/// Time keeper for clock management without RTC.
///
/// Provides current time based on ESP32 millis() counter.
/// Supports time synchronization from the mobile app via BLE.
/// Since there's no RTC, the device must sync time from the app periodically.

#pragma once

#include <Arduino.h>
#include <time.h>

/// Tracks current time using system milliseconds and epoch offset.
/// TODO: Implement all methods - currently just function signatures
class TimeKeeper {
public:
  /// Initialize time tracking system.
  /// Must call setup() before using time functions.
  void setup();

  /// Synchronizes device time from Unix timestamp (seconds since epoch).
  /// Called when app sends time sync information.
  /// TODO: Implement
  void syncTime(time_t unixTimestamp);

  /// Gets current Unix timestamp.
  /// TODO: Implement
  time_t getUnixTimestamp() const;

  /// Gets current time as struct tm (year, month, day, hour, minute, second).
  /// TODO: Implement
  struct tm getCurrentTime() const;

  /// Gets current hour (0-23).
  /// TODO: Implement
  uint8_t getCurrentHour() const;

  /// Gets current minute (0-59).
  /// TODO: Implement
  uint8_t getCurrentMinute() const;

  /// Gets current day of week (0 = Monday, 6 = Sunday).
  /// TODO: Implement
  uint8_t getDayOfWeek() const;

  /// Gets time as minutes since midnight.
  /// TODO: Implement
  uint16_t getMinutesSinceMidnight() const;

  /// Checks if time has been synchronized (not just boot time).
  /// TODO: Implement
  bool isTimeSynchronized() const;

private:
  // Unix timestamp offset at last sync
  time_t lastSyncTimestamp = 0;

  // System milliseconds at last sync
  unsigned long lastSyncMillis = 0;

  // Flag indicating if time has been synced
  bool synchronized = false;

  /// Calculates time elapsed since last sync and returns adjusted timestamp.
  /// TODO: Implement
  time_t calculateCurrentTimestamp() const;
};
