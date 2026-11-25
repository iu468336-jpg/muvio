import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:muvio/core/theme/app_colors.dart';
import 'package:muvio/core/theme/app_spacing.dart';
import 'package:muvio/core/theme/app_typography.dart';
import 'package:muvio/core/utils/formatters.dart';
import 'package:muvio/data/models/addon_models.dart';
import 'package:muvio/data/models/media_models.dart';
import 'package:muvio/data/providers/app_providers.dart';
import 'package:muvio/l10n/app_localizations.dart';
import 'package:muvio/shared/widgets/muvio_image.dart';

/// Media Detail screen designed in Muvio's signature dark/red aesthetic:
/// Backdrop, poster, rating, year, runtime, synopsis, cast chips,
/// Watch / My List / Download actions, episodes list (if series), and live addon streams.
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final addons = ref.read(addonsControllerProvider).valueOrNull ??
        const <InstalledAddon>[];
    final catalogRepo = ref.read(catalogRepositoryProvider);
    final media = await catalogRepo.resolveMediaDetail(
      mediaId: widget.mediaId,
      type: widget.mediaType,
      activeAddons: addons,
    );
    final streams = await catalogRepo.fetchStreamsForMedia(
      media: media,
      activeAddons: addons,
    );
    if (!mounted) return;
    setState(() {
      _media = media;
      _streams = streams;
      _loading = false;
    });
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

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
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
                          Color(0x990A0A0A),
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
                        width: 104,
                        height: 154,
                        borderRadius: AppSpacing.posterRadius,
                        memCacheWidth: 320,
                      ),
                      const SizedBox(width: AppSpacing.lg),
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
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '★ ${item.rating.toStringAsFixed(1)}',
                                    style: AppTypography.micro.copyWith(
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${item.year} · ${item.runtime}',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final g in item.genres)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface2,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: AppColors.line),
                                    ),
                                    child:
                                        Text(g, style: AppTypography.caption),
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
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () =>
                              context.push('/player/${item.type}/${item.id}'),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(l10n.watchNow),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.outlined(
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
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
                          minimumSize: const Size(48, 48),
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
                            SnackBar(
                              content: Text(
                                '${l10n.downloadAction}: ${item.title}',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.download),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(item.synopsis, style: AppTypography.body),
                  if (item.cast.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(l10n.castSection, style: AppTypography.h2),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final actor in item.cast)
                          Chip(
                            backgroundColor: AppColors.surface,
                            side: const BorderSide(color: AppColors.line),
                            label: Text(actor, style: AppTypography.caption),
                          ),
                      ],
                    ),
                  ],
                  if (item.episodes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(l10n.episodesSection, style: AppTypography.h2),
                    const SizedBox(height: AppSpacing.sm),
                    for (final ep in item.episodes)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'S${ep.season} · E${ep.episode} — ${ep.title}',
                                    style: AppTypography.bodyMedium,
                                  ),
                                  if (ep.overview.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      ep.overview,
                                      style: AppTypography.caption,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => context
                                  .push('/player/${item.type}/${item.id}'),
                              icon: const Icon(
                                Icons.play_circle_fill,
                                color: AppColors.red,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Text(l10n.availableStreams, style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.sm),
                  for (final stream in _streams)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.radio,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                  '${Formatters.formatBytesFr(stream.sizeBytes)} · '
                                  '👤 ${stream.seeders} seeders · Score ${stream.qualityScore}',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.push(
                              '/player/${item.type}/${item.id}',
                              extra: stream,
                            ),
                            icon: const Icon(
                              Icons.play_circle_fill_rounded,
                              color: AppColors.red,
                              size: 36,
                            ),
                          ),
                        ],
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
