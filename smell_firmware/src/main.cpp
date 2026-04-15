/// Main program for SmellDevice ESP32 firmware.
///
/// Initializes all subsystems (BLE, Storage, Scheduler, Sprayer, TimeKeeper)
/// and implements the main application loop.

#include <Arduino.h>
#include "ble_manager.h"
#include "storage_manager.h"
#include "scheduler.h"
#include "sprayer.h"
#include "time_keeper.h"
#include "config.h"

// Global singleton instances
BleManager bleManager;
StorageManager storageManager;
Scheduler scheduler;
Sprayer sprayer;
TimeKeeper timeKeeper;

/// Callback when new configuration is received from mobile app via BLE.
void onConfigReceived(const std::string& jsonConfig) {
  Serial.print("[Main] New config received from app: ");
  Serial.println(jsonConfig.c_str());

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
    }
  }

  // Check for schedule/smell config
  if (jsonConfig.find("schedules") != std::string::npos || 
      jsonConfig.find("smells") != std::string::npos) {
    // Save to NVS
    if (storageManager.saveConfig(jsonConfig)) {
      Serial.println("[Main] Config saved to NVS");
      // Update scheduler with new config
      scheduler.updateSchedules(jsonConfig);
      Serial.println("[Main] Scheduler updated");
    } else {
      Serial.println("[Main] ERROR: Failed to save config");
    }
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

  // Load configuration from storage
  std::string savedConfig = storageManager.loadConfig();
  if (!savedConfig.empty()) {
    Serial.print("[Setup] Loading saved config: ");
    Serial.println(savedConfig.c_str());
    scheduler.updateSchedules(savedConfig);
  } else {
    Serial.println("[Setup] No saved configuration found");
  }

  Serial.println("[Setup] 5. Initializing BLE...");
  bleManager.setup();
  bleManager.setOnConfigReceived(onConfigReceived);

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

  // Small delay to prevent watchdog timeout
  delay(1000); // Check scheduler every second
}
