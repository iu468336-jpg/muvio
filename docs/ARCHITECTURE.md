# Architecture Technique — Muvio

## Vue d'ensemble

**Muvio** (`app.muvio.mobile`) suit une architecture **Clean Layered + Feature-First** pilotée par **Riverpod 2** (`riverpod_annotation`), **Drift (SQLite typé)** et **GoRouter**.

```text
lib/
├── main.dart                     # Bootstrap, MediaKit init, LRU image cache 100 Mo
├── app.dart                      # MaterialApp.router, thème dynamique, i18n FR/EN
├── core/
│   ├── errors/result.dart        # Monade Result<T> (Success / Failure) + AppFailure scellées
│   ├── network/dio_client.dart   # Dio + timeout 10s + limite 5 Mo + retry + cache 5 min
│   ├── router/app_router.dart    # GoRouter StatefulShellRoute.indexedStack (5 onglets)
│   ├── storage/                  # AppDatabase (Drift SQLite) + SecureStorageService
│   ├── theme/                    # AppColors, AppTypography (Inter local), AppSpacing
│   └── utils/                    # UrlSecurityValidator (anti-SSRF), Formatters, AppLogger
├── data/
│   ├── models/                   # AddonManifest, InstalledAddon, MediaItem, StreamSource
│   ├── providers/                # StremioAddonClient, TorrentEngineBridge, Riverpod providers
│   └── repositories/             # AddonRepository, CatalogRepository, LibraryRepository
├── features/
│   ├── home/                     # Écran 1 : Hero 16:9, Continuer à regarder, Tendances
│   ├── addons/                   # Écran 2 : Stremio Addons & Nuvio Plugins, install par URL
│   ├── detail/                   # Écran Détail : Synopsis, casting, épisodes, sources
│   ├── player/                   # Écrans 3 & 7 : Portrait + Paysage 16:9, gestes, PiP
│   ├── search/                   # Écran 4 : Recherche parallèle multi-addons + Top 10
│   ├── library/                  # Écran 5 : Ma liste, Téléchargements, Historique, Stockage
│   └── profile/                  # Écran 6 : Paramètres complets, Keystore, Open Source
└── shared/widgets/               # MuvioBottomShell, PosterCard, MuvioImage, SkeletonBox
```

## Protocole Stremio & Nuvio (`MediaProvider`)

`StremioAddonClient` implémente l'interface `MediaProvider` :
- `GET {base}/manifest.json`
- `GET {base}/catalog/{type}/{id}[/search=... | /skip=...].json`
- `GET {base}/meta/{type}/{id}.json`
- `GET {base}/stream/{type}/{id}.json`
- `GET {base}/subtitles/{type}/{id}[/videoHash=...&filename=...].json`

### Résilience & Circuit Breaker
Chaque addon dispose d'un compteur d'échecs persisté (`failureCount`). Après **3 échecs consécutifs**, l'addon passe automatiquement à l'état `isOffline` (circuit breaker) afin de ne jamais ralentir ni bloquer l'application.

## Pipeline Vidéo & Moteur Torrent Natif

1. **Flux HTTP / HLS / DASH directs** : transmis directement à `media_kit` (`libmpv`) avec accélération matérielle (`hwdec`) et repli logiciel automatique.
2. **Flux BitTorrent (`magnet:?` / `infoHash`)** :
   - Le `MethodChannel` `app.muvio.mobile/torrent_engine` invoque `LocalTorrentStreamController.kt` côté Android natif.
   - `libtorrent4j` démarre la session avec `TorrentFlags.SEQUENTIAL_DOWNLOAD` pour télécharger les premières pièces en priorité.
   - Un serveur HTTP local `NanoHTTPD` lié uniquement à `127.0.0.1:<port>` supportant les requêtes `Range: bytes=...` expose immédiatement le flux à `media_kit`.

## Garanties de Performance

- **Impeller** activé dans `AndroidManifest.xml`.
- **Polices Inter** embarquées localement dans `assets/fonts/` (`allowRuntimeFetching = false`).
- **Mémoire d'images maîtrisée** : `MuvioImage` impose `memCacheWidth` adapté à la taille réelle d'affichage et plafonne `PaintingBinding.instance.imageCache` à 100 Mo.
- **Rendu liste** : `CustomScrollView`, `SliverList`, `SliverGrid`, `ListView.separated` et `RepaintBoundary` autour de chaque carte.
