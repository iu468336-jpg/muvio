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
    this.imdbId,
    this.imdbSeason,
    this.imdbEpisode,
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
      imdbId: json['imdb_id']?.toString(),
      imdbSeason: int.tryParse(json['imdbSeason']?.toString() ?? ''),
      imdbEpisode: int.tryParse(json['imdbEpisode']?.toString() ?? ''),
    );
  }

  final String id;
  final String title;
  final int season;
  final int episode;
  final String overview;
  final String? thumbnail;
  final String? released;
  final String? imdbId;
  final int? imdbSeason;
  final int? imdbEpisode;
}

@immutable
class MediaItem {
  const MediaItem({
    required this.id,
    required this.type,
    required this.title,
    required this.poster,
    this.backdrop,
    this.imdbId,
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

  factory MediaItem.fromStremioMeta(
    Map<String, dynamic> json, {
    String? fallbackType,
  }) {
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
    } else if (json['genre'] is List) {
      for (final g in json['genre'] as List) {
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

    final id = json['id']?.toString() ?? '';
    var extractedImdb = json['imdb_id']?.toString();
    if ((extractedImdb == null || !extractedImdb.startsWith('tt')) &&
        id.startsWith('tt')) {
      extractedImdb = id.split(':').first;
    }
    if ((extractedImdb == null || !extractedImdb.startsWith('tt')) &&
        json['links'] is List) {
      for (final link in json['links'] as List) {
        if (link is Map<String, dynamic>) {
          final url = link['url']?.toString() ?? '';
          final match = RegExp(r'(tt\d{5,12})').firstMatch(url);
          if (match != null) {
            extractedImdb = match.group(1);
            break;
          }
        }
      }
    }

    final poster = json['poster']?.toString() ??
        json['background']?.toString() ??
        json['logo']?.toString() ??
        '';
    final background = json['background']?.toString() ?? poster;

    return MediaItem(
      id: id,
      type: json['type']?.toString() ?? fallbackType ?? 'movie',
      title: json['name']?.toString() ?? 'Sans titre',
      poster: poster,
      backdrop: background,
      imdbId: extractedImdb,
      synopsis: json['description']?.toString() ?? '',
      year: parsedYear,
      rating: rawRating,
      genres: genres,
      cast: cast,
      runtime: json['runtime']?.toString() ??
          (fallbackType == 'tv' ? 'En direct' : '2h 10m'),
      episodes: episodes,
    );
  }

  final String id;
  final String type; // 'movie' | 'series' | 'anime' | 'tv' | 'channel'
  final String title;
  final String poster;
  final String? backdrop;
  final String? imdbId;
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

/// Dynamic catalog row rendered on Home screen for each installed & enabled catalog addon.
@immutable
class HomeCatalogSection {
  const HomeCatalogSection({
    required this.addonId,
    required this.addonName,
    required this.catalogId,
    required this.catalogType,
    required this.catalogName,
    required this.items,
  });

  final String addonId;
  final String addonName;
  final String catalogId;
  final String catalogType;
  final String catalogName;
  final List<MediaItem> items;

  String get displayTitle {
    final lowerAddon = addonName.toLowerCase();
    final lowerCat = catalogName.toLowerCase();
    if (lowerCat.contains(lowerAddon)) {
      return catalogName;
    }
    return '$addonName — $catalogName';
  }
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
    this.sources = const [],
    this.httpHeaders = const {},
    this.filename,
    this.isExternal = false,
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

    final explicitQuality = json['quality']?.toString().toUpperCase() ?? '';
    final quality = combined.contains('2160P') ||
            combined.contains('4K') ||
            combined.contains('UHD') ||
            explicitQuality.contains('4K')
        ? '4K'
        : combined.contains('1080P') || explicitQuality.contains('1080')
            ? '1080p'
            : combined.contains('720P') || explicitQuality.contains('720')
                ? '720p'
                : json['type']?.toString() == 'live'
                    ? 'LIVE'
                    : '1080p';

    final hdr =
        combined.contains('HDR') || combined.contains('DV') ? 'HDR' : 'SDR';

    final rawHash = json['infoHash']?.toString().trim();
    final infoHash =
        (rawHash != null && rawHash.isNotEmpty) ? rawHash.toLowerCase() : null;

    final sources = <String>[];
    if (json['sources'] is List) {
      for (final src in json['sources'] as List) {
        if (src != null && src.toString().trim().isNotEmpty) {
          sources.add(src.toString().trim());
        }
      }
    }

    final rawDirectUrl = json['url']?.toString().trim();
    final rawExtUrl = json['externalUrl']?.toString().trim();
    final isExt = (rawDirectUrl == null || rawDirectUrl.isEmpty) &&
        infoHash == null &&
        rawExtUrl != null &&
        rawExtUrl.isNotEmpty;

    var directUrl = '';
    if (rawDirectUrl != null && rawDirectUrl.isNotEmpty) {
      directUrl = rawDirectUrl;
    } else if (infoHash != null) {
      final trackers = sources
          .where((s) => s.startsWith('tracker:'))
          .map((s) => s.substring('tracker:'.length))
          .where((s) => s.isNotEmpty)
          .take(12)
          .map((tr) => '&tr=${Uri.encodeComponent(tr)}')
          .join();
      directUrl = 'magnet:?xt=urn:btih:$infoHash$trackers';
    } else if (rawExtUrl != null && rawExtUrl.isNotEmpty) {
      directUrl = rawExtUrl;
    }

    final seedMatch =
        RegExp(r'(?:👤|🌱|S:)\s*(\d+)').firstMatch('$name $rawTitle');
    final explicitSeed = int.tryParse(json['seed']?.toString() ?? '');
    final seeders = explicitSeed ??
        (seedMatch != null
            ? int.tryParse(seedMatch.group(1)!) ?? 0
            : (infoHash != null ? 15 : 100));

    final explicitBytes = int.tryParse(json['sizebytes']?.toString() ?? '') ??
        int.tryParse(
          (json['behaviorHints'] is Map<String, dynamic>
                  ? (json['behaviorHints'] as Map<String, dynamic>)['videoSize']
                  : null)
              ?.toString() ??
              '',
        );
    var bytes = explicitBytes ?? 0;
    if (bytes <= 0) {
      final sizeMatch =
          RegExp(r'(\d+(?:\.\d+)?)\s*(GB|GO|MB|MO)', caseSensitive: false)
              .firstMatch(rawTitle);
      if (sizeMatch != null) {
        final numVal = double.tryParse(sizeMatch.group(1)!) ?? 0;
        final unit = sizeMatch.group(2)!.toUpperCase();
        bytes = (unit == 'GB' || unit == 'GO')
            ? (numVal * 1024 * 1024 * 1024).round()
            : (numVal * 1024 * 1024).round();
      }
    }

    final headers = <String, String>{};
    String? filename;
    if (json['behaviorHints'] is Map<String, dynamic>) {
      final hints = json['behaviorHints'] as Map<String, dynamic>;
      filename = hints['filename']?.toString();
      if (hints['proxyHeaders'] is Map<String, dynamic>) {
        final proxy = hints['proxyHeaders'] as Map<String, dynamic>;
        if (proxy['request'] is Map<String, dynamic>) {
          final req = proxy['request'] as Map<String, dynamic>;
          for (final entry in req.entries) {
            if (entry.value != null) {
              headers[entry.key] = entry.value.toString();
            }
          }
        }
      }
    }

    final subs = <SubtitleTrackItem>[];
    if (json['subtitles'] is List) {
      for (final s in json['subtitles'] as List) {
        if (s is Map<String, dynamic>) {
          subs.add(SubtitleTrackItem.fromJson(s));
        }
      }
    }

    final cleanTitle = rawTitle.trim().isEmpty
        ? '$name · $quality $hdr'
        : rawTitle.replaceAll('\n', ' · ').trim();

    return StreamSource(
      id: '${addonId}_${directUrl.hashCode}_${json['fileIdx'] ?? 0}',
      addonId: addonId,
      addonName: addonName,
      title: cleanTitle,
      quality: quality,
      hdrMode: hdr,
      url: directUrl,
      infoHash: infoHash,
      fileIdx: int.tryParse(json['fileIdx']?.toString() ?? ''),
      sources: sources,
      httpHeaders: headers,
      filename: filename,
      isExternal: isExt,
      sizeBytes: bytes,
      seeders: seeders,
      subtitles: subs,
    );
  }

  final String id;
  final String addonId;
  final String addonName;
  final String title;
  final String quality; // '4K' | '1080p' | '720p' | 'LIVE'
  final String hdrMode; // 'HDR' | 'SDR'
  final String url;
  final String? infoHash;
  final int? fileIdx;
  final List<String> sources;
  final Map<String, String> httpHeaders;
  final String? filename;
  final bool isExternal;
  final int sizeBytes;
  final int seeders;
  final int leechers;
  final List<SubtitleTrackItem> subtitles;

  bool get isTorrent =>
      (infoHash != null && infoHash!.isNotEmpty) || url.startsWith('magnet:?');

  /// Prioritizes direct HTTP/HLS streams and well-seeded 1080p/4K torrents
  /// with reasonable mobile file sizes so playback starts fast on mobile!
  int get qualityScore {
    if (isExternal) return 10;
    final directBonus = isTorrent ? 0 : 250;
    final resWeight = switch (quality) {
      '1080p' => 340,
      '4K' => 320,
      'LIVE' => 330,
      '720p' => 240,
      _ => 120,
    };
    final hdrWeight = hdrMode == 'HDR' ? 25 : 0;
    final seedWeight = seeders.clamp(0, 600) ~/ 3;
    // Penalize huge >18 GB remuxes on 32-bit mobile so fast 1-6 GB encodes rank first
    final hugePenalty = sizeBytes > 18 * 1024 * 1024 * 1024
        ? 180
        : sizeBytes > 10 * 1024 * 1024 * 1024
            ? 70
            : 0;
    return directBonus + resWeight + hdrWeight + seedWeight - hugePenalty;
  }

  String get deduplicationKey => infoHash != null && infoHash!.isNotEmpty
      ? 'btih:$infoHash:${fileIdx ?? 0}'
      : 'url:$url';
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
