import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform-channel bridge for persistent Android/Dart crash & playback diagnostics.
class DiagnosticsBridge {
  const DiagnosticsBridge._();

  static const MethodChannel _channel =
      MethodChannel('app.muvio.mobile/diagnostics');

  static void installGlobalErrorHandlers() {
    final prevFlutterOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      prevFlutterOnError?.call(details);
      recordError(
        source: 'FlutterError',
        trace: '${details.exceptionAsString()}\n${details.stack ?? ''}',
      );
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordError(
        source: 'PlatformDispatcher',
        trace: '$error\n$stack',
      );
      return true;
    };
  }

  static Future<void> recordError({
    required String source,
    required String trace,
  }) async {
    try {
      await _channel.invokeMethod<void>(
        'recordCrash',
        <String, dynamic>{
          'source': source,
          'trace': trace,
        },
      );
    } catch (_) {}
  }

  static Future<String> readCrashLog() async {
    try {
      return await _channel.invokeMethod<String>('readCrashLog') ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<void> clearCrashLog() async {
    try {
      await _channel.invokeMethod<void>('clearCrashLog');
    } catch (_) {}
  }
}
