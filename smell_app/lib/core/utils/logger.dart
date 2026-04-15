/// Simple logging utility for debugging and monitoring.
///
/// In production, this would integrate with a logging service.
/// For now, it provides a consistent interface for print-style logging.
///
/// TODO: Integrate with production logging service
class Logger {
  static const String _prefix = '[SmellDevice]';

  // No instances
  Logger._();

  /// Log debug message
  static void debug(String message) {
    print('$_prefix DEBUG: $message');
  }

  /// Log info message
  static void info(String message) {
    print('$_prefix INFO: $message');
  }

  /// Log warning message
  static void warning(String message) {
    print('$_prefix WARNING: $message');
  }

  /// Log error message
  static void error(String message, [StackTrace? stackTrace]) {
    print('$_prefix ERROR: $message');
    if (stackTrace != null) {
      print(stackTrace);
    }
  }
}
