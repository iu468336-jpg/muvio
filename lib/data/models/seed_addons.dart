part of 'seed_catalog.dart';

/// Verified live Nuvio Direct HTTP/HLS/MKV scrapers + Stremio addons:
/// - Pre-installed & enabled out-of-the-box (`installed: true, enabled: true`):
///   1. Cinemeta (`com.linvo.cinemeta`) — Official movie & series catalogs + IMDb metadata
///   2. OpenSubtitles v3 (`org.stremio.opensubtitlesv3`) — Official multilingual subtitles
///   3. Nuvio All-in-One Direct (`nuvio.flixdlp.allinone`) — Instant Direct HLS/MKV multi-audio (VF/ENG + 30+ subs, zero P2P wait!)
///   4. NiakVIO VF Direct (`nuvio.niakw.vf`) — French VF/VOSTFR Direct HTTP/HLS scrapers (Purstream, Sadisflix, French-Manga…)
///   5. Nuvio Global Direct (`nuvio.yoruix.providers`) — VidLink, Videasy (Chamber FR), VixSrc Direct HLS
///   6. Torrentio Lite (`com.stremio.torrentio.lite.addon`) — Fast P2P fallback powered by native NuvioEngine C++
/// - Additional 1-tap directory addons (`installed: false`):
///   Torrentio Full, Pipe, Peerflix, Pluto TV Live, Streaming Catalogs, TMDB, Anime Kitsu.
List<InstalledAddon> _defaultProposedAddons() => [
      const InstalledAddon(
        id: 'com.linvo.cinemeta',
        manifestUrl: 'https://v3-cinemeta.strem.io/manifest.json',
        installed: true,
        enabled: true,
        accentColorHex: 0xFF1F2A6B,
        shortBadge: 'CINE',
        categoryLabel: 'Catalogue & Métadonnées officiel',
        manifest: AddonManifest(
          id: 'com.linvo.cinemeta',
          version: '3.0.14',
          name: 'Cinemeta',
          description:
              'Addon officiel par défaut (Stremio / Nuvio) fournissant les catalogues populaires, nouveautés, notes IMDb et fiches complètes.',
          resources: ['catalog', 'meta', 'addon_catalog'],
          types: ['movie', 'series'],
          catalogs: [
            AddonCatalogDef(
              type: 'movie',
              id: 'top',
              name: 'Popular Movies',
              searchSupported: true,
            ),
            AddonCatalogDef(
              type: 'series',
              id: 'top',
              name: 'Popular Series',
              searchSupported: true,
            ),
            AddonCatalogDef(
              type: 'movie',
              id: 'imdbRating',
              name: 'Featured Movies',
            ),
            AddonCatalogDef(
              type: 'series',
              id: 'imdbRating',
              name: 'Featured Series',
            ),
          ],
          idPrefixes: ['tt'],
        ),
      ),
      const InstalledAddon(
        id: 'org.stremio.opensubtitlesv3',
        manifestUrl: 'https://opensubtitles-v3.strem.io/manifest.json',
        installed: true,
        enabled: true,
        accentColorHex: 0xFF28354A,
        shortBadge: 'SUB',
        categoryLabel: 'Sous-titres officiel',
        manifest: AddonManifest(
          id: 'org.stremio.opensubtitlesv3',
          version: '1.0.0',
          name: 'OpenSubtitles v3',
          description:
              'Addon officiel préinstallé fournissant automatiquement les sous-titres multilingues (FR, EN, ES, AR, JP…).',
          resources: ['subtitles'],
          types: ['movie', 'series'],
          catalogs: [],
          idPrefixes: ['tt'],
        ),
      ),
      const InstalledAddon(
        id: 'nuvio.flixdlp.allinone',
        manifestUrl:
            'https://raw.githubusercontent.com/flix-dlp/All-in-One-Nuvio/main/manifest.json',
        installed: true,
        enabled: true,
        accentColorHex: 0xFF00A86B,
        shortBadge: 'DIRECT',
        categoryLabel: 'Lecture Directe Nuvio · HLS/MKV Multi-Audio',
        manifest: AddonManifest(
          id: 'nuvio.flixdlp.allinone',
          version: '1.6.1',
          name: 'Nuvio Direct (All-in-One)',
          description:
              'Flux HTTP/HLS/MKV directs instantanés (sans torrent ni attente de pairs) avec pistes Français VF + VO et sous-titres intégrés.',
          resources: ['stream'],
          types: ['movie', 'series', 'tv'],
          catalogs: [],
          idPrefixes: ['tt', 'tmdb:'],
          kind: AddonKind.nuvio,
        ),
      ),
      const InstalledAddon(
        id: 'nuvio.niakw.vf',
        manifestUrl:
            'https://raw.githubusercontent.com/niakw/NiakVIO/main/vf/manifest.json',
        installed: true,
        enabled: true,
        accentColorHex: 0xFF1565C0,
        shortBadge: 'VF',
        categoryLabel: 'Lecture Directe Nuvio · Français VF & Anime',
        manifest: AddonManifest(
          id: 'nuvio.niakw.vf',
          version: '5.21.184',
          name: 'NiakVIO VF Direct',
          description:
              'Sources HTTP/HLS françaises directes sans P2P (Purstream, Sadisflix, Webflix, French-Manga, Mugiwara, Neko-Sama).',
          resources: ['stream'],
          types: ['movie', 'series', 'anime', 'tv'],
          catalogs: [],
          idPrefixes: ['tt', 'tmdb:'],
          kind: AddonKind.nuvio,
        ),
      ),
      const InstalledAddon(
        id: 'nuvio.yoruix.providers',
        manifestUrl:
            'https://raw.githubusercontent.com/yoruix/nuvio-providers/main/manifest.json',
        installed: true,
        enabled: true,
        accentColorHex: 0xFF00838F,
        shortBadge: 'NUVIO',
        categoryLabel: 'Lecture Directe Nuvio · VidLink / Videasy / VixSrc',
        manifest: AddonManifest(
          id: 'nuvio.yoruix.providers',
          version: '1.2.0',
          name: 'Nuvio Providers Direct',
          description:
              'Scrapers Nuvio natifs QuickJS (VidLink, Videasy Chamber FR, VixSrc, CinemaCity) pour une lecture directe immédiate.',
          resources: ['stream'],
          types: ['movie', 'series', 'tv'],
          catalogs: [],
          idPrefixes: ['tt', 'tmdb:'],
          kind: AddonKind.nuvio,
        ),
      ),
      const InstalledAddon(
        id: 'com.stremio.torrentio.lite.addon',
        manifestUrl: 'https://torrentio.strem.fun/lite/manifest.json',
        installed: true,
        enabled: true,
        accentColorHex: 0xFFD32F2F,
        shortBadge: 'LITE',
        categoryLabel: 'Sources P2P NuvioEngine · Rapide Mobile',
        manifest: AddonManifest(
          id: 'com.stremio.torrentio.lite.addon',
          version: '0.0.15',
          name: 'Torrentio Lite',
          description:
              'Version mobile rapide propulsée par le moteur C++ NuvioEngine : sélectionne les flux 1080p/720p les mieux seedés.',
          resources: ['stream'],
          types: ['movie', 'series', 'anime'],
          catalogs: [],
          idPrefixes: ['tt', 'kitsu'],
        ),
      ),
      const InstalledAddon(
        id: 'com.stremio.torrentio.addon',
        manifestUrl: 'https://torrentio.strem.fun/manifest.json',
        installed: false,
        enabled: false,
        accentColorHex: 0xFFB0060F,
        shortBadge: 'TOR',
        categoryLabel: 'Sources P2P NuvioEngine · 4K / 1080p Complet',
        manifest: AddonManifest(
          id: 'com.stremio.torrentio.addon',
          version: '0.0.15',
          name: 'Torrentio',
          description:
              'Fournit des centaines de flux 4K HDR, 1080p et multi-audio (VF/VOSTFR) pour films, séries et animes sans configuration requise.',
          resources: ['stream'],
          types: ['movie', 'series', 'anime'],
          catalogs: [],
          idPrefixes: ['tt', 'kitsu'],
        ),
      ),
      const InstalledAddon(
        id: 'org.boringways.pipe',
        manifestUrl: 'https://pipe.boringways.workers.dev/manifest.json',
        installed: false,
        enabled: false,
        accentColorHex: 0xFF00897B,
        shortBadge: 'PIPE',
        categoryLabel: 'Sources Vidéo · Films, Séries & Anime',
        manifest: AddonManifest(
          id: 'org.boringways.pipe',
          version: '2.0.0',
          name: 'Pipe',
          description:
              'Agrégateur de flux rapide et léger compatible IMDb et Kitsu pour films, séries et animes sans clé API.',
          resources: ['stream'],
          types: ['movie', 'series', 'anime'],
          catalogs: [],
          idPrefixes: ['tt', 'kitsu'],
        ),
      ),
      const InstalledAddon(
        id: 'com.keopps.peerflix',
        manifestUrl: 'https://peerflix.mov/manifest.json',
        installed: false,
        enabled: false,
        accentColorHex: 0xFF5E35B1,
        shortBadge: 'PEER',
        categoryLabel: 'Sources Vidéo · Trackers enrichis',
        manifest: AddonManifest(
          id: 'com.keopps.peerflix',
          version: '2.7.4',
          name: 'Peerflix',
          description:
              'Sources vidéo HD/4K avec liste de trackers haute vitesse pré-intégrée pour un démarrage rapide.',
          resources: ['stream'],
          types: ['movie', 'series'],
          catalogs: [],
          idPrefixes: ['tt'],
        ),
      ),
      const InstalledAddon(
        id: 'org.plutotv',
        manifestUrl:
            'https://dev.nebulawp.org/stremio/pluto-tv-addon/manifest.json',
        installed: false,
        enabled: false,
        accentColorHex: 0xFFF9A825,
        shortBadge: 'TV',
        categoryLabel: 'TV en Direct (HLS Direct) & Catalogue',
        manifest: AddonManifest(
          id: 'org.plutotv',
          version: '1.0.0',
          name: 'Pluto TV Live',
          description:
              'Plus de 1 500 chaînes TV en direct (flux HLS immédiats sans torrent) + catalogue de chaînes populaires sur l’accueil.',
          resources: ['catalog', 'meta', 'stream'],
          types: ['tv'],
          catalogs: [
            AddonCatalogDef(
              type: 'tv',
              id: 'pluto_popular',
              name: 'Pluto TV Popular Channels',
            ),
            AddonCatalogDef(
              type: 'tv',
              id: 'pluto',
              name: 'Pluto TV',
              searchSupported: true,
            ),
          ],
          idPrefixes: [],
        ),
      ),
      const InstalledAddon(
        id: 'community.streaming-catalogs',
        manifestUrl: 'https://stremio-streaming-catalogs.vercel.app/manifest.json',
        installed: false,
        enabled: false,
        accentColorHex: 0xFFE50914,
        shortBadge: 'STRM',
        categoryLabel: 'Catalogues Netflix, Prime, Disney+, Apple TV+',
        manifest: AddonManifest(
          id: 'community.streaming-catalogs',
          version: '1.12.0',
          name: 'Streaming Catalogs',
          description:
              'Ajoute directement sur votre Accueil les rangées tendances Netflix, Prime Video, Disney+, HBO Max et Apple TV+.',
          resources: ['catalog'],
          types: ['movie', 'series'],
          catalogs: [
            AddonCatalogDef(
              type: 'movie',
              id: 'nfx',
              name: 'Netflix Films',
            ),
            AddonCatalogDef(
              type: 'series',
              id: 'nfx',
              name: 'Netflix Séries',
            ),
            AddonCatalogDef(
              type: 'movie',
              id: 'prv',
              name: 'Prime Video Films',
            ),
            AddonCatalogDef(
              type: 'series',
              id: 'dnp',
              name: 'Disney+ Séries',
            ),
          ],
          idPrefixes: ['tt'],
        ),
      ),
      const InstalledAddon(
        id: 'org.tmdb.addon',
        manifestUrl:
            'https://94c8cb9f702d-tmdb-addon.baby-beamup.club/manifest.json',
        installed: false,
        enabled: false,
        accentColorHex: 0xFF01B4E4,
        shortBadge: 'TMDB',
        categoryLabel: 'Catalogue & Métadonnées TMDB',
        manifest: AddonManifest(
          id: 'org.tmdb.addon',
          version: '3.1.7',
          name: 'The Movie Database',
          description:
              'Catalogues populaires Films & Séries sur l’accueil, affiches HD et fiches complètes TMDB.',
          resources: ['catalog', 'meta'],
          types: ['movie', 'series'],
          catalogs: [
            AddonCatalogDef(
              type: 'movie',
              id: 'tmdb.top',
              name: 'TMDB Films Populaires',
              searchSupported: true,
            ),
            AddonCatalogDef(
              type: 'series',
              id: 'tmdb.top',
              name: 'TMDB Séries Populaires',
              searchSupported: true,
            ),
          ],
          idPrefixes: ['tmdb:', 'tt'],
        ),
      ),
      const InstalledAddon(
        id: 'community.anime.kitsu',
        manifestUrl: 'https://anime-kitsu.strem.fun/manifest.json',
        installed: false,
        enabled: false,
        accentColorHex: 0xFFE65100,
        shortBadge: 'KITSU',
        categoryLabel: 'Catalogue Anime (Trending, Airing, Popular)',
        manifest: AddonManifest(
          id: 'community.anime.kitsu',
          version: '0.0.10',
          name: 'Anime Kitsu',
          description:
              'Ajoute les catalogues d’animes japonais (Tendances, En cours, Populaires) sur l’accueil avec épisodes complets.',
          resources: ['catalog', 'meta'],
          types: ['anime', 'movie', 'series'],
          catalogs: [
            AddonCatalogDef(
              type: 'anime',
              id: 'kitsu-anime-trending',
              name: 'Kitsu Trending',
            ),
            AddonCatalogDef(
              type: 'anime',
              id: 'kitsu-anime-airing',
              name: 'Kitsu Top Airing',
            ),
            AddonCatalogDef(
              type: 'anime',
              id: 'kitsu-anime-popular',
              name: 'Kitsu Most Popular',
            ),
            AddonCatalogDef(
              type: 'anime',
              id: 'kitsu-anime-list',
              name: 'Kitsu Search',
              searchSupported: true,
              isSearchOnly: true,
            ),
          ],
          idPrefixes: ['kitsu'],
        ),
      ),
    ];

List<StreamSource> _fallbackStreamsFor(MediaItem item) {
  if (item.id == 'tt_eclipse_muvio') {
    return const [
      StreamSource(
        id: 'muvio_demo_hls_1080p',
        addonId: 'com.linvo.cinemeta',
        addonName: 'Muvio Direct HLS',
        title: 'Bande-annonce Open Movie · Tears of Steel (1080p Direct)',
        quality: '1080p',
        hdrMode: 'SDR',
        url: SeedCatalogData.sampleVideoHls,
        sizeBytes: 185 * 1024 * 1024,
        seeders: 500,
      ),
    ];
  }
  return const [];
}
