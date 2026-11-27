import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:muvio/core/theme/app_colors.dart';
import 'package:muvio/core/theme/app_spacing.dart';
import 'package:muvio/core/theme/app_typography.dart';
import 'package:muvio/core/utils/formatters.dart';
import 'package:muvio/data/models/media_models.dart';
import 'package:muvio/data/providers/app_providers.dart';
import 'package:muvio/l10n/app_localizations.dart';
import 'package:muvio/shared/widgets/muvio_image.dart';

/// Media Detail screen designed in Muvio's signature dark/red aesthetic:
/// Backdrop, poster, rating, year, runtime, synopsis, cast chips,
/// Watch / My List / Download actions, season/episodes selector, and live addon streams.
class MediaDetailScreen extends ConsumerStatefulWidget {
  const MediaDetailScreen({
    required this.mediaType,
    required this.mediaId,
    super.key,
  });

  final String mediaType;
  final String mediaId;

  @override
  ConsumerState<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends ConsumerState<MediaDetailScreen> {
  MediaItem? _media;
  List<StreamSource> _streams = const [];
  EpisodeVideo? _selectedEpisode;
  int _selectedSeason = 1;
  bool _loading = true;
  bool _loadingStreams = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final addons = await ref.read(addonsControllerProvider.future);
    final catalogRepo = ref.read(catalogRepositoryProvider);
    final decodedId = Uri.decodeComponent(widget.mediaId);
    final media = await catalogRepo.resolveMediaDetail(
      mediaId: decodedId,
      type: widget.mediaType,
      activeAddons: addons,
    );

    EpisodeVideo? firstEp;
    var season = 1;
    if (media.episodes.isNotEmpty) {
      final sorted = [...media.episodes]..sort((a, b) {
          final sCmp = a.season.compareTo(b.season);
          return sCmp != 0 ? sCmp : a.episode.compareTo(b.episode);
        });
      final regular = sorted.where((e) => e.season > 0).toList();
      firstEp = regular.isNotEmpty ? regular.first : sorted.first;
      season = firstEp.season;
    }

    final targetVideoId = firstEp != null
        ? (firstEp.id.isNotEmpty
            ? firstEp.id
            : '${media.id}:${firstEp.season}:${firstEp.episode}')
        : null;

    final streams = await catalogRepo.fetchStreamsForMedia(
      media: media,
      activeAddons: addons,
      episodeVideoId: targetVideoId,
    );
    if (!mounted) return;
    setState(() {
      _media = media;
      _selectedEpisode = firstEp;
      _selectedSeason = season;
      _streams = streams;
      _loading = false;
    });
  }

  Future<void> _selectEpisode(EpisodeVideo ep) async {
    final media = _media;
    if (media == null) return;
    setState(() {
      _selectedEpisode = ep;
      _loadingStreams = true;
    });
    final addons = await ref.read(addonsControllerProvider.future);
    final epId =
        ep.id.isNotEmpty ? ep.id : '${media.id}:${ep.season}:${ep.episode}';
    final streams =
        await ref.read(catalogRepositoryProvider).fetchStreamsForMedia(
              media: media,
              activeAddons: addons,
              episodeVideoId: epId,
            );
    if (!mounted) return;
    setState(() {
      _streams = streams;
      _loadingStreams = false;
    });
  }

  String _activePlayableId(MediaItem item) {
    final ep = _selectedEpisode;
    if (ep != null) {
      return ep.id.isNotEmpty
          ? ep.id
          : '${item.id}:${ep.season}:${ep.episode}';
    }
    return item.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading || _media == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.red),
        ),
      );
    }

    final item = _media!;
    final watchlist = ref.watch(watchlistControllerProvider).valueOrNull ??
        const <MediaItem>[];
    final inList = watchlist.any((e) => e.id == item.id);

    final seasons = {for (final e in item.episodes) e.season}.toList()..sort();
    final seasonEpisodes = item.episodes
        .where((e) => e.season == _selectedSeason)
        .toList()
      ..sort((a, b) => a.episode.compareTo(b.episode));

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.bg,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  MuvioImage(
                    imageUrl: item.backdrop ?? item.poster,
                    memCacheWidth: 1080,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x55000000),
                          AppColors.bg,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      MuvioImage(
                        imageUrl: item.poster,
                        width: 98,
                        height: 146,
                        borderRadius: AppSpacing.posterRadius,
                        memCacheWidth: 320,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: AppTypography.h1),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '★ ${item.rating.toStringAsFixed(1)}',
                                    style: AppTypography.micro,
                                  ),
                                ),
                                Text(
                                  '${item.year} · ${item.runtime}',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final g in item.genres.take(4))
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: AppColors.surface2,
                                    side: const BorderSide(
                                      color: AppColors.line,
                                    ),
                                    label: Text(
                                      g,
                                      style: AppTypography.caption,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            final pid =
                                Uri.encodeComponent(_activePlayableId(item));
                            context.push(
                              '/player/${item.type}/$pid',
                              extra:
                                  _streams.isNotEmpty ? _streams.first : null,
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(l10n.watchNow),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        style: IconButton.styleFrom(
                          minimumSize: const Size(46, 46),
                          side: const BorderSide(color: AppColors.line),
                        ),
                        onPressed: () => ref
                            .read(watchlistControllerProvider.notifier)
                            .toggle(item),
                        icon: Icon(
                          inList ? Icons.favorite : Icons.favorite_border,
                          color: inList ? AppColors.red : AppColors.text,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        style: IconButton.styleFrom(
                          minimumSize: const Size(46, 46),
                          side: const BorderSide(color: AppColors.line),
                        ),
                        onPressed: () {
                          if (_streams.isEmpty) return;
                          ref
                              .read(downloadsControllerProvider.notifier)
                              .enqueueDownload(
                                media: item,
                                stream: _streams.first,
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.downloadAction)),
                          );
                        },
                        icon: const Icon(LucideIcons.download),
                      ),
                    ],
                  ),
                  if (item.synopsis.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(item.synopsis, style: AppTypography.body),
                  ],
                  if (item.episodes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.episodesSection, style: AppTypography.h2),
                        if (seasons.length > 1)
                          DropdownButton<int>(
                            value: _selectedSeason,
                            dropdownColor: AppColors.surface2,
                            underline: const SizedBox.shrink(),
                            style: AppTypography.bodyMedium,
                            items: [
                              for (final s in seasons)
                                DropdownMenuItem(
                                  value: s,
                                  child: Text('Saison $s'),
                                ),
                            ],
                            onChanged: (next) {
                              if (next == null) return;
                              setState(() => _selectedSeason = next);
                              final firstInSeason = item.episodes
                                  .where((e) => e.season == next)
                                  .firstOrNull;
                              if (firstInSeason != null) {
                                _selectEpisode(firstInSeason);
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final ep in seasonEpisodes.take(30))
                      InkWell(
                        onTap: () => _selectEpisode(ep),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedEpisode?.id == ep.id
                                ? AppColors.surface2
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedEpisode?.id == ep.id
                                  ? AppColors.red
                                  : AppColors.line,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'S${ep.season} · E${ep.episode} — ${ep.title}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  final epId = Uri.encodeComponent(
                                    ep.id.isNotEmpty
                                        ? ep.id
                                        : '${item.id}:${ep.season}:${ep.episode}',
                                  );
                                  context.push('/player/${item.type}/$epId');
                                },
                                icon: const Icon(
                                  Icons.play_circle_fill,
                                  color: AppColors.red,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.availableStreams} (${_streams.length})',
                          style: AppTypography.h2,
                        ),
                      ),
                      if (_loadingStreams)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.red,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_streams.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Aucune source active. Installez Torrentio, Pipe, Peerflix ou Pluto TV dans Addons.',
                              style: AppTypography.caption,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => context.go('/addons'),
                            child: Text(l10n.navAddons),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final stream in _streams.take(40))
                      InkWell(
                        onTap: () {
                          final pid =
                              Uri.encodeComponent(_activePlayableId(item));
                          context.push(
                            '/player/${item.type}/$pid',
                            extra: stream,
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: stream.isTorrent
                                      ? AppColors.red
                                      : const Color(0xFF00A86B),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  stream.isTorrent
                                      ? LucideIcons.radio
                                      : LucideIcons.zap,
                                  color: Colors.white,
                                  size: 17,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${stream.addonName} · ${stream.quality} ${stream.hdrMode}',
                                      style: AppTypography.bodyMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      stream.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      stream.isTorrent
                                          ? 'P2P NuvioEngine · ${Formatters.formatBytesFr(stream.sizeBytes)} · 👤 ${stream.seeders} pairs'
                                          : '⚡ Lecture Directe Nuvio HTTP/HLS (0 attente P2P)',
                                      style: AppTypography.caption.copyWith(
                                        color: stream.isTorrent
                                            ? AppColors.redGlow
                                            : const Color(0xFF3CE39B),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.play_circle_fill_rounded,
                                color: AppColors.red,
                                size: 34,
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
