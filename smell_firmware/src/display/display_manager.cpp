/// Display manager implementation.
///
/// In this project mode, we intentionally run Serial-only logs and do not
/// initialize any physical display hardware.

#include "display_manager.h"

void DisplayManager::setup() {
  initialized = true;
  displayAvailable = false;
  statusLine = "Booting";
  dataLine = "Waiting for app";

  showWelcome();

  Serial.println("[Display] Serial-only mode enabled");
}

void DisplayManager::showWelcome() {
  splashUntilMs = millis() + 2600;
  statusLine = "Welcome";
  dataLine = "Smell Device Ready";
  render();
}

void DisplayManager::setBleConnected(bool connected) {
  if (!initialized || bleConnected == connected) {
    return;
  }

  bleConnected = connected;
  statusLine = bleConnected ? "BLE connected" : "BLE waiting";
  transientLine = bleConnected ? "Phone paired successfully" : "Phone disconnected";
  transientUntilMs = millis() + 2500;

  if (bleConnected) {
    Serial.println("[Display] BLE: Connected");
  } else {
    Serial.println("[Display] BLE: Disconnected");
  }

  render();
}

void DisplayManager::showDataReceived(const std::string& payload) {
  if (!initialized) {
    return;
  }

  statusLine = "Data received";
  dataLine = "Bytes: " + std::to_string(payload.length());
  transientLine = "Payload synced from app";
  transientUntilMs = millis() + 2500;

  Serial.print("[Display] Data received bytes: ");
  Serial.println(payload.length());
  render();
}

void DisplayManager::showApplyResult(
  bool success,
  const std::string& nextSmellName,
  uint8_t dayOfWeek,
  const std::string& startTime
) {
  if (!initialized) {
    return;
  }

  if (!success) {
    statusLine = "Apply failed";
    transientLine = "Config save failed";
    transientUntilMs = millis() + 3000;
    Serial.println("[Display] Apply: FAILED");
    render();
    return;
  }

  statusLine = "Apply success";
  dataLine = "Profile active";
  transientLine = "Config stored on ESP32";
  transientUntilMs = millis() + 3000;

  Serial.println("[Display] Apply: SUCCESS");
  if (!nextSmellName.empty()) {
    Serial.print("[Display] Next smell: ");
    Serial.print(nextSmellName.c_str());
    Serial.print(" | ");
    Serial.print(dayName(dayOfWeek));
    Serial.print(" ");
    Serial.println(startTime.c_str());
  } else {
    Serial.println("[Display] Next smell: N/A");
  }

  setNextSmellStatus(!nextSmellName.empty(), nextSmellName, dayOfWeek, startTime, minutesUntilNext);
  render();
}

void DisplayManager::setNextSmellStatus(
  bool hasNext,
  const std::string& smell,
  uint8_t dayOfWeek,
  const std::string& startTime,
  int minutesUntil
) {
  hasNextSmell = hasNext;
  nextSmellName = smell;
  nextSmellDay = dayOfWeek;
  nextSmellTime = startTime;
  minutesUntilNext = minutesUntil;
}

void DisplayManager::update() {
  if (!initialized) {
    return;
  }

  if (millis() - lastHeartbeatMs < 5000) {
    return;
  }

  lastHeartbeatMs = millis();
  Serial.print("[Display] Heartbeat | BLE=");
  Serial.println(bleConnected ? "Connected" : "Disconnected");

  render();
}

void DisplayManager::render() {
  // Serial-only mode: no physical display rendering.
}

std::string DisplayManager::trimForLine(const std::string& input, size_t maxLen) const {
  if (input.length() <= maxLen) {
    return input;
  }
  if (maxLen < 4) {
    return input.substr(0, maxLen);
  }
  return input.substr(0, maxLen - 3) + "...";
}

const char* DisplayManager::dayName(uint8_t day) const {
  switch (day) {
    case 0: return "Monday";
    case 1: return "Tuesday";
    case 2: return "Wednesday";
    case 3: return "Thursday";
    case 4: return "Friday";
    case 5: return "Saturday";
    case 6: return "Sunday";
    default: return "Unknown";
  }
}
