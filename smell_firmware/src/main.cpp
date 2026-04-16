/// Main program for SmellDevice ESP32 firmware.
///
/// Initializes all subsystems (BLE, Storage, Scheduler, Sprayer, TimeKeeper)
/// and implements the main application loop.

#include <Arduino.h>
#include <ArduinoJson.h>
#include <map>
#include "ble_manager.h"
#include "storage_manager.h"
#include "scheduler.h"
#include "sprayer.h"
#include "time_keeper.h"
#include "display_manager.h"
#include "config.h"

// Global singleton instances
BleManager bleManager;
StorageManager storageManager;
Scheduler scheduler;
Sprayer sprayer;
TimeKeeper timeKeeper;
DisplayManager displayManager;

struct NextSmellInfo {
  bool found = false;
  std::string smellName;
  uint8_t dayOfWeek = 0;
  std::string startTime;
};

static std::string activeConfigJson;

static std::string getCurrentConfigJson() {
  if (!activeConfigJson.empty()) {
    return activeConfigJson;
  }

  std::string savedConfig = storageManager.loadConfig();
  if (!savedConfig.empty()) {
    activeConfigJson = savedConfig;
    return savedConfig;
  }

  return "{\"smells\":[],\"schedules\":[]}";
}

static uint16_t timeToMinutes(const std::string& timeStr) {
  if (timeStr.length() < 5) return 0;
  int hour = atoi(timeStr.substr(0, 2).c_str());
  int minute = atoi(timeStr.substr(3, 2).c_str());
  return static_cast<uint16_t>(hour * 60 + minute);
}

static int computeMinutesUntil(uint8_t targetDay, const std::string& targetStartTime) {
  if (!timeKeeper.isTimeSynchronized()) {
    return -1;
  }

  int currentDay = timeKeeper.getDayOfWeek();
  int currentMinutes = timeKeeper.getMinutesSinceMidnight();
  int targetMinutes = timeToMinutes(targetStartTime);

  int delta = ((targetDay - currentDay + 7) % 7) * 1440 + (targetMinutes - currentMinutes);
  if (delta < 0) {
    delta += 7 * 1440;
  }
  return delta;
}

static NextSmellInfo computeNextSmell(const std::string& jsonConfig) {
  NextSmellInfo result;

  DynamicJsonDocument doc(JSON_BUFFER_SIZE);
  DeserializationError error = deserializeJson(doc, jsonConfig.c_str());
  if (error) {
    return result;
  }

  std::map<std::string, std::string> smellNameById;
  if (doc["smells"].is<JsonArray>()) {
    for (JsonObject smell : doc["smells"].as<JsonArray>()) {
      std::string id = smell["id"] | "";
      std::string name = smell["name"] | "";
      if (!id.empty()) {
        smellNameById[id] = name.empty() ? id : name;
      }
    }
  }

  if (!doc["schedules"].is<JsonArray>()) {
    return result;
  }

  int currentDay = 0;
  int currentMinutes = 0;
  if (timeKeeper.isTimeSynchronized()) {
    currentDay = timeKeeper.getDayOfWeek();
    currentMinutes = timeKeeper.getMinutesSinceMidnight();
  }

  int bestDelta = 7 * 1440 + 1;
  JsonObject bestSchedule;

  for (JsonObject sch : doc["schedules"].as<JsonArray>()) {
    int schDay = sch["dayOfWeek"] | 0;
    std::string start = sch["startTime"] | "00:00";
    int schStart = timeToMinutes(start);

    int delta = ((schDay - currentDay + 7) % 7) * 1440 + (schStart - currentMinutes);
    if (delta < 0) {
      delta += 7 * 1440;
    }

    if (delta < bestDelta) {
      bestDelta = delta;
      bestSchedule = sch;
    }
  }

  if (bestSchedule.isNull()) {
    return result;
  }

  std::string smellId = bestSchedule["smellId"] | "";
  result.found = true;
  result.dayOfWeek = bestSchedule["dayOfWeek"] | 0;
  result.startTime = bestSchedule["startTime"] | "00:00";
  result.smellName = smellNameById.count(smellId) ? smellNameById[smellId] : smellId;
  return result;
}

static std::string buildApplyResultJson(bool success, const std::string& jsonConfig) {
  DynamicJsonDocument response(768);
  response["type"] = "apply_result";
  response["success"] = success;
  response["bleConnected"] = bleManager.isConnected();
  response["message"] = success ? "Configuration applied" : "Configuration failed";

  NextSmellInfo next = computeNextSmell(jsonConfig);
  response["hasNextSmell"] = next.found;
  if (next.found) {
    response["nextSmellName"] = next.smellName;
    response["nextDayOfWeek"] = next.dayOfWeek;
    response["nextStartTime"] = next.startTime;
  }

  std::string out;
  serializeJson(response, out);
  return out;
}

/// Callback when new configuration is received from mobile app via BLE.
void onConfigReceived(const std::string& jsonConfig) {
  Serial.print("[Main] New config received from app: ");
  Serial.println(jsonConfig.c_str());
  displayManager.showDataReceived(jsonConfig);

  if (jsonConfig.find("get_config") != std::string::npos) {
    std::string responseJson = getCurrentConfigJson();
    DynamicJsonDocument response(768);
    DeserializationError error = deserializeJson(response, responseJson.c_str());
    if (!error) {
      response["type"] = "device_config";
      std::string out;
      serializeJson(response, out);
      bleManager.sendConfig(out);
      Serial.print("[Main] Sent device config to app: ");
      Serial.println(out.c_str());
    } else {
      Serial.println("[Main] ERROR: Failed to serialize device config response");
    }
    return;
  }

  // Check for time sync (unixTime key)
  if (jsonConfig.find("unixTime") != std::string::npos) {
    // Parse unixTime from JSON (simple parsing for {"unixTime":1234567890})
    size_t start = jsonConfig.find("unixTime") + 9; // "unixTime" + ":"
    size_t end = jsonConfig.find("}", start);
    std::string timeStr = jsonConfig.substr(start, end - start);
    time_t unixTime = strtol(timeStr.c_str(), nullptr, 10);
    
    if (unixTime > 0) {
      timeKeeper.syncTime(unixTime);
      Serial.print("[Main] Time synced: ");
      Serial.println(unixTime);

      DynamicJsonDocument syncDoc(256);
      syncDoc["type"] = "time_sync";
      syncDoc["success"] = true;
      syncDoc["unixTime"] = unixTime;
      std::string syncOut;
      serializeJson(syncDoc, syncOut);
      bleManager.sendConfig(syncOut);
    }
  }

  // Check for schedule/smell config
  if (jsonConfig.find("schedules") != std::string::npos || 
      jsonConfig.find("smells") != std::string::npos) {
    bool savedOk = false;

    // Save to NVS
    if (storageManager.saveConfig(jsonConfig)) {
      savedOk = true;
      activeConfigJson = jsonConfig;
      Serial.println("[Main] Config saved to NVS");
      // Update scheduler with new config
      scheduler.updateSchedules(jsonConfig);
      Serial.println("[Main] Scheduler updated");
    } else {
      Serial.println("[Main] ERROR: Failed to save config");
    }

    // Notify app/display with apply result and next smell summary.
    std::string applyResult = buildApplyResultJson(savedOk, jsonConfig);
    bleManager.sendConfig(applyResult);

    NextSmellInfo next = computeNextSmell(jsonConfig);
    int minutesUntil = next.found ? computeMinutesUntil(next.dayOfWeek, next.startTime) : -1;
    displayManager.showApplyResult(
      savedOk,
      next.found ? next.smellName : "",
      next.dayOfWeek,
      next.startTime
    );
    displayManager.setNextSmellStatus(
      next.found,
      next.found ? next.smellName : "",
      next.dayOfWeek,
      next.startTime,
      minutesUntil
    );

    Serial.print("[Display] ApplyResult: ");
    Serial.println(applyResult.c_str());
  }
}

/// Arduino setup() - runs once on startup.
void setup() {
  // Initialize serial communication at 115200 baud
  Serial.begin(115200);
  delay(1000); // Wait for serial monitor to connect

  Serial.println("\n\n========================================");
  Serial.println("SmellDevice Firmware Booting");
  Serial.println("========================================\n");

  // Initialize all subsystems in order
  Serial.println("[Setup] 1. Initializing TimeKeeper...");
  timeKeeper.setup();

  Serial.println("[Setup] 2. Initializing StorageManager...");
  storageManager.setup();

  Serial.println("[Setup] 3. Initializing Sprayer...");
  sprayer.setup();

  Serial.println("[Setup] 4. Initializing Scheduler...");
  scheduler.setup();

  Serial.println("[Setup] 4.5 Initializing BLE...");
  bleManager.setup();
  bleManager.setOnConfigReceived(onConfigReceived);

  Serial.println("[Setup] 5. Initializing Display...");
  displayManager.setup();

  // Load configuration from storage
  std::string savedConfig = storageManager.loadConfig();
  if (!savedConfig.empty()) {
    activeConfigJson = savedConfig;
    Serial.print("[Setup] Loading saved config: ");
    Serial.println(savedConfig.c_str());
    scheduler.updateSchedules(savedConfig);
  } else {
    Serial.println("[Setup] No saved configuration found");
  }

  Serial.println("\n========================================");
  Serial.println("SmellDevice Ready - Waiting for Connection");
  Serial.println("========================================\n");
}

/// Arduino loop() - runs repeatedly.
void loop() {
  // Update sprayer timing (handle spray duration)
  sprayer.update();

  // Check scheduler for any matching schedules
  std::string sprayed = scheduler.check();
  if (!sprayed.empty()) {
    Serial.print("[Loop] Schedule triggered spray: ");
    Serial.println(sprayed.c_str());
  }

  // Print BLE connection status periodically
  static unsigned long lastStatusPrint = 0;
  if (millis() - lastStatusPrint > 10000) { // Every 10 seconds
    if (bleManager.isConnected()) {
      Serial.println("[Loop] Status: BLE Connected");
    } else {
      Serial.println("[Loop] Status: Waiting for BLE connection...");
    }
    lastStatusPrint = millis();
  }

  displayManager.setBleConnected(bleManager.isConnected());

  if (!activeConfigJson.empty()) {
    NextSmellInfo next = computeNextSmell(activeConfigJson);
    int minutesUntil = next.found ? computeMinutesUntil(next.dayOfWeek, next.startTime) : -1;
    displayManager.setNextSmellStatus(
      next.found,
      next.found ? next.smellName : "",
      next.dayOfWeek,
      next.startTime,
      minutesUntil
    );
  }

  displayManager.update();

  // Small delay to prevent watchdog timeout
  delay(1000); // Check scheduler every second
}
