import 'package:muvio/core/errors/result.dart';
import 'package:muvio/data/models/addon_models.dart';
import 'package:muvio/data/models/media_models.dart';
import 'package:muvio/data/models/seed_catalog.dart';
import 'package:muvio/data/providers/stremio_addon_client.dart';
import 'package:muvio/data/repositories/addon_repository.dart';

/// Aggregates catalogs, metadata, multi-addon parallel search (`Future.wait`),
/// and deduplicated stream sources across all active addons.
class CatalogRepository {
  CatalogRepository({
    required MediaProvider client,
    required AddonRepository addonRepository,
  })  : _client = client,
        _addonRepository = addonRepository;

  final MediaProvider _client;
  final AddonRepository _addonRepository;

  Future<List<MediaItem>> fetchMergedCatalog({
    required List<InstalledAddon> activeAddons,
    String type = 'movie',
  }) async {
    final catalogAddons = activeAddons
        .where(
          (a) =>
              a.installed &&
              a.enabled &&
              !a.isOffline &&
              a.manifest.supportsResource('catalog') &&
              a.manifest.catalogs.any((c) => c.type == type),
        )
        .toList();

    if (catalogAddons.isEmpty) {
      return SeedCatalogData.catalogItems
          .where((m) => type == 'all' || m.type == type)
          .toList();
    }

    final futures = catalogAddons.map((addon) async {
      final cat = addon.manifest.catalogs.firstWhere((c) => c.type == type);
      final res = await _client.fetchCatalog(
        addon: addon,
        type: type,
        catalogId: cat.id,
      );
      return res.fold(
        onSuccess: (items) {
          _addonRepository.resetFailures(addon);
          return items;
        },
        onFailure: (_) {
          _addonRepository.recordFailure(addon);
          return <MediaItem>[];
        },
      );
    });

    final results = await Future.wait(futures);
    final merged = _deduplicateMedia([
      ...SeedCatalogData.catalogItems,
      for (final list in results) ...list,
    ]);
    return merged;
  }

  /// Parallel search across all enabled addons with deduplication by `meta.id`.
  Future<List<MediaItem>> searchAcrossAddons({
    required String query,
    required List<InstalledAddon> activeAddons,
    String? genreFilter,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();

    final localMatches = [
      ...SeedCatalogData.heroItems,
      ...SeedCatalogData.catalogItems,
    ].where((item) {
      final matchesText = normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.synopsis.toLowerCase().contains(normalizedQuery);
      final matchesGenre = genreFilter == null ||
          genreFilter == 'Tout' ||
          genreFilter == 'All' ||
          item.genres.any((g) => g.toLowerCase() == genreFilter.toLowerCase());
      return matchesText && matchesGenre;
    }).toList();

    if (normalizedQuery.isEmpty) {
      return _deduplicateMedia(localMatches);
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
              .then((res) => res.valueOrNull ?? const <MediaItem>[]),
        );
      }
    }

    final remoteLists = remoteFutures.isEmpty
        ? const <List<MediaItem>>[]
        : await Future.wait(remoteFutures);

    return _deduplicateMedia([
      ...localMatches,
      for (final list in remoteLists) ...list,
    ]);
  }

  Future<MediaItem> resolveMediaDetail({
    required String mediaId,
    required String type,
    required List<InstalledAddon> activeAddons,
  }) async {
    final allLocal = [
      ...SeedCatalogData.heroItems,
      ...SeedCatalogData.catalogItems,
    ];
    for (final item in allLocal) {
      if (item.id == mediaId) return item;
    }

    for (final addon in activeAddons) {
      if (!addon.installed || !addon.enabled || addon.isOffline) continue;
      if (!addon.manifest.supportsResource('meta')) continue;
      final res = await _client.fetchMeta(
        addon: addon,
        type: type,
        mediaId: mediaId,
      );
      if (res is Success<MediaItem>) {
        return res.value;
      }
    }

    return SeedCatalogData.heroItems.first;
  }

  Future<List<StreamSource>> fetchStreamsForMedia({
    required MediaItem media,
    required List<InstalledAddon> activeAddons,
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

    final remoteFutures = streamAddons.map((addon) async {
      final res = await _client.fetchStreams(
        addon: addon,
        type: media.type,
        mediaId: media.id,
      );
      return res.valueOrNull ?? const <StreamSource>[];
    });

    final remoteLists = remoteFutures.isEmpty
        ? const <List<StreamSource>>[]
        : await Future.wait(remoteFutures);

    final combined = <StreamSource>[
      for (final list in remoteLists) ...list,
      ...SeedCatalogData.fallbackStreamsFor(media),
    ];

    return StreamDeduplicator.deduplicateAndRank(combined);
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
