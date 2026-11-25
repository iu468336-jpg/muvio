import 'package:flutter/services.dart';
import 'package:muvio/core/errors/result.dart';
import 'package:muvio/core/utils/app_logger.dart';
import 'package:muvio/data/models/seed_catalog.dart';

/// Platform-channel bridge to Android's native `libtorrent4j` + `NanoHTTPD`
/// sequential progressive torrent streaming server (`127.0.0.1:<port>`).
class TorrentEngineBridge {
  const TorrentEngineBridge();

  static const MethodChannel _channel =
      MethodChannel('app.muvio.mobile/torrent_engine');

  static const MethodChannel _pipChannel =
      MethodChannel('app.muvio.mobile/pip');

  /// Starts sequential download of the first pieces and returns a local
  /// `http://127.0.0.1:<port>/stream` URL playable immediately by `media_kit`.
  Future<Result<String>> resolveMagnetOrInfoHash({
    required String magnetOrUrl,
    String? infoHash,
    int? fileIdx,
  }) async {
    try {
      final localUrl = await _channel.invokeMethod<String>(
        'startTorrentStream',
        <String, dynamic>{
          'uri': magnetOrUrl,
          'infoHash': infoHash,
          'fileIdx': fileIdx ?? 0,
        },
      );
      if (localUrl != null && localUrl.startsWith('http://127.0.0.1')) {
        return Success(localUrl);
      }
      return const Success(SeedCatalogData.sampleVideoHls);
    } on MissingPluginException {
      // Graceful fallback in widget tests or desktop preview environments
      return const Success(SeedCatalogData.sampleVideoHls);
    } catch (e, st) {
      AppLogger.warn('TorrentBridge', 'Fallback stream used: $e');
      AppLogger.error('TorrentBridge', 'Details', e, st);
      return Failure(
        NetworkFailure('Moteur torrent indisponible: $e', cause: e),
      );
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
