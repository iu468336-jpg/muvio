import 'package:flutter/foundation.dart';

/// Debug-only logger ensuring zero `print()` statements in release builds.
class AppLogger {
  const AppLogger._();

  static void info(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  static void warn(String tag, String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[$tag][WARN] $message ${error ?? ''}');
    }
  }

  static void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (kDebugMode) {
      debugPrint('[$tag][ERROR] $message ${error ?? ''}');
      if (stackTrace != null) {
        debugPrintStack(stackTrace: stackTrace, maxFrames: 6);
      }
    }
  }
}
