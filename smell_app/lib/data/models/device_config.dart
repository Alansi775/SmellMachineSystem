/// Root device configuration object.
///
/// This represents the complete configuration state for the SmellDevice ESP32.
/// It contains lists of smells and schedules, and is serialized to JSON for
/// transmission to the device via BLE.
///
/// Example JSON structure:
/// {
///   "smells": [
///     {"id": "smell001", "name": "Lavender"},
///     {"id": "smell002", "name": "Rose"}
///   ],
///   "schedules": [
///     {"id": "sched001", "smellId": "smell001", "dayOfWeek": 0, "startTime": "09:00", "endTime": "17:00"}
///   ]
/// }
///
/// TODO: Implement JSON serialization/deserialization and validation
import 'smell.dart';
import 'schedule.dart';

class DeviceConfig {
  final List<Smell> smells;
  final List<Schedule> schedules;

  const DeviceConfig({
    List<Smell>? smells,
    List<Schedule>? schedules,
  })  : smells = smells ?? const [],
        schedules = schedules ?? const [];

  /// Creates a copy of this DeviceConfig with optional field overrides.
  DeviceConfig copyWith({
    List<Smell>? smells,
    List<Schedule>? schedules,
  }) {
    return DeviceConfig(
      smells: smells ?? this.smells,
      schedules: schedules ?? this.schedules,
    );
  }

  /// Creates a DeviceConfig from JSON.
  /// TODO: Implement JSON deserialization with validation
  factory DeviceConfig.fromJson(Map<String, dynamic> json) {
    return DeviceConfig(
      smells: (json['smells'] as List?)
              ?.map((e) => Smell.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      schedules: (json['schedules'] as List?)
              ?.map((e) => Schedule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Converts this DeviceConfig to JSON.
  /// TODO: Implement JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'smells': smells.map((e) => e.toJson()).toList(),
      'schedules': schedules.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() => 'DeviceConfig(smells: ${smells.length}, schedules: ${schedules.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceConfig &&
        identical(other.smells, smells) &&
        identical(other.schedules, schedules);
  }

  @override
  int get hashCode => smells.hashCode ^ schedules.hashCode;
}
