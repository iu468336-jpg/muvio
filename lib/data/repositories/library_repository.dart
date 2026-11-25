import 'package:drift/drift.dart';
import 'package:muvio/core/storage/app_database.dart';
import 'package:muvio/data/models/media_models.dart';
import 'package:muvio/data/models/seed_catalog.dart';

/// Persists Watchlist ("Ma liste"), Watch History with exact-second resume,
/// and queued/active Downloads inside Drift SQLite.
class LibraryRepository {
  LibraryRepository(this._db);

  final AppDatabase _db;

  Future<List<MediaItem>> loadWatchlist() async {
    final rows = await (_db.select(_db.libraryEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
        .get();

    if (rows.isEmpty) {
      // Seed initial curated watchlist matching Screen 5 mockup
      final initialIds = {'tt0816692', 'tt0468569', 'tt1375666', 'tt0068646'};
      final seeded = SeedCatalogData.catalogItems
          .where((m) => initialIds.contains(m.id))
          .toList();
      for (final item in seeded) {
        await addToWatchlist(item);
      }
      return seeded;
    }

    return rows
        .map(
          (r) => MediaItem(
            id: r.mediaId,
            type: r.mediaType,
            title: r.title,
            poster: r.poster,
            backdrop: r.backdrop,
            synopsis: r.synopsis,
            year: r.year,
            rating: r.rating,
          ),
        )
        .toList();
  }

  Future<void> addToWatchlist(MediaItem item) async {
    await _db.into(_db.libraryEntries).insertOnConflictUpdate(
          LibraryEntriesCompanion.insert(
            mediaId: item.id,
            mediaType: item.type,
            title: item.title,
            poster: item.poster,
            backdrop: Value(item.backdrop),
            synopsis: Value(item.synopsis),
            year: Value(item.year),
            rating: Value(item.rating),
            addedAt: DateTime.now(),
          ),
        );
  }

  Future<void> removeFromWatchlist(String mediaId) async {
    await (_db.delete(_db.libraryEntries)
          ..where((t) => t.mediaId.equals(mediaId)))
        .go();
  }

  Future<List<WatchProgressItem>> loadWatchHistory() async {
    final rows = await (_db.select(_db.playbackEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();

    if (rows.isEmpty) {
      // Seed initial "Continuer à regarder" items matching Screen 1 mockup
      final dune = SeedCatalogData.heroItems[1];
      final tlou =
          SeedCatalogData.catalogItems.firstWhere((e) => e.id == 'tt3581920');
      final shogun = SeedCatalogData.heroItems[3];
      final interstellar = SeedCatalogData.heroItems[2];

      final seeded = [
        WatchProgressItem(
          media: dune,
          positionSeconds: 2640,
          durationSeconds: 12600,
          episodeBadge: '2h 46m restantes',
          updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        WatchProgressItem(
          media: tlou,
          positionSeconds: 1920,
          durationSeconds: 3480,
          episodeBadge: 'S1 · E5',
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        WatchProgressItem(
          media: shogun,
          positionSeconds: 2500,
          durationSeconds: 3600,
          episodeBadge: 'S1 · E7',
          updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        WatchProgressItem(
          media: interstellar,
          positionSeconds: 5880,
          durationSeconds: 10140,
          episodeBadge: '1h 11m restantes',
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      for (final p in seeded) {
        await saveWatchProgress(p);
      }
      return seeded;
    }

    return rows
        .map(
          (r) => WatchProgressItem(
            media: MediaItem(
              id: r.mediaId,
              type: r.mediaType,
              title: r.title,
              poster: r.poster,
              backdrop: r.backdrop,
            ),
            positionSeconds: r.positionSeconds,
            durationSeconds: r.durationSeconds,
            episodeBadge: r.episodeBadge,
            lastStreamUrl: r.lastStreamUrl,
            updatedAt: r.updatedAt,
          ),
        )
        .toList();
  }

  Future<void> saveWatchProgress(WatchProgressItem progress) async {
    await _db.into(_db.playbackEntries).insertOnConflictUpdate(
          PlaybackEntriesCompanion.insert(
            mediaId: progress.media.id,
            mediaType: progress.media.type,
            title: progress.media.title,
            poster: progress.media.poster,
            backdrop: Value(progress.media.backdrop),
            positionSeconds: Value(progress.positionSeconds),
            durationSeconds: Value(progress.durationSeconds),
            episodeBadge: Value(progress.episodeBadge),
            lastStreamUrl: Value(progress.lastStreamUrl),
            updatedAt: progress.updatedAt,
          ),
        );
  }

  Future<List<DownloadTaskItem>> loadDownloads() async {
    final rows = await (_db.select(_db.downloadEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    if (rows.isEmpty) {
      // Seed Screen 5 downloads mockup state
      const gb = 1024 * 1024 * 1024;
      final total18Gb = (1.8 * gb).round();
      final seeded = [
        DownloadTaskItem(
          id: 'dl_dune2',
          mediaId: 'tt15239678',
          title: 'Dune: Part Two',
          thumbnail:
              'https://image.tmdb.org/t/p/w500/xOMo8BRK7PfcJv9JCnx7s5hj0PX.jpg',
          quality: '1080p',
          totalBytes: total18Gb,
          downloadedBytes: (total18Gb * 0.65).round(),
          status: DownloadStatus.downloading,
          streamUrl: SeedCatalogData.sampleVideoHls,
        ),
        DownloadTaskItem(
          id: 'dl_jw4',
          mediaId: 'tt10366206',
          title: 'John Wick: Chapter 4',
          thumbnail:
              'https://image.tmdb.org/t/p/w500/h8gHn0OzBoaefsYseUByqsmEDMY.jpg',
          quality: '1080p',
          totalBytes: total18Gb,
          downloadedBytes: (total18Gb * 0.65).round(),
          status: DownloadStatus.downloading,
          streamUrl: SeedCatalogData.sampleVideoBackup,
        ),
        DownloadTaskItem(
          id: 'dl_batman',
          mediaId: 'tt1877830',
          title: 'The Batman',
          thumbnail:
              'https://image.tmdb.org/t/p/w500/b0PlSFdDwbyK0cf5RxwDpaOJQvQ.jpg',
          quality: '1080p',
          totalBytes: total18Gb,
          downloadedBytes: total18Gb,
          status: DownloadStatus.completed,
          streamUrl: SeedCatalogData.sampleVideoSciFi,
        ),
      ];
      for (final d in seeded) {
        await upsertDownload(d);
      }
      return seeded;
    }

    return rows
        .map(
          (r) => DownloadTaskItem(
            id: r.id,
            mediaId: r.mediaId,
            title: r.title,
            thumbnail: r.thumbnail,
            quality: r.quality,
            totalBytes: r.totalBytes,
            downloadedBytes: r.downloadedBytes,
            status: DownloadStatus.values.firstWhere(
              (s) => s.name == r.status,
              orElse: () => DownloadStatus.paused,
            ),
            streamUrl: r.streamUrl,
          ),
        )
        .toList();
  }

  Future<void> upsertDownload(DownloadTaskItem item) async {
    await _db.into(_db.downloadEntries).insertOnConflictUpdate(
          DownloadEntriesCompanion.insert(
            id: item.id,
            mediaId: item.mediaId,
            title: item.title,
            thumbnail: item.thumbnail,
            quality: item.quality,
            totalBytes: item.totalBytes,
            downloadedBytes: item.downloadedBytes,
            status: item.status.name,
            streamUrl: item.streamUrl,
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> deleteDownload(String id) async {
    await (_db.delete(_db.downloadEntries)..where((t) => t.id.equals(id))).go();
  }
}
