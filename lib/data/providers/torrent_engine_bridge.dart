import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:muvio/core/errors/result.dart';
import 'package:muvio/core/utils/app_logger.dart';
import 'package:muvio/data/models/seed_catalog.dart';

@immutable
class TorrentStreamTelemetry {
  const TorrentStreamTelemetry({
    this.hasMetadata = false,
    this.readyToPlay = false,
    this.peers = 0,
    this.seeds = 0,
    this.downloadSpeedBytesPerSec = 0,
    this.progress = 0,
    this.bufferedBytes = 0,
    this.fileSize = 0,
  });

  factory TorrentStreamTelemetry.fromMap(Map<dynamic, dynamic> map) {
    return TorrentStreamTelemetry(
      hasMetadata: map['hasMetadata'] == true,
      readyToPlay: map['readyToPlay'] == true,
      peers: (map['peers'] as num?)?.toInt() ?? 0,
      seeds: (map['seeds'] as num?)?.toInt() ?? 0,
      downloadSpeedBytesPerSec: (map['downloadSpeed'] as num?)?.toInt() ?? 0,
      progress: (map['progress'] as num?)?.toDouble() ?? 0,
      bufferedBytes: (map['bufferedBytes'] as num?)?.toInt() ?? 0,
      fileSize: (map['fileSize'] as num?)?.toInt() ?? 0,
    );
  }

  final bool hasMetadata;
  final bool readyToPlay;
  final int peers;
  final int seeds;
  final int downloadSpeedBytesPerSec;
  final double progress;
  final int bufferedBytes;
  final int fileSize;
}

/// Platform-channel bridge to Android's native `libtorrent4j` + `NanoHTTPD`
/// piece-accurate progressive torrent streaming server (`127.0.0.1:<port>`).
class TorrentEngineBridge {
  const TorrentEngineBridge();

  static const MethodChannel _channel =
      MethodChannel('app.muvio.mobile/torrent_engine');

  static const MethodChannel _pipChannel =
      MethodChannel('app.muvio.mobile/pip');

  /// Starts sequential download of header & tail pieces and returns a local
  /// `http://127.0.0.1:<port>/stream` URL playable by AndroidX Media3 (`ExoPlayer`).
  Future<Result<String>> resolveMagnetOrInfoHash({
    required String magnetOrUrl,
    String? infoHash,
    int? fileIdx,
    List<String> sources = const [],
  }) async {
    try {
      final localUrl = await _channel.invokeMethod<String>(
        'startTorrentStream',
        <String, dynamic>{
          'uri': magnetOrUrl,
          'infoHash': infoHash,
          'fileIdx': fileIdx ?? 0,
          'sources': sources,
        },
      );
      if (localUrl != null && localUrl.startsWith('http://127.0.0.1')) {
        return Success(localUrl);
      }
      return const Failure(
        NetworkFailure('Serveur de streaming local non initialisé.'),
      );
    } on MissingPluginException {
      // Graceful fallback in widget tests or desktop preview environments
      return const Success(SeedCatalogData.sampleVideoHls);
    } catch (e, st) {
      AppLogger.warn('TorrentBridge', 'Torrent start error: $e');
      AppLogger.error('TorrentBridge', 'Details', e, st);
      return Failure(
        NetworkFailure('Moteur torrent indisponible: $e', cause: e),
      );
    }
  }

  Future<TorrentStreamTelemetry> pollTelemetry() async {
    try {
      final raw =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getTorrentStatus');
      if (raw != null) {
        return TorrentStreamTelemetry.fromMap(raw);
      }
      return const TorrentStreamTelemetry();
    } on MissingPluginException {
      return const TorrentStreamTelemetry(hasMetadata: true, readyToPlay: true);
    } catch (_) {
      return const TorrentStreamTelemetry();
    }
  }

  Future<void> stopAllStreams() async {
    try {
      await _channel.invokeMethod<void>('stopTorrentStream');
    } catch (_) {
      // Safe no-op when no active session
    }
  }

  Future<bool> enterPictureInPicture() async {
    try {
      final entered = await _pipChannel.invokeMethod<bool>('enterPip') ?? false;
      return entered;
    } catch (_) {
      return false;
    }
  }
}
