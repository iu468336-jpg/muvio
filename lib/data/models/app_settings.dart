import 'package:flutter/foundation.dart';

enum DefaultVideoQuality { auto, uhd4k, fhd1080p, hd720p }

enum VideoDecoderMode { hardware, software }

@immutable
class AppSettings {
  const AppSettings({
    this.localeCode = 'fr',
    this.defaultQuality = DefaultVideoQuality.uhd4k,
    this.preferredAudioLang = 'fr',
    this.preferredSubtitleLang = 'fr',
    this.subtitleFontSize = 18,
    this.pureAmoledBlack = false,
    this.decoderMode = VideoDecoderMode.hardware,
    this.autoRotatePlayer = true,
    this.useSdCardStorage = false,
  });

  final String localeCode;
  final DefaultVideoQuality defaultQuality;
  final String preferredAudioLang;
  final String preferredSubtitleLang;
  final double subtitleFontSize;
  final bool pureAmoledBlack;
  final VideoDecoderMode decoderMode;
  final bool autoRotatePlayer;
  final bool useSdCardStorage;

  String get qualityLabel => switch (defaultQuality) {
        DefaultVideoQuality.auto => 'Auto',
        DefaultVideoQuality.uhd4k => '4K HDR',
        DefaultVideoQuality.fhd1080p => '1080p',
        DefaultVideoQuality.hd720p => '720p',
      };

  AppSettings copyWith({
    String? localeCode,
    DefaultVideoQuality? defaultQuality,
    String? preferredAudioLang,
    String? preferredSubtitleLang,
    double? subtitleFontSize,
    bool? pureAmoledBlack,
    VideoDecoderMode? decoderMode,
    bool? autoRotatePlayer,
    bool? useSdCardStorage,
  }) {
    return AppSettings(
      localeCode: localeCode ?? this.localeCode,
      defaultQuality: defaultQuality ?? this.defaultQuality,
      preferredAudioLang: preferredAudioLang ?? this.preferredAudioLang,
      preferredSubtitleLang:
          preferredSubtitleLang ?? this.preferredSubtitleLang,
      subtitleFontSize: subtitleFontSize ?? this.subtitleFontSize,
      pureAmoledBlack: pureAmoledBlack ?? this.pureAmoledBlack,
      decoderMode: decoderMode ?? this.decoderMode,
      autoRotatePlayer: autoRotatePlayer ?? this.autoRotatePlayer,
      useSdCardStorage: useSdCardStorage ?? this.useSdCardStorage,
    );
  }
}
