/// Represents a single smell/fragrance bottle in the device.
///
/// Each smell has a unique ID and user-defined name.
/// This model is immutable and supports JSON serialization.
///
/// TODO: Implement fromJson/toJson for JSON serialization
class Smell {
  final String id;
  final String name;

  const Smell({
    required this.id,
    required this.name,
  });

  /// Creates a copy of this Smell with optional field overrides.
  Smell copyWith({
    String? id,
    String? name,
  }) {
    return Smell(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  /// Creates a Smell from JSON.
  /// TODO: Implement JSON deserialization
  factory Smell.fromJson(Map<String, dynamic> json) {
    return Smell(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  /// Converts this Smell to JSON.
  /// TODO: Implement JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  String toString() => 'Smell(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Smell && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
