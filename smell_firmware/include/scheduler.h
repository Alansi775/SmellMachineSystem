/// Scheduler for automatic fragrance dispensing.
///
/// Compares current weekday/time against stored schedules.
/// When a schedule matches, triggers the corresponding sprayer pin.
///
/// Requires TimeKeeper to provide current time.

#pragma once

#include <Arduino.h>
#include <string>
#include <vector>

/// Schedule entry loaded from device config.
struct ScheduleEntry {
  std::string id;
  std::string smellId;
  uint8_t dayOfWeek;    // 0 = Monday, 6 = Sunday
  uint16_t startTime;   // Minutes since midnight (0-1440)
  uint16_t endTime;     // Minutes since midnight
};

/// Manages schedule checking and sprayer triggering.
/// TODO: Implement all methods - currently just function signatures
class Scheduler {
public:
  /// Initialize scheduler with the latest config.
  /// Must call setup() before any scheduling operations.
  void setup();

  /// Updates internal schedule list from JSON config string.
  /// Called when new config is received from app.
  /// TODO: Implement with JSON parsing
  void updateSchedules(const std::string& jsonConfig);

  /// Checks current time against all schedules and triggers sprayers as needed.
  /// Should be called frequently from main loop (e.g., every 1000ms).
  /// Returns the ID of the smell sprayed (empty if none).
  /// TODO: Implement with time comparison logic
  std::string check();

  /// Gets currently active schedules for the current time.
  /// TODO: Implement
  std::vector<ScheduleEntry> getActiveSchedules() const;

  /// Gets all loaded schedules.
  /// TODO: Implement
  const std::vector<ScheduleEntry>& getAllSchedules() const;

private:
  // Vector of all loaded schedules
  std::vector<ScheduleEntry> schedules;

  // Currently active smells (to avoid repeated sprays in same window)
  // TODO: Track last spray time to prevent duplicate triggers
  std::string lastActiveSmelID;
  unsigned long lastSprayTime = 0;

  /// Parses schedule entry from JSON object.
  /// TODO: Implement
  ScheduleEntry parseScheduleEntry(const std::string& jsonObject);

  /// Converts "HH:mm" string to minutes since midnight.
  /// TODO: Implement
  uint16_t timeStringToMinutes(const std::string& timeStr) const;

  /// Gets current weekday (0 = Monday, 6 = Sunday).
  /// TODO: Integrate with TimeKeeper
  uint8_t getCurrentDayOfWeek() const;

  /// Gets current time as minutes since midnight.
  /// TODO: Integrate with TimeKeeper
  uint16_t getCurrentTimeInMinutes() const;

  /// Triggers spraying of a specific smell.
  /// TODO: Integrate with Sprayer class
  void triggerSpray(const std::string& smellId);
};
