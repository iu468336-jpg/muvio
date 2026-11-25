/// Formatting utilities for durations, file sizes, and video resolutions.
class Formatters {
  const Formatters._();

  static String formatDurationClock(Duration d) {
    final totalSeconds = d.inSeconds < 0 ? 0 : d.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  static String formatRemainingShort(Duration remaining) {
    final totalMinutes = remaining.inMinutes < 1 ? 1 : remaining.inMinutes;
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins.toString().padLeft(2, '0')}m';
    }
    return '${mins}m';
  }

  static String formatBytesFr(int bytes) {
    if (bytes <= 0) return '0 Mo';
    const gb = 1024 * 1024 * 1024;
    const mb = 1024 * 1024;
    if (bytes >= gb) {
      final val = (bytes / gb).toStringAsFixed(1);
      return '$val Go';
    }
    final val = (bytes / mb).toStringAsFixed(0);
    return '$val Mo';
  }
}
