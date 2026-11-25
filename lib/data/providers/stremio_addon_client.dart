import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:muvio/core/errors/result.dart';
import 'package:muvio/core/utils/app_logger.dart';
import 'package:muvio/core/utils/url_validator.dart';
import 'package:muvio/data/models/addon_models.dart';
import 'package:muvio/data/models/media_models.dart';

/// Unified abstraction for Stremio addons and Nuvio plugins.
abstract interface class MediaProvider {
  Future<Result<AddonManifest>> fetchManifest(String rawManifestUrl);

  Future<Result<List<MediaItem>>> fetchCatalog({
    required InstalledAddon addon,
    required String type,
    required String catalogId,
    int skip = 0,
    String? searchQuery,
  });

  Future<Result<MediaItem>> fetchMeta({
    required InstalledAddon addon,
    required String type,
    required String mediaId,
  });

  Future<Result<List<StreamSource>>> fetchStreams({
    required InstalledAddon addon,
    required String type,
    required String mediaId,
  });

  Future<Result<List<SubtitleTrackItem>>> fetchSubtitles({
    required InstalledAddon addon,
    required String type,
    required String mediaId,
    String? videoHash,
    String? filename,
  });
}

/// Official Stremio protocol HTTP client with strict JSON validation,
/// URL safety checks, and Nuvio plugin manifest fallback parsing.
class StremioAddonClient implements MediaProvider {
  const StremioAddonClient(this._dio);

  final Dio _dio;

  @override
  Future<Result<AddonManifest>> fetchManifest(String rawManifestUrl) async {
    final validated = UrlSecurityValidator.validateAddonUrl(rawManifestUrl);
    if (validated is Failure<Uri>) {
      return Failure(validated.failure);
    }

    final uri = (validated as Success<Uri>).value;
    try {
      final response = await _dio.getUri<dynamic>(uri);
      final map = _decodeJsonMap(response.data);
      if (map == null) {
        return const Failure(
            ParseFailure('Le manifest reçu n’est pas un JSON valide.'));
      }

      final isNuvio = map.containsKey('nuvioVersion') ||
          map['protocol']?.toString().toLowerCase() == 'nuvio';

      final manifest = AddonManifest.fromJson(
        map,
        kind: isNuvio ? AddonKind.nuvio : AddonKind.stremio,
      );
      return Success(manifest);
    } on FormatException catch (e) {
      return Failure(ParseFailure(e.message, cause: e));
    } on DioException catch (e) {
      return Failure(
        NetworkFailure(
          'Impossible de joindre l’addon (${e.response?.statusCode ?? 'réseau'}).',
          cause: e,
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e, st) {
      AppLogger.error('AddonClient', 'fetchManifest failed', e, st);
      return Failure(
          ParseFailure('Erreur inattendue sur le manifest.', cause: e));
    }
  }

  @override
  Future<Result<List<MediaItem>>> fetchCatalog({
    required InstalledAddon addon,
    required String type,
    required String catalogId,
    int skip = 0,
    String? searchQuery,
  }) async {
    if (addon.isOffline) {
      return const Failure(
          AddonOfflineFailure('Addon hors ligne (circuit breaker).'));
    }

    final extraSegments = <String>[];
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      extraSegments.add('search=${Uri.encodeComponent(searchQuery.trim())}');
    } else if (skip > 0) {
      extraSegments.add('skip=$skip');
    }

    final suffix = extraSegments.isEmpty ? '' : '/${extraSegments.join('&')}';
    final url = '${addon.baseUrl}/catalog/$type/$catalogId$suffix.json';

    try {
      final response = await _dio.get<dynamic>(url);
      final map = _decodeJsonMap(response.data);
      if (map == null || map['metas'] is! List) {
        return const Failure(ParseFailure('Format catalogue invalide.'));
      }

      final items = <MediaItem>[];
      for (final raw in map['metas'] as List) {
        if (raw is Map<String, dynamic>) {
          final parsed = MediaItem.fromStremioMeta(raw);
          if (parsed.id.isNotEmpty && parsed.poster.isNotEmpty) {
            items.add(parsed);
          }
        }
      }
      return Success(items);
    } catch (e) {
      return Failure(
          NetworkFailure('Échec catalogue ${addon.manifest.name}', cause: e));
    }
  }

  @override
  Future<Result<MediaItem>> fetchMeta({
    required InstalledAddon addon,
    required String type,
    required String mediaId,
  }) async {
    if (addon.isOffline) {
      return const Failure(AddonOfflineFailure('Addon hors ligne.'));
    }

    final encodedId = Uri.encodeComponent(mediaId);
    final url = '${addon.baseUrl}/meta/$type/$encodedId.json';

    try {
      final response = await _dio.get<dynamic>(url);
      final map = _decodeJsonMap(response.data);
      if (map == null || map['meta'] is! Map<String, dynamic>) {
        return const Failure(ParseFailure('Format meta invalide.'));
      }
      return Success(
        MediaItem.fromStremioMeta(map['meta'] as Map<String, dynamic>),
      );
    } catch (e) {
      return Failure(
          NetworkFailure('Échec meta ${addon.manifest.name}', cause: e));
    }
  }

  @override
  Future<Result<List<StreamSource>>> fetchStreams({
    required InstalledAddon addon,
    required String type,
    required String mediaId,
  }) async {
    if (addon.isOffline) {
      return const Failure(AddonOfflineFailure('Addon hors ligne.'));
    }

    final encodedId = Uri.encodeComponent(mediaId);
    final url = '${addon.baseUrl}/stream/$type/$encodedId.json';

    try {
      final response = await _dio.get<dynamic>(url);
      final map = _decodeJsonMap(response.data);
      if (map == null || map['streams'] is! List) {
        return const Failure(ParseFailure('Format stream invalide.'));
      }

      final streams = <StreamSource>[];
      for (final raw in map['streams'] as List) {
        if (raw is Map<String, dynamic>) {
          final source = StreamSource.fromStremioJson(
            raw,
            addonId: addon.id,
            addonName: addon.manifest.name,
          );
          if (source.url.isNotEmpty &&
              UrlSecurityValidator.isSafeStreamUrl(source.url)) {
            streams.add(source);
          }
        }
      }
      return Success(streams);
    } catch (e) {
      return Failure(
          NetworkFailure('Échec streams ${addon.manifest.name}', cause: e));
    }
  }

  @override
  Future<Result<List<SubtitleTrackItem>>> fetchSubtitles({
    required InstalledAddon addon,
    required String type,
    required String mediaId,
    String? videoHash,
    String? filename,
  }) async {
    if (addon.isOffline) {
      return const Failure(AddonOfflineFailure('Addon hors ligne.'));
    }

    final encodedId = Uri.encodeComponent(mediaId);
    final queryParts = <String>[];
    if (videoHash != null && videoHash.isNotEmpty) {
      queryParts.add('videoHash=${Uri.encodeComponent(videoHash)}');
    }
    if (filename != null && filename.isNotEmpty) {
      queryParts.add('filename=${Uri.encodeComponent(filename)}');
    }

    final extra = queryParts.isEmpty ? '' : '/${queryParts.join('&')}';
    final url = '${addon.baseUrl}/subtitles/$type/$encodedId$extra.json';

    try {
      final response = await _dio.get<dynamic>(url);
      final map = _decodeJsonMap(response.data);
      if (map == null || map['subtitles'] is! List) {
        return const Failure(ParseFailure('Format sous-titres invalide.'));
      }

      final subs = <SubtitleTrackItem>[];
      for (final raw in map['subtitles'] as List) {
        if (raw is Map<String, dynamic>) {
          final parsed = SubtitleTrackItem.fromJson(raw);
          if (parsed.url.isNotEmpty) subs.add(parsed);
        }
      }
      return Success(subs);
    } catch (e) {
      return Failure(
          NetworkFailure('Échec sous-titres ${addon.manifest.name}', cause: e));
    }
  }

  Map<String, dynamic>? _decodeJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    return null;
  }
}

/// Stream deduplication and quality ranking helper.
class StreamDeduplicator {
  const StreamDeduplicator._();

  static List<StreamSource> deduplicateAndRank(List<StreamSource> raw) {
    final byKey = <String, StreamSource>{};
    for (final stream in raw) {
      final key = stream.deduplicationKey;
      final existing = byKey[key];
      if (existing == null || stream.qualityScore > existing.qualityScore) {
        byKey[key] = stream;
      }
    }
    final list = byKey.values.toList()
      ..sort((a, b) => b.qualityScore.compareTo(a.qualityScore));
    return list;
  }
}
