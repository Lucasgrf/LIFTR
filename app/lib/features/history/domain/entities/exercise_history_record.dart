import 'package:flutter/foundation.dart';

/// Pure Domain Entity representing the performance record of an exercise in a completed session.
@immutable
class ExerciseHistoryRecord {
  const ExerciseHistoryRecord({
    required this.sessionId,
    required this.sessionName,
    required this.date,
    required this.setsCount,
    required this.topWeightKg,
    required this.topReps,
    required this.bestEstimated1Rm,
    this.notes,
  });

  final String sessionId;
  final String sessionName;
  final DateTime date;
  final int setsCount;
  final double topWeightKg;
  final int topReps;
  final double bestEstimated1Rm;
  final String? notes;

  ExerciseHistoryRecord copyWith({
    String? sessionId,
    String? sessionName,
    DateTime? date,
    int? setsCount,
    double? topWeightKg,
    int? topReps,
    double? bestEstimated1Rm,
    String? notes,
  }) {
    return ExerciseHistoryRecord(
      sessionId: sessionId ?? this.sessionId,
      sessionName: sessionName ?? this.sessionName,
      date: date ?? this.date,
      setsCount: setsCount ?? this.setsCount,
      topWeightKg: topWeightKg ?? this.topWeightKg,
      topReps: topReps ?? this.topReps,
      bestEstimated1Rm: bestEstimated1Rm ?? this.bestEstimated1Rm,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseHistoryRecord &&
        other.sessionId == sessionId &&
        other.sessionName == sessionName &&
        other.date == date &&
        other.setsCount == setsCount &&
        other.topWeightKg == topWeightKg &&
        other.topReps == topReps &&
        other.bestEstimated1Rm == bestEstimated1Rm &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
        sessionId,
        sessionName,
        date,
        setsCount,
        topWeightKg,
        topReps,
        bestEstimated1Rm,
        notes,
      );
}
