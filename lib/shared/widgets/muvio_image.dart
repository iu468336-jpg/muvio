import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:muvio/core/theme/app_colors.dart';

/// Memory-efficient cached network image enforcing `memCacheWidth`
/// so posters and backdrops never decode at oversized raw dimensions.
class MuvioImage extends StatelessWidget {
  const MuvioImage({
    required this.imageUrl,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.memCacheWidth = 420,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final int memCacheWidth;

  @override
  Widget build(BuildContext context) {
    final child = imageUrl.isEmpty
        ? _PlaceholderBox(width: width, height: height)
        : CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            memCacheWidth: memCacheWidth,
            fadeInDuration: const Duration(milliseconds: 140),
            placeholder: (_, __) =>
                _PlaceholderBox(width: width, height: height),
            errorWidget: (_, __, ___) =>
                _PlaceholderBox(width: width, height: height),
          );

    if (borderRadius <= 0) return child;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  const _PlaceholderBox({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface2, AppColors.surface],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.movie_creation_outlined,
          color: AppColors.line,
          size: 28,
        ),
      ),
    );
  }
}
