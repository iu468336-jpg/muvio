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
import 'package:muvio/shared/widgets/poster_card.dart';
import 'package:muvio/shared/widgets/skeleton_and_empty.dart';

part 'library_widgets.dart';

/// Screen 5 — Bibliothèque & Téléchargements:
/// Header logo + "open source" + search + avatar, "Ma bibliothèque",
/// Tabs: Ma liste (active red) | Téléchargements | Historique,
/// Posters with red heart, Downloads with thumbnail + 1.8 Go + 1080p tag +
/// 65% red progress ring + pause/resume + green check when done,
/// "Tout mettre en pause", and Storage usage bar (12,4 Go utilisés sur 32 Go).
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _activeTab =
      0; // 0: Ma liste (combined overview), 1: Téléchargements, 2: Historique

  Future<void> _confirmDeleteDownload(DownloadTaskItem task) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.delete, style: AppTypography.h2),
        content: Text(
          'Supprimer le téléchargement « ${task.title} » ?',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref
          .read(downloadsControllerProvider.notifier)
          .removeDownload(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final watchlistAsync = ref.watch(watchlistControllerProvider);
    final downloadsAsync = ref.watch(downloadsControllerProvider);
    final historyAsync = ref.watch(watchHistoryControllerProvider);

    final downloads = downloadsAsync.valueOrNull ?? const <DownloadTaskItem>[];
    final usedBytes = downloads.fold<int>(
      0,
      (sum, d) => sum + d.downloadedBytes,
    );
    final usedGb = (usedBytes / (1024 * 1024 * 1024))
        .toStringAsFixed(2)
        .replaceAll('.', ',');

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'muvio',
                      style: AppTypography.h2.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l10n.openSourceSubtitle,
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => context.go('/search'),
                  icon: const Icon(LucideIcons.search, size: 21),
                ),
                GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line),
                      color: AppColors.surface2,
                    ),
                    child: const Icon(LucideIcons.user, size: 17),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Text(l10n.libraryTitle, style: AppTypography.display),
          ),
          const SizedBox(height: AppSpacing.sm),
          _LibraryTabs(
            activeIndex: _activeTab,
            labels: [l10n.myList, l10n.downloadsTab, l10n.historyTab],
            onSelect: (idx) => setState(() => _activeTab = idx),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 110),
              children: [
                if (_activeTab == 0 || _activeTab == 1) ...[
                  if (_activeTab == 0) ...[
                    SectionHeader(
                      title: l10n.myList,
                      actionLabel: l10n.seeAll,
                      onActionTap: () => setState(() => _activeTab = 0),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 178,
                      child: watchlistAsync.when(
                        data: (items) {
                          if (items.isEmpty) {
                            return EmptyStateCard(
                              icon: LucideIcons.heart,
                              title: l10n.emptyListTitle,
                              subtitle: l10n.emptyListSubtitle,
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenPadding,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return PosterCard(
                                item: item,
                                width: 118,
                                showFavoriteHeart: true,
                                onHeartTap: () => ref
                                    .read(watchlistControllerProvider.notifier)
                                    .toggle(item),
                                onTap: () => context
                                    .push('/detail/${item.type}/${item.id}'),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child:
                              CircularProgressIndicator(color: AppColors.red),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.downloadsTab,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => ref
                              .read(downloadsControllerProvider.notifier)
                              .pauseAll(),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.pauseAll,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  LucideIcons.pauseCircle,
                                  color: AppColors.red,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (downloads.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: EmptyStateCard(
                        icon: LucideIcons.download,
                        title: l10n.downloadsTab,
                        subtitle:
                            'Aucun téléchargement en cours. Lancez un téléchargement depuis la fiche d’un film ou d’une série.',
                      ),
                    )
                  else
                    for (final task in downloads)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          0,
                          AppSpacing.screenPadding,
                          AppSpacing.md,
                        ),
                        child: _DownloadRowCard(
                          task: task,
                          onTogglePause: () => ref
                              .read(downloadsControllerProvider.notifier)
                              .togglePause(task),
                          onLongPressDelete: () => _confirmDeleteDownload(task),
                          onOpenPlayer: () =>
                              context.push('/player/movie/${task.mediaId}'),
                        ),
                      ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: _StorageUsageBar(
                      label: l10n.storageUsed(usedGb, '32'),
                      fraction: (usedBytes / (32 * 1024 * 1024 * 1024))
                          .clamp(0.05, 1.0),
                      onTap: () => context.go('/profile'),
                    ),
                  ),
                ] else ...[
                  historyAsync.when(
                    data: (history) {
                      if (history.isEmpty) {
                        return EmptyStateCard(
                          icon: LucideIcons.history,
                          title: l10n.emptyHistoryTitle,
                          subtitle: l10n.emptyHistorySubtitle,
                        );
                      }
                      return Column(
                        children: [
                          for (final h in history)
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenPadding,
                                vertical: 6,
                              ),
                              leading: MuvioImage(
                                imageUrl: h.media.poster,
                                width: 52,
                                height: 76,
                                borderRadius: 8,
                                memCacheWidth: 180,
                              ),
                              title: Text(
                                h.media.title,
                                style: AppTypography.bodyMedium,
                              ),
                              subtitle: Text(
                                '${Formatters.formatDurationClock(Duration(seconds: h.positionSeconds))} / '
                                '${Formatters.formatDurationClock(Duration(seconds: h.durationSeconds))}',
                                style: AppTypography.caption,
                              ),
                              trailing: const Icon(
                                Icons.play_circle_fill_rounded,
                                color: AppColors.red,
                                size: 32,
                              ),
                              onTap: () => context.push(
                                '/player/${h.media.type}/${h.media.id}',
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.red),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
