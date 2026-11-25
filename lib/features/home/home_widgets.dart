part of 'home_screen.dart';

class _HeroCarousel extends StatelessWidget {
  const _HeroCarousel({
    required this.controller,
    required this.currentIndex,
    required this.items,
    required this.watchlistIds,
    required this.onPageChanged,
    required this.onWatch,
    required this.onToggleList,
  });

  final PageController controller;
  final int currentIndex;
  final List<MediaItem> items;
  final Set<String> watchlistIds;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<MediaItem> onWatch;
  final ValueChanged<MediaItem> onToggleList;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AspectRatio(
      aspectRatio: 1.18,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.line),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: controller,
                itemCount: items.length,
                onPageChanged: onPageChanged,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final inList = watchlistIds.contains(item.id);

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      MuvioImage(
                        imageUrl: item.backdrop ?? item.poster,
                        memCacheWidth: 960,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.1, 0.55, 1.0],
                            colors: [
                              Color(0x33000000),
                              Color(0x990A0A0A),
                              Color(0xF20A0A0A),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'UN FILM ORIGINAL ',
                                  style: AppTypography.micro.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  'MUVIO',
                                  style: AppTypography.micro.copyWith(
                                    color: AppColors.red,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.title.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.display.copyWith(
                                letterSpacing: 4,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.synopsis,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body.copyWith(
                                color: AppColors.text.withValues(alpha: 0.88),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Flexible(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.red,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 44),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => onWatch(item),
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 22,
                                    ),
                                    label: Text(
                                      l10n.watchNow,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodyMedium,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.text,
                                      backgroundColor:
                                          Colors.black.withValues(alpha: 0.45),
                                      side: const BorderSide(
                                        color: AppColors.line,
                                      ),
                                      minimumSize: const Size(0, 44),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => onToggleList(item),
                                    icon: Icon(
                                      inList ? Icons.check : Icons.add,
                                      size: 18,
                                    ),
                                    label: Text(
                                      inList ? l10n.inMyList : l10n.myList,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodyMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(items.length, (idx) {
                    final selected = idx == currentIndex;
                    return AnimatedContainer(
                      duration: AppDurations.fast,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: selected ? 9 : 7,
                      height: selected ? 9 : 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? AppColors.red
                            : Colors.white.withValues(alpha: 0.45),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  const _ContinueWatchingCard({
    required this.entry,
    required this.onTap,
  });

  final WatchProgressItem entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 132,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.posterRadius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MuvioImage(
                        imageUrl: entry.media.poster,
                        memCacheWidth: 360,
                      ),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.progressFraction.clamp(0.08, 1.0),
                            minHeight: 4,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                            valueColor:
                                const AlwaysStoppedAnimation(AppColors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.media.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                entry.episodeBadge ?? 'Reprendre',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizontalSkeletonList extends StatelessWidget {
  const _HorizontalSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
      itemBuilder: (_, __) => const SkeletonBox(width: 124, height: 186),
    );
  }
}
