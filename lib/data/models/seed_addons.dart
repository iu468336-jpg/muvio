part of 'seed_catalog.dart';

/// Real, verified Stremio & Nuvio addons matching Nuvio's official default setup:
/// - Pre-installed by default (`installed: true, enabled: true`):
///   1. Cinemeta (`com.linvo.cinemeta`) — Official movie & series catalogs + IMDb metadata
///   2. OpenSubtitles v3 (`org.stremio.opensubtitlesv3`) — Official multilingual subtitles
/// - Real community addons & Nuvio plugin repositories available in 1 tap (`installed: false`):
///   Torrentio, Comet, MediaFusion, The Movie Database Addon, Anime Kitsu,
///   All-in-One Nuvio Repo, Yoru's Nuvio Repo.
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
            AddonCatalogDef(
              type: 'movie',
              id: 'year',
              name: 'New Movies',
            ),
            AddonCatalogDef(
              type: 'series',
              id: 'year',
              name: 'New Series',
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
        id: 'com.stremio.torrentio.addon',
        manifestUrl: 'https://torrentio.strem.fun/manifest.json',
        installed: false,
        enabled: false,
        accentColorHex: 0xFFB0060F,
        shortBadge: 'TOR',
        categoryLabel: 'Sources 4K / 1080p',
        manifest: AddonManifest(
          id: 'com.stremio.torrentio.addon',
          version: '0.0.15',
          name: 'Torrentio',
          description:
              'Fournit des flux 4K HDR / 1080p multi-langues depuis les principaux indexeurs publics et services Debrid.',
          resources: ['stream'],
          types: ['movie', 'series', 'anime'],
          catalogs: [],
          idPrefixes: ['tt', 'kitsu'],
        ),
      ),
      const InstalledAddon(
        id: 'comet.elfhosted.com',
        manifestUrl: 'https://comet.elfhosted.com/manifest.json',
        installed: false,
        enabled: false,
        accentColorHex: 0xFF53339E,
        shortBadge: 'CMT',
        categoryLabel: 'Sources rapides & Debrid',
        manifest: AddonManifest(
          id: 'comet.elfhosted.com',
          version: '2.0.0',
          name: 'Comet | ElfHosted',
          description:
              'Moteur ultra-rapide de recherche de flux torrents et caches Debrid pour films, séries et animes.',
          resources: ['stream'],
          types: ['movie', 'series', 'anime'],
          catalogs: [],
          idPrefixes: ['tt', 'kitsu'],
        ),
      ),
      const InstalledAddon(
        id: 'stremio.addons.mediafusion|elfhosted',
        manifestUrl: 'https://mediafusion.elfhosted.com/manifest.json',
        installed: false,
        enabled: false,
        accentColorHex: 0xFF2352C7,
        shortBadge: 'MF',
        categoryLabel: 'Sources & Événements Live',
        manifest: AddonManifest(
          id: 'stremio.addons.mediafusion|elfhosted',
          version: '6.2.0',
          name: 'MediaFusion | ElfHosted',
          description:
              'Agrégateur universel de catalogues, flux HD/4K et événements sportifs en direct.',
          resources: ['catalog', 'meta', 'stream'],
          types: ['movie', 'series', 'tv', 'events'],
          catalogs: [],
          idPrefixes: ['tt', 'mf'],
        ),
      ),
      const InstalledAddon(
        id: 'tmdb-addon',
        manifestUrl:
            'https://94c8cb9f702d-tmdb-addon.baby-beamup.club/manifest.json',
        installed: false,
        enabled: false,
        accentColorHex: 0xFF01B4E4,
        shortBadge: 'TMDB',
        categoryLabel: 'Catalogue & Métadonnées TMDB',
        manifest: AddonManifest(
          id: 'tmdb-addon',
          version: '3.1.7',
          name: 'The Movie Database Addon',
          description:
              'Catalogues enrichis, affiches HD et synopsis traduits propulsés par The Movie Database (TMDB).',
          resources: ['catalog', 'meta'],
          types: ['movie', 'series'],
          catalogs: [
            AddonCatalogDef(
              type: 'movie',
              id: 'tmdb.top',
              name: 'TMDB Popular',
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
        categoryLabel: 'Catalogue Anime',
        manifest: AddonManifest(
          id: 'community.anime.kitsu',
          version: '0.0.10',
          name: 'Anime Kitsu',
          description:
              'Catalogue complet d’animes japonais avec saisons, OAV, notes et recherche dédiée.',
          resources: ['catalog', 'meta', 'subtitles'],
          types: ['anime', 'movie', 'series'],
          catalogs: [
            AddonCatalogDef(
              type: 'anime',
              id: 'kitsu-anime-trending',
              name: 'Trending Anime',
              searchSupported: true,
            ),
          ],
          idPrefixes: ['kitsu'],
        ),
      ),
      const InstalledAddon(
        id: 'com.linvo.stremiochannels',
        manifestUrl: 'https://v3-channels.strem.io/manifest.json',
        installed: false,
        enabled: false,
        accentColorHex: 0xFFCC0000,
        shortBadge: 'YT',
        categoryLabel: 'Chaînes officielles',
        manifest: AddonManifest(
          id: 'com.linvo.stremiochannels',
          version: '1.30.7',
          name: 'YouTube Channels',
          description:
              'Chaînes vidéo officielles Stremio sans publicité et bandes-annonces.',
          resources: ['catalog', 'meta'],
          types: ['channel'],
          catalogs: [],
          idPrefixes: ['yt_id:'],
        ),
      ),
      const InstalledAddon(
        id: 'nuvio.raw_githubusercontent_com.all.in.one.nuvio',
        manifestUrl:
            'https://raw.githubusercontent.com/NuvioPlugin/All-in-One-Nuvio/refs/heads/main/manifest.json',
        installed: false,
        enabled: false,
        accentColorHex: 0xFFD99B00,
        shortBadge: 'AIO',
        categoryLabel: 'Dépôt Nuvio officiel',
        manifest: AddonManifest(
          id: 'nuvio.raw_githubusercontent_com.all.in.one.nuvio',
          version: '1.0.0',
          name: 'All-in-One-Nuvio',
          description:
              'Dépôt communautaire Nuvio regroupant plus de 60 scrapers directs (VidLink, VidSrc, UHDMovies, AnimeSama, ShowBox…).',
          resources: ['stream'],
          types: ['movie', 'series'],
          catalogs: [],
          kind: AddonKind.nuvio,
        ),
      ),
      const InstalledAddon(
        id: 'nuvio.raw_githubusercontent_com.yoru.s.repo',
        manifestUrl:
            'https://raw.githubusercontent.com/yoruix/nuvio-providers/refs/heads/main/manifest.json',
        installed: false,
        enabled: false,
        accentColorHex: 0xFF7B3FE4,
        shortBadge: 'YORU',
        categoryLabel: 'Dépôt Nuvio Providers',
        manifest: AddonManifest(
          id: 'nuvio.raw_githubusercontent_com.yoru.s.repo',
          version: '1.0.0',
          name: "Yoru's Repo",
          description:
              'Collection maintenue de 29 providers Nuvio HD/4K (4KHDHub, MovieBox, Vidlink, Cinevibe, Netmirror…).',
          resources: ['stream'],
          types: ['movie', 'series'],
          catalogs: [],
          kind: AddonKind.nuvio,
        ),
      ),
    ];

List<StreamSource> _fallbackStreamsFor(MediaItem item) => const [];
