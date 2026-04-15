/// Utilities for time formatting and parsing.
///
/// Provides helpers for working with times, days of week, and time ranges.
///
/// TODO: Implement time formatting, parsing, and validation
class TimeUtils {
  // Days of week (0 = Monday, 6 = Sunday)
  static const List<String> daysOfWeekEn = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> daysOfWeekTr = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  // No instances
  TimeUtils._();

  /// Formats a TimeOfDay to HH:mm format.
  /// TODO: Implement with proper formatting
  static String formatTime(int hour, int minute) {
    return '$hour:$minute';
  }

  /// Parses HH:mm format string to hour and minute.
  /// TODO: Implement parsing and validation
  static (int, int)? parseTime(String timeString) {
    return null;
  }

  /// Gets the day name for a given day index (0 = Monday).
  static String getDayName(int dayIndex, {bool turkish = false}) {
    if (dayIndex < 0 || dayIndex > 6) return '';
    return turkish ? daysOfWeekTr[dayIndex] : daysOfWeekEn[dayIndex];
  }
}
