import 'package:flutter/foundation.dart';

/// Centralized Logger for application errors, crash reporting, and debug tracing.
class ErrorLogger {
  ErrorLogger._();

  /// Logs an error with optional stack trace and context tag.
  static void log(
    dynamic error, [
    StackTrace? stackTrace,
    String tag = 'APP_ERROR',
  ]) {
    if (kDebugMode) {
      debugPrint('════════════════════════════════════════════════════════════');
      debugPrint('🚨 [$tag] ${DateTime.now().toIso8601String()}');
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack Trace:\n$stackTrace');
      }
      debugPrint('════════════════════════════════════════════════════════════');
    }
  }

  /// Logs informational events or non-fatal warnings.
  static void info(String message, [String tag = 'APP_INFO']) {
    if (kDebugMode) {
      debugPrint('ℹ️ [$tag] $message');
    }
  }
}
