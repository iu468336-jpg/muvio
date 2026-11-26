import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:muvio/core/theme/app_colors.dart';
import 'package:muvio/core/theme/app_spacing.dart';
import 'package:muvio/core/theme/app_typography.dart';
import 'package:muvio/data/models/addon_models.dart';
import 'package:muvio/data/models/media_models.dart';
import 'package:muvio/data/models/seed_catalog.dart';
import 'package:muvio/data/providers/app_providers.dart';
import 'package:muvio/l10n/app_localizations.dart';
import 'package:muvio/shared/widgets/muvio_image.dart';
import 'package:muvio/shared/widgets/poster_card.dart';
import 'package:muvio/shared/widgets/skeleton_and_empty.dart';

part 'search_widgets.dart';

/// Screen 4 — Recherche & Découverte:
/// Centered MUVIO logo, rounded search bar with red search icon (350ms debounce),
/// horizontal genre chips (Tout active red, Action, Drame, Sci-Fi, Animation, Comédie),
/// "Top 10 aujourd'hui" with giant red outline rank numbers (1, 2, 3...),
/// 3-column poster grid with ★ 8.6 red badges, grouped results & clean empty state.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _query = '';
  String _selectedGenre = 'Tout';
  bool _searching = false;
  List<MediaItem> _results = SeedCatalogData.catalogItems;

  @override
  void initState() {
    super.initState();
    _runSearch();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppDurations.searchDebounce, () {
      if (!mounted) return;
      setState(() => _query = value);
      _runSearch();
    });
  }

  Future<void> _runSearch() async {
    setState(() => _searching = true);
    final addons = ref.read(addonsControllerProvider).valueOrNull ??
        const <InstalledAddon>[];
    final items = await ref.read(catalogRepositoryProvider).searchAcrossAddons(
          query: _query,
          activeAddons: addons,
          genreFilter: _selectedGenre,
        );
    if (!mounted) return;
    setState(() {
      _results = items;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final genres = [
      l10n.genreAll,
      l10n.genreAction,
      l10n.genreDrama,
      l10n.genreSciFi,
      l10n.genreAnimation,
      l10n.genreComedy,
    ];
    final top10 =
        (_results.isNotEmpty ? _results : SeedCatalogData.catalogItems)
            .take(10)
            .toList();
    final isFiltering = _query.trim().isNotEmpty;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding:
                  EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
              child: Center(
                child: Text('MUVIO', style: AppTypography.logo),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: _SearchInputBar(
                controller: _searchController,
                hint: l10n.searchHint,
                onChanged: _onQueryChanged,
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                  _runSearch();
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: genres.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  final active = _selectedGenre == genre ||
                      (index == 0 && _selectedGenre == 'Tout');
                  return GestureDetector(
                    onTap: () {
                      setState(
                        () => _selectedGenre = index == 0 ? 'Tout' : genre,
                      );
                      _runSearch();
                    },
                    child: AnimatedContainer(
                      duration: AppDurations.fast,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? AppColors.red : AppColors.bg,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.chipRadius),
                        border: Border.all(
                          color: active
                              ? AppColors.red
                              : AppColors.red.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Text(
                        genre,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (!isFiltering) ...[
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Text(l10n.top10Today, style: AppTypography.h1),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 174,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: top10.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final item = top10[index];
                    return _Top10RankPoster(
                      rank: index + 1,
                      item: item,
                      onTap: () =>
                          context.push('/detail/${item.type}/${item.id}'),
                    );
                  },
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          if (_searching)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.red),
                ),
              ),
            )
          else if (_results.isEmpty)
            SliverToBoxAdapter(
              child: EmptyStateCard(
                icon: LucideIcons.searchX,
                title: l10n.noResultsTitle,
                subtitle: l10n.noResultsSubtitle,
              ),
            )
          else ...[
            if (isFiltering)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    0,
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                  ),
                  child: Text(
                    '${l10n.moviesGroup} (${_results.where((e) => e.type == 'movie').length}) · '
                    '${l10n.seriesGroup} (${_results.where((e) => e.type == 'series').length})',
                    style: AppTypography.caption,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                110,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSpacing.gridGap,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.66,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _results[index];
                    return PosterCard(
                      item: item,
                      showRatingBadge: true,
                      onTap: () =>
                          context.push('/detail/${item.type}/${item.id}'),
                    );
                  },
                  childCount: _results.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
