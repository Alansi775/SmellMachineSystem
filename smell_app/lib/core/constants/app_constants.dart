/// Application-wide constants: device name, BLE UUIDs, limits, etc.
class AppConstants {
  // Device identification
  static const String deviceName = 'Smell Device';

  // BLE Service and Characteristic UUIDs
  static const String bleServiceUuid = '12345678-1234-1234-1234-123456789abc';
  static const String bleConfigCharacteristicUuid = 'bbcc0001-e56f-504d-a6c5-6c2342e5672a';
  static const String bleResponseCharacteristicUuid = 'bbcc0002-e56f-504d-a6c5-6c2342e5672a';

  // NVS Preferences keys (ESP32)
  static const String nvsConfigKey = 'device_config';

  // Constraints
  static const int maxSmells = 8;
  static const int maxSchedules = 32;
  static const int maxSmellNameLength = 32;

  // No instances
  AppConstants._();
}
