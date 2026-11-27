import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:muvio/data/models/media_models.dart';

@immutable
class NativePlayerOpenResult {
  const NativePlayerOpenResult({
    required this.textureId,
    this.aspectRatio = 16 / 9,
  });

  final int textureId;
  final double aspectRatio;
}

@immutable
class NativePlayerEvent {
  const NativePlayerEvent({
    required this.type,
    this.positionMs = 0,
    this.durationMs = 0,
    this.bufferedMs = 0,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isCompleted = false,
    this.width = 0,
    this.height = 0,
    this.aspectRatio = 16 / 9,
    this.errorMessage,
  });

  factory NativePlayerEvent.fromMap(Map<dynamic, dynamic> map) {
    return NativePlayerEvent(
      type: map['event']?.toString() ?? 'unknown',
      positionMs: (map['positionMs'] as num?)?.toInt() ?? 0,
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      bufferedMs: (map['bufferedMs'] as num?)?.toInt() ?? 0,
      isPlaying: map['isPlaying'] == true,
      isBuffering: map['isBuffering'] == true,
      isCompleted: map['isCompleted'] == true,
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      aspectRatio: (map['aspectRatio'] as num?)?.toDouble() ?? (16 / 9),
      errorMessage: map['message']?.toString(),
    );
  }

  final String type;
  final int positionMs;
  final int durationMs;
  final int bufferedMs;
  final bool isPlaying;
  final bool isBuffering;
  final bool isCompleted;
  final int width;
  final int height;
  final double aspectRatio;
  final String? errorMessage;
}

/// Platform-channel bridge to Android's native `AndroidX Media3` (`ExoPlayer`) +
/// `Jellyfin FFmpeg Audio Decoder` video engine (`SurfaceProducer` texture).
class NativeVideoPlayerBridge {
  const NativeVideoPlayerBridge();

  static const MethodChannel _channel =
      MethodChannel('app.muvio.mobile/native_player');

  static const EventChannel _eventsChannel =
      EventChannel('app.muvio.mobile/native_player_events');

  Stream<NativePlayerEvent> get events {
    return _eventsChannel.receiveBroadcastStream().map((dynamic raw) {
      if (raw is Map<dynamic, dynamic>) {
        return NativePlayerEvent.fromMap(raw);
      }
      return const NativePlayerEvent(type: 'unknown');
    });
  }

  Future<NativePlayerOpenResult?> open({
    required String url,
    String? filename,
    Map<String, String> headers = const {},
    List<SubtitleTrackItem> subtitles = const [],
    int startPositionMs = 0,
    bool preferSoftware = false,
  }) async {
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'open',
        <String, dynamic>{
          'url': url,
          'filename': filename,
          'headers': headers,
          'subtitles': subtitles
              .where((s) => s.url.isNotEmpty)
              .map(
                (s) => <String, String>{
                  'id': s.id,
                  'url': s.url,
                  'lang': s.lang,
                  'label': s.label,
                },
              )
              .toList(),
          'startPositionMs': startPositionMs,
          'preferSoftware': preferSoftware,
        },
      );
      if (raw == null) return null;
      final texId = (raw['textureId'] as num?)?.toInt();
      if (texId == null) return null;
      final ar = (raw['aspectRatio'] as num?)?.toDouble() ?? (16 / 9);
      return NativePlayerOpenResult(
        textureId: texId,
        aspectRatio: ar > 0 ? ar : (16 / 9),
      );
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> play() async {
    try {
      await _channel.invokeMethod<void>('play');
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _channel.invokeMethod<void>('pause');
    } catch (_) {}
  }

  Future<bool?> playOrPause() async {
    try {
      return await _channel.invokeMethod<bool>('playOrPause');
    } catch (_) {
      return null;
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _channel.invokeMethod<void>(
        'seek',
        <String, dynamic>{'positionMs': position.inMilliseconds},
      );
    } catch (_) {}
  }

  Future<void> setVolume(double normalizedVolume) async {
    try {
      await _channel.invokeMethod<void>(
        'setVolume',
        <String, dynamic>{'volume': normalizedVolume.clamp(0.0, 1.0)},
      );
    } catch (_) {}
  }

  Future<void> setSpeed(double speed) async {
    try {
      await _channel.invokeMethod<void>(
        'setSpeed',
        <String, dynamic>{'speed': speed},
      );
    } catch (_) {}
  }

  Future<void> setSubtitlesEnabled({required bool enabled}) async {
    try {
      await _channel.invokeMethod<void>(
        'setSubtitlesEnabled',
        <String, dynamic>{'enabled': enabled},
      );
    } catch (_) {}
  }

  Future<String> cycleAudioTrack() async {
    try {
      return await _channel.invokeMethod<String>('cycleAudioTrack') ?? 'Audio';
    } catch (_) {
      return 'Audio';
    }
  }

  Future<void> dispose() async {
    try {
      await _channel.invokeMethod<void>('dispose');
    } catch (_) {}
  }
}
