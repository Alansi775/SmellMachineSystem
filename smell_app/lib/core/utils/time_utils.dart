import 'package:intl/intl.dart';

/// Utilities for time formatting and parsing.
///
/// Provides helpers for working with times, days of week, and time ranges.
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

  /// Returns the current time in HH:mm format.
  static String currentTimeLabel([DateTime? dateTime]) {
    final now = dateTime ?? DateTime.now();
    return DateFormat('HH:mm').format(now);
  }

  /// Returns the current date in yyyy-MM-dd format.
  static String currentDateLabel([DateTime? dateTime]) {
    final now = dateTime ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  /// Returns the current day name in English or Turkish.
  static String currentDayName([DateTime? dateTime, bool turkish = false]) {
    final now = dateTime ?? DateTime.now();
    final dayIndex = now.weekday - 1;
    return getDayName(dayIndex, turkish: turkish);
  }

  /// Builds metadata describing the current local time and day.
  static Map<String, dynamic> buildCurrentMetadata([DateTime? dateTime]) {
    final now = dateTime ?? DateTime.now();
    return {
      'currentTime': currentTimeLabel(now),
      'currentDate': currentDateLabel(now),
      'currentDayName': currentDayName(now),
      'currentDayIndex': now.weekday - 1,
    };
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
