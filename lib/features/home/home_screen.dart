import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:muvio/core/theme/app_colors.dart';
import 'package:muvio/core/theme/app_spacing.dart';
import 'package:muvio/core/theme/app_typography.dart';
import 'package:muvio/data/models/media_models.dart';
import 'package:muvio/data/models/seed_catalog.dart';
import 'package:muvio/data/providers/app_providers.dart';
import 'package:muvio/l10n/app_localizations.dart';
import 'package:muvio/shared/widgets/muvio_image.dart';
import 'package:muvio/shared/widgets/poster_card.dart';
import 'package:muvio/shared/widgets/skeleton_and_empty.dart';

part 'home_widgets.dart';

/// Screen 1 — Accueil (Portrait):
/// Header MUVIO + Avatar, Hero Carousel 16:9 ("ÉCLIPSE"),
/// Continuer à regarder (2:3 + progress bar + S1·E5), Tendances, Nouveautés ("N" badge),
/// Pull-to-refresh & skeleton shimmer.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _heroController = PageController();
  int _heroPage = 0;

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalogAsync = ref.watch(homeCatalogProvider);
    final historyAsync = ref.watch(watchHistoryControllerProvider);
    final watchlistAsync = ref.watch(watchlistControllerProvider);
    final watchlistIds = {
      for (final m in watchlistAsync.valueOrNull ?? const <MediaItem>[]) m.id,
    };

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.red,
        backgroundColor: AppColors.surface2,
        onRefresh: () async {
          ref.invalidate(homeCatalogProvider);
          await ref.read(homeCatalogProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHeader(
                onAvatarTap: () => context.go('/profile'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: _HeroCarousel(
                  controller: _heroController,
                  currentIndex: _heroPage,
                  items: SeedCatalogData.heroItems,
                  watchlistIds: watchlistIds,
                  onPageChanged: (idx) => setState(() => _heroPage = idx),
                  onWatch: (item) =>
                      context.push('/player/${item.type}/${item.id}'),
                  onToggleList: (item) => ref
                      .read(watchlistControllerProvider.notifier)
                      .toggle(item),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.sectionGap),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: l10n.continueWatching,
                actionLabel: l10n.seeAll,
                onActionTap: () => context.go('/library'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 222,
                child: historyAsync.when(
                  data: (history) => ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: history.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final entry = history[index];
                      return _ContinueWatchingCard(
                        entry: entry,
                        onTap: () => context.push(
                          '/player/${entry.media.type}/${entry.media.id}',
                        ),
                      );
                    },
                  ),
                  loading: () => const _HorizontalSkeletonList(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.sectionGap),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: l10n.trending,
                actionLabel: l10n.seeAll,
                onActionTap: () => context.go('/search'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 186,
                child: catalogAsync.when(
                  data: (items) {
                    final trending = items.take(10).toList();
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: trending.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final item = trending[index];
                        return PosterCard(
                          item: item,
                          onTap: () =>
                              context.push('/detail/${item.type}/${item.id}'),
                        );
                      },
                    );
                  },
                  loading: () => const _HorizontalSkeletonList(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.sectionGap),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: l10n.newReleases,
                actionLabel: l10n.seeAll,
                onActionTap: () => context.go('/search'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 186,
                child: catalogAsync.when(
                  data: (items) {
                    final releases =
                        items.where((e) => e.isNewRelease).toList();
                    final list = releases.isNotEmpty
                        ? releases
                        : items.reversed.take(8).toList();
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return PosterCard(
                          item: item,
                          showNewBadge: true,
                          onTap: () =>
                              context.push('/detail/${item.type}/${item.id}'),
                        );
                      },
                    );
                  },
                  loading: () => const _HorizontalSkeletonList(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onAvatarTap});

  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('MUVIO', style: AppTypography.logo),
          Semantics(
            button: true,
            label: 'Profil utilisateur',
            child: GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line, width: 1.5),
                  gradient: const LinearGradient(
                    colors: [AppColors.surface2, AppColors.redDeep],
                  ),
                ),
                child: const Icon(
                  LucideIcons.user,
                  color: AppColors.text,
                  size: 19,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
