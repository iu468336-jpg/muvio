import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:muvio/core/theme/app_colors.dart';
import 'package:muvio/core/theme/app_spacing.dart';
import 'package:muvio/core/theme/app_typography.dart';
import 'package:muvio/data/models/media_models.dart';
import 'package:muvio/shared/widgets/muvio_image.dart';

/// 2:3 movie/series poster card with optional N badge, rating star badge,
/// or favorite heart overlay, wrapped in `RepaintBoundary`.
class PosterCard extends StatelessWidget {
  const PosterCard({
    required this.item,
    required this.onTap,
    super.key,
    this.width = 124,
    this.showNewBadge = false,
    this.showRatingBadge = false,
    this.showFavoriteHeart = false,
    this.onHeartTap,
  });

  final MediaItem item;
  final VoidCallback onTap;
  final double width;
  final bool showNewBadge;
  final bool showRatingBadge;
  final bool showFavoriteHeart;
  final VoidCallback? onHeartTap;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.5;

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: item.title,
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.posterRadius),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: MuvioImage(
                    imageUrl: item.poster,
                    width: width,
                    height: height,
                    borderRadius: AppSpacing.posterRadius,
                    memCacheWidth: 360,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.posterRadius),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.55, 1.0],
                        colors: [Colors.transparent, Color(0xCC000000)],
                      ),
                    ),
                  ),
                ),
                if (showNewBadge || item.isNewRelease)
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: _NewNBadge(),
                  ),
                if (showRatingBadge)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: AppTypography.micro.copyWith(
                              letterSpacing: 0.2,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (showFavoriteHeart)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onHeartTap,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.favorite,
                          color: AppColors.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewNBadge extends StatelessWidget {
  const _NewNBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'N',
        style: AppTypography.micro.copyWith(
          color: AppColors.red,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Section header with H1 title and optional red "Voir tout >" action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.h2.copyWith(fontSize: 19),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionLabel != null && onActionTap != null)
            Semantics(
              button: true,
              label: actionLabel,
              child: InkWell(
                onTap: onActionTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
