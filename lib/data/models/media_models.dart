import 'package:flutter/foundation.dart';

@immutable
class EpisodeVideo {
  const EpisodeVideo({
    required this.id,
    required this.title,
    required this.season,
    required this.episode,
    this.overview = '',
    this.thumbnail,
    this.released,
  });

  factory EpisodeVideo.fromJson(Map<String, dynamic> json) {
    return EpisodeVideo(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ??
          json['name']?.toString() ??
          'Épisode ${json['episode'] ?? 1}',
      season: int.tryParse(json['season']?.toString() ?? '1') ?? 1,
      episode: int.tryParse(json['episode']?.toString() ?? '1') ?? 1,
      overview:
          json['overview']?.toString() ?? json['description']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString(),
      released: json['released']?.toString(),
    );
  }

  final String id;
  final String title;
  final int season;
  final int episode;
  final String overview;
  final String? thumbnail;
  final String? released;
}

@immutable
class MediaItem {
  const MediaItem({
    required this.id,
    required this.type,
    required this.title,
    required this.poster,
    this.backdrop,
    this.synopsis = '',
    this.year = 2024,
    this.rating = 8.4,
    this.genres = const [],
    this.cast = const [],
    this.runtime = '2h 15m',
    this.isNewRelease = false,
    this.isOriginal = false,
    this.episodes = const [],
    this.introEndSeconds = 85,
  });

  factory MediaItem.fromStremioMeta(Map<String, dynamic> json) {
    final rawYear =
        json['releaseInfo']?.toString() ?? json['year']?.toString() ?? '2024';
    final parsedYear =
        int.tryParse(rawYear.split(RegExp('[^0-9]')).first) ?? 2024;
    final rawRating =
        double.tryParse(json['imdbRating']?.toString() ?? '') ?? 8.0;

    final genres = <String>[];
    if (json['genres'] is List) {
      for (final g in json['genres'] as List) {
        if (g != null) genres.add(g.toString());
      }
    }

    final cast = <String>[];
    if (json['cast'] is List) {
      for (final c in json['cast'] as List) {
        if (c != null) cast.add(c.toString());
      }
    }

    final episodes = <EpisodeVideo>[];
    if (json['videos'] is List) {
      for (final v in json['videos'] as List) {
        if (v is Map<String, dynamic>) {
          episodes.add(EpisodeVideo.fromJson(v));
        }
      }
    }

    final poster = json['poster']?.toString() ?? '';
    final background = json['background']?.toString() ?? poster;

    return MediaItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'movie',
      title: json['name']?.toString() ?? 'Sans titre',
      poster: poster,
      backdrop: background,
      synopsis: json['description']?.toString() ?? '',
      year: parsedYear,
      rating: rawRating,
      genres: genres,
      cast: cast,
      runtime: json['runtime']?.toString() ?? '2h 10m',
      episodes: episodes,
    );
  }

  final String id;
  final String type; // 'movie' | 'series' | 'channel'
  final String title;
  final String poster;
  final String? backdrop;
  final String synopsis;
  final int year;
  final double rating;
  final List<String> genres;
  final List<String> cast;
  final String runtime;
  final bool isNewRelease;
  final bool isOriginal;
  final List<EpisodeVideo> episodes;
  final int introEndSeconds;
}

@immutable
class SubtitleTrackItem {
  const SubtitleTrackItem({
    required this.id,
    required this.url,
    required this.lang,
    required this.label,
  });

  factory SubtitleTrackItem.fromJson(Map<String, dynamic> json) {
    final lang = json['lang']?.toString() ?? 'fr';
    return SubtitleTrackItem(
      id: json['id']?.toString() ?? lang,
      url: json['url']?.toString() ?? '',
      lang: lang,
      label: json['label']?.toString() ?? lang.toUpperCase(),
    );
  }

  final String id;
  final String url;
  final String lang;
  final String label;
}

@immutable
class StreamSource {
  const StreamSource({
    required this.id,
    required this.addonId,
    required this.addonName,
    required this.title,
    required this.quality,
    required this.hdrMode,
    required this.url,
    this.infoHash,
    this.fileIdx,
    this.sizeBytes = 0,
    this.seeders = 0,
    this.leechers = 0,
    this.subtitles = const [],
  });

  factory StreamSource.fromStremioJson(
    Map<String, dynamic> json, {
    required String addonId,
    required String addonName,
  }) {
    final name = json['name']?.toString() ?? addonName;
    final rawTitle =
        json['title']?.toString() ?? json['description']?.toString() ?? '';
    final combined = '$name $rawTitle'.toUpperCase();

    final quality = combined.contains('2160P') || combined.contains('4K')
        ? '4K'
        : combined.contains('1080P')
            ? '1080p'
            : combined.contains('720P')
                ? '720p'
                : '1080p';

    final hdr =
        combined.contains('HDR') || combined.contains('DV') ? 'HDR' : 'SDR';

    final infoHash = json['infoHash']?.toString();
    final directUrl = json['url']?.toString() ??
        json['externalUrl']?.toString() ??
        (infoHash != null ? 'magnet:?xt=urn:btih:$infoHash' : '');

    final seedMatch = RegExp(r'👤\s*(\d+)').firstMatch(rawTitle);
    final seeders =
        seedMatch != null ? int.tryParse(seedMatch.group(1)!) ?? 120 : 120;

    final sizeMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(GB|MB)', caseSensitive: false)
        .firstMatch(rawTitle);
    var bytes = 0;
    if (sizeMatch != null) {
      final numVal = double.tryParse(sizeMatch.group(1)!) ?? 0;
      final unit = sizeMatch.group(2)!.toUpperCase();
      bytes = unit == 'GB'
          ? (numVal * 1024 * 1024 * 1024).round()
          : (numVal * 1024 * 1024).round();
    }

    final subs = <SubtitleTrackItem>[];
    if (json['subtitles'] is List) {
      for (final s in json['subtitles'] as List) {
        if (s is Map<String, dynamic>) {
          subs.add(SubtitleTrackItem.fromJson(s));
        }
      }
    }

    return StreamSource(
      id: '${addonId}_${directUrl.hashCode}',
      addonId: addonId,
      addonName: addonName,
      title: rawTitle.isEmpty ? '$addonName · $quality $hdr' : rawTitle,
      quality: quality,
      hdrMode: hdr,
      url: directUrl,
      infoHash: infoHash,
      fileIdx: int.tryParse(json['fileIdx']?.toString() ?? ''),
      sizeBytes: bytes,
      seeders: seeders,
      subtitles: subs,
    );
  }

  final String id;
  final String addonId;
  final String addonName;
  final String title;
  final String quality; // '4K' | '1080p' | '720p'
  final String hdrMode; // 'HDR' | 'SDR'
  final String url;
  final String? infoHash;
  final int? fileIdx;
  final int sizeBytes;
  final int seeders;
  final int leechers;
  final List<SubtitleTrackItem> subtitles;

  bool get isTorrent =>
      (infoHash != null && infoHash!.isNotEmpty) || url.startsWith('magnet:?');

  int get qualityScore {
    final resWeight = switch (quality) {
      '4K' => 400,
      '1080p' => 300,
      '720p' => 200,
      _ => 100,
    };
    final hdrWeight = hdrMode == 'HDR' ? 50 : 0;
    return resWeight + hdrWeight + (seeders.clamp(0, 500) ~/ 10);
  }

  String get deduplicationKey =>
      infoHash != null && infoHash!.isNotEmpty ? 'btih:$infoHash' : 'url:$url';
}

enum DownloadStatus { queued, downloading, paused, completed, failed }

@immutable
class DownloadTaskItem {
  const DownloadTaskItem({
    required this.id,
    required this.mediaId,
    required this.title,
    required this.thumbnail,
    required this.quality,
    required this.totalBytes,
    required this.downloadedBytes,
    required this.status,
    required this.streamUrl,
  });

  final String id;
  final String mediaId;
  final String title;
  final String thumbnail;
  final String quality;
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final String streamUrl;

  double get progress =>
      totalBytes <= 0 ? 0 : (downloadedBytes / totalBytes).clamp(0.0, 1.0);

  int get progressPercent => (progress * 100).round();

  DownloadTaskItem copyWith({
    int? downloadedBytes,
    DownloadStatus? status,
  }) {
    return DownloadTaskItem(
      id: id,
      mediaId: mediaId,
      title: title,
      thumbnail: thumbnail,
      quality: quality,
      totalBytes: totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      streamUrl: streamUrl,
    );
  }
}

@immutable
class WatchProgressItem {
  const WatchProgressItem({
    required this.media,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.updatedAt,
    this.episodeBadge,
    this.lastStreamUrl,
  });

  final MediaItem media;
  final int positionSeconds;
  final int durationSeconds;
  final DateTime updatedAt;
  final String? episodeBadge;
  final String? lastStreamUrl;

  double get progressFraction => durationSeconds <= 0
      ? 0
      : (positionSeconds / durationSeconds).clamp(0.0, 1.0);

  Duration get remainingDuration {
    final rem = durationSeconds - positionSeconds;
    return Duration(seconds: rem < 0 ? 0 : rem);
  }
}
