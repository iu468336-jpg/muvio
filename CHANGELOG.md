# Changelog

Toutes les modifications notables de **Muvio** sont documentées dans ce fichier.

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
