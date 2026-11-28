part of 'player_screen.dart';

class _GlassTransportRow extends StatelessWidget {
  const _GlassTransportRow({
    required this.isPlaying,
    required this.onRewind,
    required this.onPlayPause,
    required this.onForward,
  });

  final bool isPlaying;
  final VoidCallback onRewind;
  final VoidCallback onPlayPause;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GlassCircleButton(
          size: 56,
          icon: Icons.replay_10_rounded,
          onTap: onRewind,
        ),
        const SizedBox(width: 24),
        _GlassCircleButton(
          size: 76,
          icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          iconSize: 38,
          onTap: onPlayPause,
        ),
        const SizedBox(width: 24),
        _GlassCircleButton(
          size: 56,
          icon: Icons.forward_10_rounded,
          onTap: onForward,
        ),
      ],
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({
    required this.size,
    required this.icon,
    required this.onTap,
    this.iconSize = 26,
  });

  final double size;
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.62),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}

class _ControlPillButton extends StatelessWidget {
  const _ControlPillButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 38,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.red : AppColors.line,
          ),
        ),
        child: Icon(icon, size: 17, color: Colors.white),
      ),
    );
  }
}

class _QualityChip extends StatelessWidget {
  const _QualityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.redDeep.withValues(alpha: 0.35)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.red : AppColors.line,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected ? AppColors.red : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
