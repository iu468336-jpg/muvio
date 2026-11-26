import 'package:muvio/core/errors/result.dart';
import 'package:muvio/data/models/addon_models.dart';
import 'package:muvio/data/models/media_models.dart';
import 'package:muvio/data/models/seed_catalog.dart';
import 'package:muvio/data/providers/stremio_addon_client.dart';
import 'package:muvio/data/repositories/addon_repository.dart';

/// Aggregates Stremio/Nuvio-style per-addon Home catalog rows, metadata routing,
/// multi-addon parallel search (`Future.wait`), and cross-ID (`tt`, `tmdb:`, `kitsu:`)
/// deduplicated stream sources across all active addons.
class CatalogRepository {
  CatalogRepository({
    required MediaProvider client,
    required AddonRepository addonRepository,
  })  : _client = client,
        _addonRepository = addonRepository;

  final MediaProvider _client;
  final AddonRepository _addonRepository;

  final Map<String, MediaItem> _itemMemoryCache = <String, MediaItem>{};

  void _cacheItems(Iterable<MediaItem> items) {
    for (final item in items) {
      if (item.id.isNotEmpty) {
        _itemMemoryCache[item.id] = item;
      }
    }
  }

  /// Fetches dynamic Home catalog rows across ALL installed & enabled catalog addons,
  /// preserving exact addon installation order just like Stremio and Nuvio!
  Future<List<HomeCatalogSection>> fetchHomeSections({
    required List<InstalledAddon> activeAddons,
  }) async {
    final catalogAddons = activeAddons
        .where(
          (a) =>
              a.installed &&
              a.enabled &&
              !a.isOffline &&
              (a.manifest.supportsResource('catalog') ||
                  a.manifest.catalogs.isNotEmpty),
        )
        .toList();

    if (catalogAddons.isEmpty) {
      return _fallbackHomeSections();
    }

    final tasks = <Future<HomeCatalogSection?>>[];
    for (final addon in catalogAddons) {
      final homeCats =
          addon.manifest.catalogs.where((c) => c.showOnHome).take(6).toList();
      for (final cat in homeCats) {
        tasks.add(
          _client
              .fetchCatalog(
            addon: addon,
            type: cat.type,
            catalogId: cat.id,
            defaultExtra: cat.defaultRequiredExtra,
          )
              .then((res) {
            return res.fold(
              onSuccess: (items) {
                if (items.isEmpty) return null;
                _addonRepository.resetFailures(addon);
                _cacheItems(items);
                return HomeCatalogSection(
                  addonId: addon.id,
                  addonName: addon.manifest.name,
                  catalogId: cat.id,
                  catalogType: cat.type,
                  catalogName: cat.name,
                  items: items,
                );
              },
              onFailure: (_) => null,
            );
          }),
        );
      }
    }

    final resolved = await Future.wait(tasks);
    final nonNull = resolved.whereType<HomeCatalogSection>().toList();
    if (nonNull.isEmpty) {
      return _fallbackHomeSections();
    }
    return nonNull;
  }

  List<HomeCatalogSection> _fallbackHomeSections() {
    final movies =
        SeedCatalogData.catalogItems.where((e) => e.type == 'movie').toList();
    final series =
        SeedCatalogData.catalogItems.where((e) => e.type == 'series').toList();
    _cacheItems(SeedCatalogData.catalogItems);
    return [
      HomeCatalogSection(
        addonId: 'com.linvo.cinemeta',
        addonName: 'Cinemeta',
        catalogId: 'top',
        catalogType: 'movie',
        catalogName: 'Popular Movies',
        items: movies,
      ),
      HomeCatalogSection(
        addonId: 'com.linvo.cinemeta',
        addonName: 'Cinemeta',
        catalogId: 'top',
        catalogType: 'series',
        catalogName: 'Popular Series',
        items: series,
      ),
    ];
  }

  Future<List<MediaItem>> fetchMergedCatalog({
    required List<InstalledAddon> activeAddons,
    String type = 'all',
  }) async {
    final sections = await fetchHomeSections(activeAddons: activeAddons);
    final merged = <MediaItem>[
      for (final s in sections)
        if (type == 'all' || s.catalogType == type) ...s.items,
    ];
    if (merged.isEmpty) {
      return SeedCatalogData.catalogItems
          .where((m) => type == 'all' || m.type == type)
          .toList();
    }
    return _deduplicateMedia([
      ...merged,
      ...SeedCatalogData.catalogItems
          .where((m) => type == 'all' || m.type == type),
    ]);
  }

  /// Parallel search across all enabled addons with deduplication by `meta.id`.
  Future<List<MediaItem>> searchAcrossAddons({
    required String query,
    required List<InstalledAddon> activeAddons,
    String? genreFilter,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      final base = await fetchMergedCatalog(activeAddons: activeAddons);
      if (genreFilter == null ||
          genreFilter == 'Tout' ||
          genreFilter == 'All') {
        return base;
      }
      return base
          .where(
            (item) => item.genres
                .any((g) => g.toLowerCase() == genreFilter.toLowerCase()),
          )
          .toList();
    }

    final searchableAddons = activeAddons
        .where(
          (a) =>
              a.installed &&
              a.enabled &&
              !a.isOffline &&
              a.manifest.catalogs.any((c) => c.searchSupported),
        )
        .toList();

    final remoteFutures = <Future<List<MediaItem>>>[];
    for (final addon in searchableAddons) {
      for (final cat
          in addon.manifest.catalogs.where((c) => c.searchSupported)) {
        remoteFutures.add(
          _client
              .fetchCatalog(
                addon: addon,
                type: cat.type,
                catalogId: cat.id,
                searchQuery: query,
              )
              .then((res) {
            final items = res.valueOrNull ?? const <MediaItem>[];
            _cacheItems(items);
            return items;
          }),
        );
      }
    }

    final remoteLists = remoteFutures.isEmpty
        ? const <List<MediaItem>>[]
        : await Future.wait(remoteFutures);

    final localMatches = [
      ...SeedCatalogData.heroItems,
      ...SeedCatalogData.catalogItems,
    ].where((item) {
      return item.title.toLowerCase().contains(normalizedQuery) ||
          item.synopsis.toLowerCase().contains(normalizedQuery);
    });

    final merged = _deduplicateMedia([
      for (final list in remoteLists) ...list,
      ...localMatches,
    ]);

    if (genreFilter == null || genreFilter == 'Tout' || genreFilter == 'All') {
      return merged;
    }
    return merged
        .where(
          (item) => item.genres
              .any((g) => g.toLowerCase() == genreFilter.toLowerCase()),
        )
        .toList();
  }

  /// Resolves full metadata by prioritizing addons whose `idPrefixes` & `types`
  /// match `mediaId` (e.g., `tmdb:1726` -> TMDB Addon, `kitsu:7442` -> Anime Kitsu,
  /// `ryan-and-friends` -> Pluto TV, `tt...` -> Cinemeta), with safe cache fallback!
  Future<MediaItem> resolveMediaDetail({
    required String mediaId,
    required String type,
    required List<InstalledAddon> activeAddons,
  }) async {
    final metaAddons = activeAddons
        .where(
          (a) =>
              a.installed &&
              a.enabled &&
              !a.isOffline &&
              a.manifest.supportsResource('meta'),
        )
        .toList()
      ..sort((a, b) {
        final aScore = _metaAffinityScore(a.manifest, mediaId, type);
        final bScore = _metaAffinityScore(b.manifest, mediaId, type);
        return bScore.compareTo(aScore);
      });

    final candidateTypes = <String>{
      type,
      if (mediaId.startsWith('kitsu:')) ...['anime', 'series', 'movie'],
    }.toList();

    for (final addon in metaAddons) {
      if (!addon.manifest.matchesIdPrefix(mediaId) &&
          addon.manifest.idPrefixes.isNotEmpty) {
        continue;
      }
      for (final candidateType in candidateTypes) {
        final res = await _client.fetchMeta(
          addon: addon,
          type: candidateType,
          mediaId: mediaId,
        );
        if (res is Success<MediaItem>) {
          _itemMemoryCache[mediaId] = res.value;
          return res.value;
        }
      }
    }

    final cached = _itemMemoryCache[mediaId];
    if (cached != null) return cached;

    final allLocal = [
      ...SeedCatalogData.heroItems,
      ...SeedCatalogData.catalogItems,
    ];
    for (final item in allLocal) {
      if (item.id == mediaId) return item;
    }

    return MediaItem(
      id: mediaId,
      type: type,
      title: mediaId,
      poster: SeedCatalogData.heroItems.first.poster,
      backdrop: SeedCatalogData.heroItems.first.backdrop,
    );
  }

  int _metaAffinityScore(AddonManifest manifest, String mediaId, String type) {
    var score = 0;
    if (manifest.idPrefixes.isNotEmpty &&
        manifest.idPrefixes.any(mediaId.startsWith)) {
      score += 20;
    }
    if (manifest.types.contains(type)) {
      score += 10;
    }
    return score;
  }

  /// Queries all enabled stream addons in parallel, automatically translating
  /// `tmdb:...` and `kitsu:...` IDs into their `imdbId` (`tt...`) when needed
  /// so Torrentio, Pipe, Peerflix, and Pluto TV all return streams reliably!
  Future<List<StreamSource>> fetchStreamsForMedia({
    required MediaItem media,
    required List<InstalledAddon> activeAddons,
    String? episodeVideoId,
  }) async {
    final streamAddons = activeAddons
        .where(
          (a) =>
              a.installed &&
              a.enabled &&
              !a.isOffline &&
              a.manifest.supportsResource('stream'),
        )
        .toList();

    final queryPairs = _buildStreamQueries(media, episodeVideoId);
    final remoteFutures = <Future<List<StreamSource>>>[];

    for (final addon in streamAddons) {
      for (final pair in queryPairs) {
        final qType = pair.$1;
        final qId = pair.$2;
        if (addon.manifest.idPrefixes.isNotEmpty &&
            !addon.manifest.matchesIdPrefix(qId)) {
          continue;
        }
        if (addon.manifest.types.isNotEmpty &&
            !addon.manifest.types.contains(qType)) {
          continue;
        }
        remoteFutures.add(
          _client
              .fetchStreams(
                addon: addon,
                type: qType,
                mediaId: qId,
              )
              .then((res) => res.valueOrNull ?? const <StreamSource>[]),
        );
      }
    }

    final remoteLists = remoteFutures.isEmpty
        ? const <List<StreamSource>>[]
        : await Future.wait(remoteFutures);

    final combined = <StreamSource>[
      for (final list in remoteLists) ...list,
      ...SeedCatalogData.fallbackStreamsFor(media),
    ];

    return StreamDeduplicator.deduplicateAndRank(combined);
  }

  List<(String, String)> _buildStreamQueries(
    MediaItem media,
    String? episodeVideoId,
  ) {
    final queries = <(String, String)>{};
    final targetId =
        (episodeVideoId != null && episodeVideoId.trim().isNotEmpty)
            ? episodeVideoId.trim()
            : (media.episodes.isNotEmpty &&
                    (media.type == 'series' || media.type == 'anime')
                ? (media.episodes.first.id.isNotEmpty
                    ? media.episodes.first.id
                    : '${media.id}:${media.episodes.first.season}:${media.episodes.first.episode}')
                : media.id);

    queries.add((media.type, targetId));
    if (media.type == 'anime') {
      queries.add(('series', targetId));
    } else if (media.type == 'series' && targetId.startsWith('kitsu:')) {
      queries.add(('anime', targetId));
    }

    // Cross-ID bridge: if item came from TMDB (`tmdb:1726`) or Kitsu (`kitsu:7442:1`)
    // and carries an `imdbId` (`tt...`), also query IMDb-based addons (`tt...:S:E`)!
    final imdb = media.imdbId;
    if (imdb != null && imdb.startsWith('tt') && !targetId.startsWith('tt')) {
      if (media.type == 'movie') {
        queries.add(('movie', imdb));
      } else {
        EpisodeVideo? matchedEp;
        for (final ep in media.episodes) {
          if (ep.id == targetId) {
            matchedEp = ep;
            break;
          }
        }
        final s = matchedEp?.imdbSeason ?? matchedEp?.season ?? 1;
        final e = matchedEp?.imdbEpisode ?? matchedEp?.episode ?? 1;
        final epImdb = matchedEp?.imdbId ?? imdb;
        queries.add(('series', '$epImdb:$s:$e'));
      }
    }

    return queries.toList();
  }

  List<MediaItem> _deduplicateMedia(List<MediaItem> items) {
    final seen = <String, MediaItem>{};
    for (final item in items) {
      if (item.id.isEmpty) continue;
      seen.putIfAbsent(item.id, () => item);
    }
    return seen.values.toList();
  }
}
