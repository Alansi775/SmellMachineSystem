/// Display manager for board screen status.
///
/// This module is intentionally isolated in its own files so screen logic
/// can be maintained independently from BLE/scheduler logic.

#pragma once

#include <Arduino.h>
#include <string>

class DisplayManager {
public:
  /// Initialize display subsystem.
  void setup();

  /// Shows initial branding splash on boot.
  void showWelcome();

  /// Update BLE connection indicator on the screen.
  void setBleConnected(bool connected);

  /// Show brief indication that data has arrived from app.
  void showDataReceived(const std::string& payload);

  /// Show configuration apply result and next smell summary.
  void showApplyResult(
    bool success,
    const std::string& nextSmellName,
    uint8_t dayOfWeek,
    const std::string& startTime
  );

  /// Updates upcoming smell summary and countdown in minutes.
  void setNextSmellStatus(
    bool hasNext,
    const std::string& nextSmellName,
    uint8_t dayOfWeek,
    const std::string& startTime,
    int minutesUntilNext
  );

  /// Refresh display heartbeat/status text.
  void update();

private:
  void render();
  std::string trimForLine(const std::string& input, size_t maxLen) const;

  bool initialized = false;
  bool displayAvailable = false;
  bool bleConnected = false;

  unsigned long lastHeartbeatMs = 0;
  unsigned long splashUntilMs = 0;
  unsigned long transientUntilMs = 0;

  std::string statusLine = "Booting";
  std::string dataLine = "Waiting for app";
  std::string transientLine;

  bool hasNextSmell = false;
  std::string nextSmellName;
  uint8_t nextSmellDay = 0;
  std::string nextSmellTime;
  int minutesUntilNext = -1;

  const char* dayName(uint8_t day) const;
};
