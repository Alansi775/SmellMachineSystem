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
  final String id;
  final String smellId;
  final int dayOfWeek; // 0 = Monday, 6 = Sunday
  final String startTime; // "HH:mm"
  final String endTime;   // "HH:mm"

  const Schedule({
    required this.id,
    required this.smellId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  /// Creates a copy of this Schedule with optional field overrides.
  Schedule copyWith({
    String? id,
    String? smellId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
  }) {
    return Schedule(
      id: id ?? this.id,
      smellId: smellId ?? this.smellId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
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
    };
  }

  @override
  String toString() =>
      'Schedule(id: $id, smellId: $smellId, dayOfWeek: $dayOfWeek, '
      'startTime: $startTime, endTime: $endTime)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Schedule &&
        other.id == id &&
        other.smellId == smellId &&
        other.dayOfWeek == dayOfWeek &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      smellId.hashCode ^
      dayOfWeek.hashCode ^
      startTime.hashCode ^
      endTime.hashCode;
}
