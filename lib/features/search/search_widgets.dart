part of 'search_screen.dart';

class _SearchInputBar extends StatelessWidget {
  const _SearchInputBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(LucideIcons.search, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTypography.body,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child:
                    Icon(LucideIcons.x, color: AppColors.textMuted, size: 18),
              ),
            ),
          const SizedBox(width: 4),
          const Icon(LucideIcons.search, color: AppColors.red, size: 20),
        ],
      ),
    );
  }
}

class _Top10RankPoster extends StatelessWidget {
  const _Top10RankPoster({
    required this.rank,
    required this.item,
    required this.onTap,
  });

  final int rank;
  final MediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 126,
          height: 172,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 104,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.posterRadius),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: MuvioImage(
                    imageUrl: item.poster,
                    borderRadius: AppSpacing.posterRadius,
                    memCacheWidth: 320,
                  ),
                ),
              ),
              Positioned(
                left: -2,
                bottom: -6,
                child: Stack(
                  children: [
                    Text(
                      '$rank',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 84,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 2.8
                          ..color = AppColors.red,
                      ),
                    ),
                    Text(
                      '$rank',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 84,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        color: Color(0xCC0A0A0A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
