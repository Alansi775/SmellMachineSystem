/// Application-wide constants: device name, BLE UUIDs, limits, etc.
class AppConstants {
  // Device identification
  static const String deviceName = 'Smell Device';

  // BLE Service and Characteristic UUIDs
  // TODO: Replace with actual UUIDs generated for this project
  static const String bleServiceUuid = '180a'; // Device Information Service (example)
  static const String bleConfigCharacteristicUuid = '2a29'; // Manufacturer Name (example)
  static const String bleResponseCharacteristicUuid = '2a26'; // Firmware Revision (example)

  // NVS Preferences keys (ESP32)
  static const String nvsConfigKey = 'device_config';

  // Constraints
  static const int maxSmells = 8;
  static const int maxSchedules = 32;
  static const int maxSmellNameLength = 32;

  // No instances
  AppConstants._();
}
