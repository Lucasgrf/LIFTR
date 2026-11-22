import 'package:flutter/foundation.dart';

/// Aggregated weekly snapshot persisted in `weekly_snapshots` for comparison
/// and longitudinal tracking across weeks.
@immutable
class WeeklySnapshot {
  const WeeklySnapshot({
    this.id,
    this.userId,
    required this.weekStart,
    required this.weekEnd,
    this.workoutsCompleted = 0,
    this.cardioDurationSeconds = 0,
    this.trainingDurationSeconds = 0,
    this.workingSetsCount = 0,
    this.totalVolumeKg = 0.0,
    this.avgRpe,
    this.avgExecutionScore,
    this.updatedAt,
  });

  final String? id;
  final String? userId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int workoutsCompleted;
  final int cardioDurationSeconds;
  final int trainingDurationSeconds;
  final int workingSetsCount;
  final double totalVolumeKg;
  final double? avgRpe;
  final double? avgExecutionScore;
  final DateTime? updatedAt;

  bool get hasActivity => workoutsCompleted > 0 || cardioDurationSeconds > 0;

  int get cardioMinutes => (cardioDurationSeconds / 60).round();

  int get trainingMinutes => (trainingDurationSeconds / 60).round();

  WeeklySnapshot copyWith({
    String? id,
    String? userId,
    DateTime? weekStart,
    DateTime? weekEnd,
    int? workoutsCompleted,
    int? cardioDurationSeconds,
    int? trainingDurationSeconds,
    int? workingSetsCount,
    double? totalVolumeKg,
    double? avgRpe,
    double? avgExecutionScore,
    DateTime? updatedAt,
  }) {
    return WeeklySnapshot(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      workoutsCompleted: workoutsCompleted ?? this.workoutsCompleted,
      cardioDurationSeconds:
          cardioDurationSeconds ?? this.cardioDurationSeconds,
      trainingDurationSeconds:
          trainingDurationSeconds ?? this.trainingDurationSeconds,
      workingSetsCount: workingSetsCount ?? this.workingSetsCount,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
      avgRpe: avgRpe ?? this.avgRpe,
      avgExecutionScore: avgExecutionScore ?? this.avgExecutionScore,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeeklySnapshot &&
        other.id == id &&
        other.userId == userId &&
        other.weekStart == weekStart &&
        other.weekEnd == weekEnd &&
        other.workoutsCompleted == workoutsCompleted &&
        other.cardioDurationSeconds == cardioDurationSeconds &&
        other.trainingDurationSeconds == trainingDurationSeconds &&
        other.workingSetsCount == workingSetsCount &&
        other.totalVolumeKg == totalVolumeKg &&
        other.avgRpe == avgRpe &&
        other.avgExecutionScore == avgExecutionScore &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        weekStart,
        weekEnd,
        workoutsCompleted,
        cardioDurationSeconds,
        trainingDurationSeconds,
        workingSetsCount,
        totalVolumeKg,
        avgRpe,
        avgExecutionScore,
        updatedAt,
      );
}
