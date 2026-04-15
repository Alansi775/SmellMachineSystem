/// Storage Manager for persistent device configuration using NVS.
///
/// Handles reading/writing/erasing JSON configuration from ESP32 NVS (Non-Volatile Storage).
/// Preferences survive power loss and BLE disconnection.
///
/// NVS is organized as key-value pairs. We store the entire config JSON as a single string.

#pragma once

#include <Arduino.h>
#include <string>

/// Manages NVS-based persistence of device configuration.
/// TODO: Implement all methods - currently just function signatures
class StorageManager {
public:
  /// Initialize NVS and prepare for read/write operations.
  /// Must call setup() before any storage operations.
  void setup();

  /// Saves a JSON configuration string to NVS.
  /// Returns true if successful, false on error.
  /// TODO: Implement
  bool saveConfig(const std::string& jsonConfig);

  /// Loads the stored JSON configuration from NVS.
  /// Returns empty string if no config stored or on error.
  /// TODO: Implement
  std::string loadConfig() const;

  /// Checks if a configuration exists in NVS.
  /// TODO: Implement
  bool hasConfig() const;

  /// Erases all stored data from NVS.
  /// Useful for "Wipe Device Data" feature.
  /// TODO: Implement
  bool eraseAll();

  /// Gets the size of stored config in bytes.
  /// TODO: Implement
  size_t getConfigSize() const;

private:
  // NVS preferences instance
  // TODO: Declare Preferences object

  /// Verifies NVS is initialized and accessible.
  /// TODO: Implement
  bool ensureInitialized() const;
};
