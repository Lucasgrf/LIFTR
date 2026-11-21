import 'package:flutter/foundation.dart';

/// Pure Domain Entity representing a progress checkpoint recorded for a goal.
@immutable
class GoalCheckpoint {
  const GoalCheckpoint({
    required this.id,
    required this.goalId,
    required this.value,
    required this.recordedAt,
    this.notes,
  });

  final String id;
  final String goalId;
  final double value;
  final DateTime recordedAt;
  final String? notes;

  GoalCheckpoint copyWith({
    String? id,
    String? goalId,
    double? value,
    DateTime? recordedAt,
    String? notes,
  }) {
    return GoalCheckpoint(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      value: value ?? this.value,
      recordedAt: recordedAt ?? this.recordedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalCheckpoint &&
        other.id == id &&
        other.goalId == goalId &&
        other.value == value &&
        other.recordedAt == recordedAt &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
        id,
        goalId,
        value,
        recordedAt,
        notes,
      );
}
