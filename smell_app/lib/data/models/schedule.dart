/// Represents a schedule for automatic spray dispensing.
///
/// A schedule specifies when and which smell should be sprayed:
/// - dayOfWeek: 0 = Monday, 6 = Sunday
/// - startTime / endTime: "HH:mm" format
/// - smellId: which bottle to spray during this time window
///
/// This model is immutable and supports JSON serialization.
///
/// TODO: Implement time parsing and validation
class Schedule {
  static const int minPumpStartSeconds = 5;
  static const int maxPumpStartSeconds = 240;
  static const int minPumpWaitSeconds = 10;
  static const int maxPumpWaitSeconds = 360;

  final String id;
  final String smellId;
  final int dayOfWeek; // 0 = Monday, 6 = Sunday
  final String startTime; // "HH:mm"
  final String endTime;   // "HH:mm"
  final int pumpStartSeconds;
  final int pumpWaitSeconds;

  const Schedule({
    required this.id,
    required this.smellId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.pumpStartSeconds = 5,
    this.pumpWaitSeconds = 10,
  });

  /// Creates a copy of this Schedule with optional field overrides.
  Schedule copyWith({
    String? id,
    String? smellId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    int? pumpStartSeconds,
    int? pumpWaitSeconds,
  }) {
    return Schedule(
      id: id ?? this.id,
      smellId: smellId ?? this.smellId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pumpStartSeconds: _clampPumpStart(
        pumpStartSeconds ?? this.pumpStartSeconds,
      ),
      pumpWaitSeconds: _clampPumpWait(
        pumpWaitSeconds ?? this.pumpWaitSeconds,
      ),
    );
  }

  /// Creates a Schedule from JSON.
  /// TODO: Implement JSON deserialization with validation
  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String? ?? '',
      smellId: json['smellId'] as String? ?? '',
      dayOfWeek: json['dayOfWeek'] as int? ?? 0,
      startTime: json['startTime'] as String? ?? '00:00',
      endTime: json['endTime'] as String? ?? '00:00',
      pumpStartSeconds: _clampPumpStart(_toInt(json['pumpStartSeconds']) ?? 5),
      pumpWaitSeconds: _clampPumpWait(_toInt(json['pumpWaitSeconds']) ?? 10),
    );
  }

  /// Converts this Schedule to JSON.
  /// TODO: Implement JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'smellId': smellId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'pumpStartSeconds': pumpStartSeconds,
      'pumpWaitSeconds': pumpWaitSeconds,
    };
  }

  static int _clampPumpStart(int value) =>
      value.clamp(minPumpStartSeconds, maxPumpStartSeconds);

  static int _clampPumpWait(int value) =>
      value.clamp(minPumpWaitSeconds, maxPumpWaitSeconds);

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'Schedule(id: $id, smellId: $smellId, dayOfWeek: $dayOfWeek, '
      'startTime: $startTime, endTime: $endTime, '
      'pumpStartSeconds: $pumpStartSeconds, pumpWaitSeconds: $pumpWaitSeconds)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Schedule &&
        other.id == id &&
        other.smellId == smellId &&
        other.dayOfWeek == dayOfWeek &&
        other.startTime == startTime &&
          other.endTime == endTime &&
          other.pumpStartSeconds == pumpStartSeconds &&
          other.pumpWaitSeconds == pumpWaitSeconds;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      smellId.hashCode ^
      dayOfWeek.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      pumpStartSeconds.hashCode ^
      pumpWaitSeconds.hashCode;
}
