/// Spacing, border radii, and layout constants across Muvio.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double screenPadding = 20;
  static const double xl = 24;
  static const double sectionGap = 28;
  static const double xxl = 36;

  static const double gridGap = 16;
  static const double cardRadius = 20;
  static const double posterRadius = 12;
  static const double pillRadius = 999;
  static const double chipRadius = 999;

  static const double bottomNavHeight = 64;
  static const double minTouchTarget = 44;
}

/// Standard animation durations (capped at 200 ms per performance spec).
class AppDurations {
  const AppDurations._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 180);
  static const Duration maxAnim = Duration(milliseconds: 200);
  static const Duration searchDebounce = Duration(milliseconds: 350);
  static const Duration controlsAutoHide = Duration(seconds: 3);
  static const Duration catalogCacheTtl = Duration(minutes: 5);
}
