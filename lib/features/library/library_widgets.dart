part of 'library_screen.dart';

class _LibraryTabs extends StatelessWidget {
  const _LibraryTabs({
    required this.activeIndex,
    required this.labels,
    required this.onSelect,
  });

  final int activeIndex;
  final List<String> labels;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        child: Row(
          children: List.generate(labels.length, (idx) {
            final selected = idx == activeIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 24),
              child: InkWell(
                onTap: () => onSelect(idx),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected ? AppColors.red : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[idx],
                    style: AppTypography.bodyMedium.copyWith(
                      color: selected ? AppColors.red : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _DownloadRowCard extends StatelessWidget {
  const _DownloadRowCard({
    required this.task,
    required this.onTogglePause,
    required this.onLongPressDelete,
    required this.onOpenPlayer,
  });

  final DownloadTaskItem task;
  final VoidCallback onTogglePause;
  final VoidCallback onLongPressDelete;
  final VoidCallback onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == DownloadStatus.completed;
    final isPaused = task.status == DownloadStatus.paused;

    return RepaintBoundary(
      child: InkWell(
        onTap: onOpenPlayer,
        onLongPress: onLongPressDelete,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              MuvioImage(
                imageUrl: task.thumbnail,
                width: 104,
                height: 64,
                borderRadius: 10,
                memCacheWidth: 280,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      Formatters.formatBytesFr(task.totalBytes),
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.red),
                      ),
                      child: Text(
                        task.quality,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.red,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isDone)
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.black,
                    size: 18,
                  ),
                )
              else ...[
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: task.progress,
                        strokeWidth: 3,
                        backgroundColor: AppColors.line,
                        valueColor: const AlwaysStoppedAnimation(AppColors.red),
                      ),
                      Text(
                        '${task.progressPercent}%',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: onTogglePause,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54),
                    ),
                    child: Icon(
                      isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageUsageBar extends StatelessWidget {
  const _StorageUsageBar({
    required this.label,
    required this.fraction,
    required this.onTap,
  });

  final String label;
  final double fraction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                LucideIcons.hardDrive,
                color: AppColors.red,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      backgroundColor: AppColors.line,
                      valueColor: const AlwaysStoppedAnimation(AppColors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              LucideIcons.chevronRight,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
