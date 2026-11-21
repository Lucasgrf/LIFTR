/// Pure Domain Entity representing a recorded body weight measurement.
class WeightEntry {
  const WeightEntry({
    required this.id,
    this.userId,
    required this.weightKg,
    required this.measuredAt,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String? userId;
  final double weightKg;
  final DateTime measuredAt;
  final String? notes;
  final DateTime? createdAt;

  WeightEntry copyWith({
    String? id,
    String? userId,
    double? weightKg,
    DateTime? measuredAt,
    String? notes,
    DateTime? createdAt,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weightKg: weightKg ?? this.weightKg,
      measuredAt: measuredAt ?? this.measuredAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeightEntry &&
        other.id == id &&
        other.userId == userId &&
        other.weightKg == weightKg &&
        other.measuredAt == measuredAt &&
        other.notes == notes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        weightKg,
        measuredAt,
        notes,
        createdAt,
      );
}
