import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muvio/core/errors/result.dart';
import 'package:muvio/core/network/dio_client.dart';
import 'package:muvio/core/storage/app_database.dart';
import 'package:muvio/data/models/addon_models.dart';
import 'package:muvio/data/models/app_settings.dart';
import 'package:muvio/data/models/media_models.dart';
import 'package:muvio/data/providers/native_video_player_bridge.dart';
import 'package:muvio/data/providers/stremio_addon_client.dart';
import 'package:muvio/data/providers/torrent_engine_bridge.dart';
import 'package:muvio/data/repositories/addon_repository.dart';
import 'package:muvio/data/repositories/catalog_repository.dart';
import 'package:muvio/data/repositories/library_repository.dart';
import 'package:muvio/data/repositories/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
MediaProvider stremioClient(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return StremioAddonClient(dio);
}

@Riverpod(keepAlive: true)
TorrentEngineBridge torrentEngineBridge(Ref ref) {
  return const TorrentEngineBridge();
}

final nativeVideoPlayerBridgeProvider =
    Provider<NativeVideoPlayerBridge>((ref) {
  return const NativeVideoPlayerBridge();
});

@Riverpod(keepAlive: true)
AddonRepository addonRepository(Ref ref) {
  return AddonRepository(
    db: ref.watch(appDatabaseProvider),
    client: ref.watch(stremioClientProvider),
  );
}

@Riverpod(keepAlive: true)
CatalogRepository catalogRepository(Ref ref) {
  return CatalogRepository(
    client: ref.watch(stremioClientProvider),
    addonRepository: ref.watch(addonRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
LibraryRepository libraryRepository(Ref ref) {
  return LibraryRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
class AppSettingsController extends _$AppSettingsController {
  @override
  Future<AppSettings> build() async {
    return ref.watch(settingsRepositoryProvider).loadSettings();
  }

  Future<void> updateSettings(AppSettings updated) async {
    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }
}

@Riverpod(keepAlive: true)
class AddonsController extends _$AddonsController {
  @override
  Future<List<InstalledAddon>> build() async {
    return ref.watch(addonRepositoryProvider).loadAddons();
  }

  Future<Result<AddonManifest>> previewUrl(String rawUrl) {
    return ref.read(addonRepositoryProvider).previewManifest(rawUrl);
  }

  Future<Result<InstalledAddon>> installManifest({
    required String rawUrl,
    required AddonManifest manifest,
  }) async {
    final res = await ref
        .read(addonRepositoryProvider)
        .installFromManifest(rawUrl: rawUrl, manifest: manifest);

    if (res is Success<InstalledAddon>) {
      final current = state.valueOrNull ?? const <InstalledAddon>[];
      final withoutDup = current.where((a) => a.id != res.value.id).toList();
      state = AsyncData([res.value, ...withoutDup]);
      ref
        ..invalidate(homeCatalogProvider)
        ..invalidate(homeSectionsProvider);
    }
    return res;
  }

  Future<Result<InstalledAddon>> toggleInstallProposed(
    InstalledAddon addon,
  ) async {
    final res =
        await ref.read(addonRepositoryProvider).installProposedAddon(addon);
    if (res is Success<InstalledAddon>) {
      final current = state.valueOrNull ?? const <InstalledAddon>[];
      state = AsyncData([
        for (final a in current)
          if (a.id == addon.id || a.id == res.value.id) res.value else a,
      ]);
      ref
        ..invalidate(homeCatalogProvider)
        ..invalidate(homeSectionsProvider);
    }
    return res;
  }

  Future<void> toggleEnabled(InstalledAddon addon,
      {required bool enabled}) async {
    final updated = addon.copyWith(enabled: enabled);
    await ref.read(addonRepositoryProvider).updateAddonState(updated);
    final current = state.valueOrNull ?? const <InstalledAddon>[];
    state = AsyncData([
      for (final a in current)
        if (a.id == addon.id) updated else a,
    ]);
    ref
      ..invalidate(homeCatalogProvider)
      ..invalidate(homeSectionsProvider);
  }

  Future<void> deleteAddon(String addonId) async {
    await ref.read(addonRepositoryProvider).removeAddon(addonId);
    final current = state.valueOrNull ?? const <InstalledAddon>[];
    state = AsyncData(current.where((a) => a.id != addonId).toList());
    ref
      ..invalidate(homeCatalogProvider)
      ..invalidate(homeSectionsProvider);
  }
}

final homeSectionsProvider =
    FutureProvider.autoDispose<List<HomeCatalogSection>>((ref) async {
  final addons = await ref.watch(addonsControllerProvider.future);
  return ref
      .watch(catalogRepositoryProvider)
      .fetchHomeSections(activeAddons: addons);
});

@riverpod
Future<List<MediaItem>> homeCatalog(Ref ref) async {
  final addons = await ref.watch(addonsControllerProvider.future);
  return ref
      .watch(catalogRepositoryProvider)
      .fetchMergedCatalog(activeAddons: addons);
}

@Riverpod(keepAlive: true)
class WatchlistController extends _$WatchlistController {
  @override
  Future<List<MediaItem>> build() async {
    return ref.watch(libraryRepositoryProvider).loadWatchlist();
  }

  Future<void> toggle(MediaItem item) async {
    final current = state.valueOrNull ?? const <MediaItem>[];
    final exists = current.any((m) => m.id == item.id);
    if (exists) {
      await ref.read(libraryRepositoryProvider).removeFromWatchlist(item.id);
      state = AsyncData(current.where((m) => m.id != item.id).toList());
    } else {
      await ref.read(libraryRepositoryProvider).addToWatchlist(item);
      state = AsyncData([item, ...current]);
    }
  }
}

@Riverpod(keepAlive: true)
class WatchHistoryController extends _$WatchHistoryController {
  @override
  Future<List<WatchProgressItem>> build() async {
    return ref.watch(libraryRepositoryProvider).loadWatchHistory();
  }

  Future<void> saveProgress(WatchProgressItem item) async {
    await ref.read(libraryRepositoryProvider).saveWatchProgress(item);
    final current = state.valueOrNull ?? const <WatchProgressItem>[];
    final filtered = current.where((e) => e.media.id != item.media.id).toList();
    state = AsyncData([item, ...filtered]);
  }
}

@Riverpod(keepAlive: true)
class DownloadsController extends _$DownloadsController {
  @override
  Future<List<DownloadTaskItem>> build() async {
    return ref.watch(libraryRepositoryProvider).loadDownloads();
  }

  Future<void> enqueueDownload({
    required MediaItem media,
    required StreamSource stream,
  }) async {
    final current = state.valueOrNull ?? const <DownloadTaskItem>[];
    final activeCount =
        current.where((d) => d.status == DownloadStatus.downloading).length;
    final initialStatus =
        activeCount < 2 ? DownloadStatus.downloading : DownloadStatus.queued;

    final task = DownloadTaskItem(
      id: 'dl_${media.id}',
      mediaId: media.id,
      title: media.title,
      thumbnail: media.backdrop ?? media.poster,
      quality: stream.quality,
      totalBytes: stream.sizeBytes > 0
          ? stream.sizeBytes
          : (1.8 * 1024 * 1024 * 1024).round(),
      downloadedBytes: 0,
      status: initialStatus,
      streamUrl: stream.url,
    );
    await ref.read(libraryRepositoryProvider).upsertDownload(task);
    final withoutOld = current.where((d) => d.id != task.id).toList();
    state = AsyncData([task, ...withoutOld]);
  }

  Future<void> togglePause(DownloadTaskItem task) async {
    if (task.status == DownloadStatus.completed) return;
    final nextStatus = task.status == DownloadStatus.downloading
        ? DownloadStatus.paused
        : DownloadStatus.downloading;
    final updated = task.copyWith(status: nextStatus);
    await ref.read(libraryRepositoryProvider).upsertDownload(updated);
    final current = state.valueOrNull ?? const <DownloadTaskItem>[];
    state = AsyncData([
      for (final d in current)
        if (d.id == task.id) updated else d,
    ]);
  }

  Future<void> pauseAll() async {
    final current = state.valueOrNull ?? const <DownloadTaskItem>[];
    final next = <DownloadTaskItem>[];
    for (final d in current) {
      if (d.status == DownloadStatus.downloading ||
          d.status == DownloadStatus.queued) {
        final paused = d.copyWith(status: DownloadStatus.paused);
        await ref.read(libraryRepositoryProvider).upsertDownload(paused);
        next.add(paused);
      } else {
        next.add(d);
      }
    }
    state = AsyncData(next);
  }

  Future<void> removeDownload(String id) async {
    await ref.read(libraryRepositoryProvider).deleteDownload(id);
    final current = state.valueOrNull ?? const <DownloadTaskItem>[];
    state = AsyncData(current.where((d) => d.id != id).toList());
  }
}
