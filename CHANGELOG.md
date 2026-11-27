# Changelog

Toutes les modifications notables de **Muvio** sont documentées dans ce fichier.

## [1.0.4] - 2026-11-26

### Élimination définitive du crash natif (`SIGSEGV`) à la sélection d'un flux vidéo et fiabilisation de la lecture (`armeabi-v7a` & `arm64-v8a`)
- **Correction du Use-After-Free critique SWIG JNI dans `LocalTorrentStreamController.kt` (`alert.handle()` -> `SIGSEGV`)** :
  - Dans `libtorrent4j`, `TorrentAlert.handle()` retourne un pointeur SWIG non-propriétaire (`swigCMemOwn = false`) pointant directement à l'intérieur de l'objet C++ temporaire `torrent_alert`, lequel est détruit par `SessionManager.alertsLoop()` (`v.clear()`) quelques millisecondes plus tard. Conserver `activeHandle = alert.handle()` provoquait un crash natif `SIGSEGV` ~650 ms après la sélection d'un flux torrent, avant même le démarrage de la vidéo.
  - Désormais, seul le hash hexadécimal (`infoHash().toHex()`) est extrait pendant l'alerte, et chaque opération résout systématiquement un `TorrentHandle` propriétaire alloué sur le tas (`swigCMemOwn = true`) via `sessionManager.find(Sha1Hash.parseHex(hex))`, exactement comme dans LibreTorrent 4.1.1.
- **Mise à niveau vers `libtorrent4j 2.1.0-38` (compatible API 24+ `armeabi-v7a`) & correctif réseau Android 11–15 (`enable_ip_notifier = false`)** :
  - Mise à jour de `libtorrent4j` de `2.1.0-31` vers **`2.1.0-38`** (même moteur que LibreTorrent 4.1.1, sans symbole `LIBC_P` bloquant sur Android 7–8.1).
  - Désactivation de `enable_ip_notifier` (bloqué par SELinux `NETLINK_ROUTE` sur Android 11–15, ce qui laissait parfois la session bloquée à 0 pair) et configuration explicite de `listenInterfaces` IPv4/IPv6 avec réessai automatique de port et nœuds bootstrap DHT.
- **Isolation complète du moteur torrent dans un sous-processus Android dédié (`android:process=":torrent"`)** :
  - `TorrentForegroundService` exécute désormais `libtorrent4j` + `NanoHTTPD` dans un processus système séparé (`:torrent`) relié par `Messenger` IPC (`bindService`), protégeant à 100 % le processus principal Flutter / ExoPlayer contre toute corruption mémoire, conflit de gestionnaire de signaux POSIX ou saturation d'espace d'adressage 32-bit.
- **Correction du crash `ImageReaderSurfaceProducer` / `Gralloc` sous Skia (`createSurfaceTexture()`)** :
  - Avec `EnableImpeller = false` (Skia OpenGL ES), l'appel `createSurfaceProducer()` allouait sur Android 10+ un `ImageReaderSurfaceProducer` (`AHardwareBuffer`) provoquant des crashs `Gralloc validateBufferSize` / `OMX` sur puces MediaTek, Mali et HiSilicon 32-bit. `NativeMedia3PlayerController` utilise désormais directement `createSurfaceTexture()` (`GLConsumer` OpenGL ES natif) avec verrouillage `debugForceSurfaceProducerGlTextures = true`.
- **Journal de diagnostic intégré dans Profil > Paramètres** :
  - Enregistrement persistant des erreurs non interceptées (Android JVM, processus `:torrent`, ExoPlayer et Flutter/Dart) consultable et copiable en un clic depuis `Profil > Journal de diagnostic`.

## [1.0.3] - 2026-11-26

### Correction critique du freeze / crash à la sélection d'une source vidéo (32-bit `armeabi-v7a` & tous téléphones Android)
- **Nouveau moteur vidéo natif AndroidX Media3 (`ExoPlayer 1.6.1` + décodeur audio FFmpeg Jellyfin)** :
  - Remplacement complet de `media_kit` (`libmpv` FFI) par un moteur natif **AndroidX Media3 (`ExoPlayer`)** couplé au décodeur **FFmpeg (`libffmpegJNI.so`)**, éliminant définitivement les crashs natifs `SIGSEGV`/`SIGABRT` liés aux callbacks FFI Dart (`NativeCallable` / `SurfaceProducer` 1×1) et les blocages du thread UI sur les smartphones 32-bit `armeabi-v7a`.
  - Prise en charge matérielle fluide (`MediaCodec`) des conteneurs **MKV, MP4, WebM, HLS (`.m3u8`), DASH (`.mpd`)** et décodage logiciel transparent de toutes les pistes audio **AC3, EAC3 (Dolby Digital Plus), DTS, AAC, Opus, Vorbis et FLAC**, avec changement de piste audio et activation/désactivation des sous-titres en direct.
- **Correction du crash mémoire `mmap` 32-bit dans `libtorrent4j` (`setPosixDiskIO()`)** :
  - Activation explicite de `SessionParams.setPosixDiskIO()` afin d'interdire le `mmap` de fichiers vidéo multi-gigaoctets dans l'espace d'adressage virtuel 32-bit (`armeabi-v7a`), responsable d'erreurs `OutOfMemory` / `SIGABRT` dès la réception des métadonnées d'un film ou d'un épisode.
  - Plafonnement strict des tampons mémoire et connexions pairs (`connectionsLimit`, `maxPeerlistSize`, `maxQueuedDiskBytes = 4 Mo`, `aio_threads = 2`) adapté aux téléphones Android 32-bit.
- **Zéro gel de l'interface (ANR éliminé)** :
  - Déport complet des appels JNI `libtorrent` (`status()`, `havePiece()`) et de l'arrêt de session (`stopAsync()`) sur des threads d'arrière-plan dédiés : `getTorrentStatus` lit désormais un instantané `@Volatile` sans verrou ni appel JNI sur le thread principal Android.
  - Démarrage immédiat de la préparation du flux sélectionné dès l'ouverture du lecteur, sans attendre une seconde requête réseau de catalogue/flux.
- **Rendu graphique OpenGL Skia stabilisé (`EnableImpeller = false` + `largeHeap = true`)** :
  - Désactivation d'Impeller sur Android pour éliminer les crashs pilotes Vulkan/GLES sur GPU Mali/Adreno 32-bit lors de l'affichage de la texture vidéo et des contrôles vitrés (`BackdropFilter`).

## [1.0.2] - 2026-11-26

### Corrections critiques (Flux, Catalogues Accueil & Lecture Vidéo)
- **Catalogues dynamiques sur l'Accueil (comme Stremio & Nuvio)** : L'installation ou l'activation de n'importe quel addon catalogue (**The Movie Database**, **Streaming Catalogs** Netflix/Prime/Disney+, **Anime Kitsu**, **Pluto TV Live**, ou URL personnalisée) affiche désormais automatiquement ses propres rangées horizontales sur l'écran d'Accueil, gère les paramètres `extra` requis et récupère les métadonnées complètes (`meta`) depuis l'addon propriétaire.
- **Résolution des flux vidéo 100 % fonctionnelle** :
  - Support complet des manifests Stremio déclarant `resources` sous forme d'objets (`{name, types, idPrefixes}`) ou de chaînes, encodage propre des identifiants composés (`tt...:saison:episode`, `kitsu:...:episode`, `tmdb:...`) et pont automatique `imdb_id` permettant de lire les fiches TMDB et Anime Kitsu via **Torrentio**, **Torrentio Lite**, **Pipe** et **Peerflix**.
  - Remplacement des entrées non configurées qui renvoyaient `403` ou `0` flux par des sources vérifiées fonctionnelles sans clé API (**Torrentio**, **Torrentio Lite**, **Pipe**, **Peerflix**, **Pluto TV Live**).
- **Moteur de lecture vidéo & torrent entièrement réécrit (`libtorrent4j` + `media_kit`)** :
  - Injection automatique de trackers UDP/HTTP haute vitesse + trackers `sources` Stremio + bootstrap DHT/LSD.
  - Sélection exacte du fichier vidéo cible (`fileIdx`) avec mise en `Priority.IGNORE` des autres fichiers des packs de saisons.
  - Priorisation `TOP_PRIORITY` + `setPieceDeadline` sur les pièces d'en-tête ET de fin de fichier (`moov` MP4 / `Cues` MKV).
  - Lecture HTTP Range (`206 Partial Content`) vérifiant `havePiece(pieceIndex)` pièce par pièce via `RandomAccessFile` (élimine définitivement l'erreur HTTP `503` et la lecture d'octets vides qui bloquaient le démarrage de `mpv`), accompagnée d'un indicateur de mise en mémoire tampon en temps réel (pairs connectés, Mo tamponnés, vitesse Ko/s) et de l'autorisation des flux directs HTTP/HLS (`.m3u8`, `.mp4`, `.mkv`).

## [1.0.1] - 2026-11-26

### Corrigé & Amélioré
- Pré-installation des addons officiels **Cinemeta** et **OpenSubtitles v3**, suppression des données fictives et recalibrage de l'interface mobile.

## [1.0.0] - 2026-11-25

### Ajouté
- Version initiale open-source de Muvio.
