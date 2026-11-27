import 'package:flutter/services.dart';
import 'package:muvio/core/errors/result.dart';
import 'package:muvio/core/utils/app_logger.dart';
import 'package:muvio/core/utils/url_validator.dart';
import 'package:muvio/data/models/addon_models.dart';
import 'package:muvio/data/models/media_models.dart';

/// Platform-channel bridge to Android's native QuickJS Nuvio Scraper Engine
/// (`NuvioPluginRuntimeController`), executing Direct HTTP / HLS / MKV scrapers on-device.
class NuvioPluginBridge {
  const NuvioPluginBridge();

  static const MethodChannel _channel =
      MethodChannel('app.muvio.mobile/nuvio_plugins');

  Future<Result<List<StreamSource>>> fetchStreams({
    required InstalledAddon addon,
    required String type,
    required String mediaId,
  }) async {
    try {
      final rawList = await _channel.invokeMethod<List<dynamic>>(
        'fetchStreams',
        <String, dynamic>{
          'manifestUrl': addon.manifestUrl,
          'addonId': addon.id,
          'addonName': addon.manifest.name,
          'type': type,
          'mediaId': mediaId,
        },
      );
      if (rawList == null || rawList.isEmpty) {
        return const Success(<StreamSource>[]);
      }

      final streams = <StreamSource>[];
      for (final item in rawList) {
        if (item is Map<dynamic, dynamic>) {
          final normalized = _normalizeDynamicMap(item);
          final source = StreamSource.fromStremioJson(
            normalized,
            addonId: normalized['addonId']?.toString() ?? addon.id,
            addonName:
                normalized['addonName']?.toString() ?? addon.manifest.name,
          );
          if (source.url.isNotEmpty &&
              UrlSecurityValidator.isSafeStreamUrl(source.url)) {
            streams.add(source);
          }
        }
      }
      return Success(streams);
    } on MissingPluginException {
      return const Success(<StreamSource>[]);
    } catch (e, st) {
      AppLogger.warn('NuvioBridge', 'Scraper error for ${addon.id}: $e');
      AppLogger.error('NuvioBridge', 'Details', e, st);
      return Failure(
        NetworkFailure('Erreur plugin Nuvio ${addon.manifest.name}', cause: e),
      );
    }
  }

  Map<String, dynamic> _normalizeDynamicMap(Map<dynamic, dynamic> raw) {
    final out = <String, dynamic>{};
    for (final entry in raw.entries) {
      final key = entry.key?.toString() ?? '';
      if (key.isEmpty) continue;
      final value = entry.value;
      if (value is Map<dynamic, dynamic>) {
        out[key] = _normalizeDynamicMap(value);
      } else if (value is List) {
        out[key] = value.map((e) {
          if (e is Map<dynamic, dynamic>) return _normalizeDynamicMap(e);
          return e;
        }).toList();
      } else {
        out[key] = value;
      }
    }
    return out;
  }
}
