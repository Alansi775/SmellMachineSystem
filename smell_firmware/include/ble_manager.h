/// BLE (Bluetooth Low Energy) Manager for NimBLE-Arduino.
///
/// Handles all BLE communication:
/// - Creates BLE server with Device Information Service
/// - Manages configuration characteristic (read/write)
/// - Serializes/deserializes JSON configuration
/// - Broadcasts "Smell Device" name for discovery
///
/// UML-style class with public methods and private state.

#pragma once

#include <Arduino.h>
#include <string>

/// Manages BLE service, characteristics, and callbacks.
/// TODO: Implement all methods - currently just function signatures
class BleManager {
public:
  /// Initialize BLE server and advertise as "Smell Device".
  /// Must call setup() before any BLE operations.
  void setup();

  /// Called when app writes new JSON configuration.
  /// TODO: Implement callback registration
  void setOnConfigReceived(void (*callback)(const std::string& config));

  /// Sends current device configuration to connected client.
  /// Writes to the response characteristic.
  /// TODO: Implement
  void sendConfig(const std::string& jsonConfig);

  /// Check if a client is currently connected.
  /// TODO: Implement
  bool isConnected() const;

  /// Stops BLE and cleans up.
  /// TODO: Implement
  void shutdown();

private:
  // Callback function pointer for config updates
  void (*onConfigReceived)(const std::string&) = nullptr;

  // NimBLE connection handle (when client is connected)
  // TODO: Track connection state

  /// Initializes the BLE service and characteristics.
  /// Called from setup().
  /// TODO: Implement
  void initializeService();

  /// Called when a BLE client connects.
  /// TODO: Implement
  void onConnect();

  /// Called when a BLE client disconnects.
  /// TODO: Implement
  void onDisconnect();

  /// Called when config characteristic is written by client.
  /// TODO: Implement
  void onConfigWrite(const std::string& data);
};
