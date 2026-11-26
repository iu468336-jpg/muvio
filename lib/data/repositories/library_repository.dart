import 'package:drift/drift.dart';
import 'package:muvio/core/storage/app_database.dart';
import 'package:muvio/data/models/media_models.dart';

/// Persists Watchlist ("Ma liste"), real Watch History with exact-second resume,
/// and real queued/active Downloads inside Drift SQLite (zero fake pre-populated rows).
class LibraryRepository {
  LibraryRepository(this._db);

  final AppDatabase _db;

  Future<List<MediaItem>> loadWatchlist() async {
    final rows = await (_db.select(_db.libraryEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
        .get();

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
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

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
