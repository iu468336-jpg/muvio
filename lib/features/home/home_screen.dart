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
/// Header MUVIO + Avatar, Hero Carousel, Continuer à regarder (real watch history only),
/// and Stremio/Nuvio-style dynamic horizontal catalog rows for EVERY installed & enabled
/// catalog addon (Cinemeta, TMDB, Streaming Catalogs, Anime Kitsu, Pluto TV, custom URLs).
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

  void _openItemDetail(BuildContext context, MediaItem item) {
    final encodedId = Uri.encodeComponent(item.id);
    context.push('/detail/${item.type}/$encodedId');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sectionsAsync = ref.watch(homeSectionsProvider);
    final history = ref.watch(watchHistoryControllerProvider).valueOrNull ??
        const <WatchProgressItem>[];
    final watchlistAsync = ref.watch(watchlistControllerProvider);
    final watchlistIds = {
      for (final m in watchlistAsync.valueOrNull ?? const <MediaItem>[]) m.id,
    };

    final allItems = <MediaItem>[
      for (final sec in sectionsAsync.valueOrNull ?? const <HomeCatalogSection>[])
        ...sec.items,
    ];
    final heroCandidates = allItems
        .where((m) => (m.backdrop ?? '').isNotEmpty && m.poster.isNotEmpty)
        .take(5)
        .toList();
    final effectiveHeroes =
        heroCandidates.isNotEmpty ? heroCandidates : SeedCatalogData.heroItems;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.red,
        backgroundColor: AppColors.surface2,
        onRefresh: () async {
          ref
            ..invalidate(homeSectionsProvider)
            ..invalidate(homeCatalogProvider);
          await ref.read(homeSectionsProvider.future);
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
                  currentIndex: _heroPage.clamp(0, effectiveHeroes.length - 1),
                  items: effectiveHeroes,
                  watchlistIds: watchlistIds,
                  onPageChanged: (idx) => setState(() => _heroPage = idx),
                  onWatch: (item) => _openItemDetail(context, item),
                  onToggleList: (item) => ref
                      .read(watchlistControllerProvider.notifier)
                      .toggle(item),
                ),
              ),
            ),
            if (history.isNotEmpty) ...[
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
                  height: 196,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: history.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final entry = history[index];
                      final encodedId = Uri.encodeComponent(entry.media.id);
                      return _ContinueWatchingCard(
                        entry: entry,
                        onTap: () => context.push(
                          '/player/${entry.media.type}/$encodedId',
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            ...sectionsAsync.when(
              data: (sections) => [
                for (final section in sections) ...[
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sectionGap),
                  ),
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: section.displayTitle,
                      actionLabel: l10n.seeAll,
                      onActionTap: () => context.go('/search'),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 168,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: section.items.take(25).length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = section.items[index];
                          return PosterCard(
                            item: item,
                            width: 112,
                            showNewBadge: item.isNewRelease,
                            onTap: () => _openItemDetail(context, item),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
              loading: () => const [
                SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.sectionGap),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 168,
                    child: _HorizontalSkeletonList(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.sectionGap),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 168,
                    child: _HorizontalSkeletonList(),
                  ),
                ),
              ],
              error: (_, __) => const [],
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 92)),
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
        AppSpacing.xs,
        AppSpacing.screenPadding,
        AppSpacing.sm,
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
                width: 34,
                height: 34,
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
                  size: 17,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
