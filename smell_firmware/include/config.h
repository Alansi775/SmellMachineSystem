/// Device configuration constants for SmellDevice ESP32.
///
/// Defines device name, BLE service/characteristic UUIDs, NVS keys, and constraints.
/// These constants must match the values used in the Flutter app.

#pragma once

// Device identification
static constexpr const char* DEVICE_NAME = "Smell Device";

// BLE Service and Characteristic UUIDs
// These match the UUIDs in the Flutter app (BleProvider)
static constexpr const char* BLE_SERVICE_UUID = "12345678-1234-1234-1234-123456789abc";
static constexpr const char* BLE_CONFIG_CHAR_UUID = "bbcc0001-e56f-504d-a6c5-6c2342e5672a";
static constexpr const char* BLE_RESPONSE_CHAR_UUID = "bbcc0002-e56f-504d-a6c5-6c2342e5672a";

// NVS (Preferences) Keys
static constexpr const char* NVS_NAMESPACE = "SmellDevice";
static constexpr const char* NVS_CONFIG_KEY = "device_config";

// Configuration limits
static constexpr int MAX_SMELLS = 8;
static constexpr int MAX_SCHEDULES = 32;
static constexpr int MAX_NAME_LENGTH = 32;

// JSON buffer size for device config
static constexpr size_t JSON_BUFFER_SIZE = 2048;

// Serial communication baud rate
static constexpr uint32_t SERIAL_BAUD_RATE = 115200;
