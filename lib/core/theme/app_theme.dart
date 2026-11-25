import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muvio/core/theme/app_colors.dart';
import 'package:muvio/core/theme/app_spacing.dart';
import 'package:muvio/core/theme/app_typography.dart';

/// Builds the Muvio Material 3 dark theme with zero runtime font fetching.
class AppTheme {
  const AppTheme._();

  static void configureFonts() {
    GoogleFonts.config.allowRuntimeFetching = false;
  }

  static ThemeData build({bool pureAmoled = false}) {
    final background = pureAmoled ? Colors.black : AppColors.bg;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.red,
        onPrimary: AppColors.text,
        secondary: AppColors.redGlow,
        onSecondary: AppColors.text,
        surface: AppColors.surface,
        error: AppColors.redGlow,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTypography.h1,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.red;
          }
          return AppColors.line;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface2,
        contentTextStyle: AppTypography.body,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.posterRadius),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: AppTypography.display,
        headlineMedium: AppTypography.h1,
        titleMedium: AppTypography.h2,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.caption,
        labelSmall: AppTypography.micro,
      ),
    );
  }
}
