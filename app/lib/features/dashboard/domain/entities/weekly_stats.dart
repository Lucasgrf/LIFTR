import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/day_adherence.dart';

/// Pure Domain Entity representing aggregated weekly training statistics and adherence.
@immutable
class WeeklyStats {
  WeeklyStats({
    this.completedWorkoutsCount = 0,
    this.targetWorkoutsCount = 4,
    this.totalVolumeKg = 0.0,
    this.totalDurationMinutes = 0,
    List<DayAdherence> days = const [],
  }) : days = List.unmodifiable(days);

  const WeeklyStats.empty()
      : completedWorkoutsCount = 0,
        targetWorkoutsCount = 4,
        totalVolumeKg = 0.0,
        totalDurationMinutes = 0,
        days = const [];

  final int completedWorkoutsCount;
  final int targetWorkoutsCount;
  final double totalVolumeKg;
  final int totalDurationMinutes;
  final List<DayAdherence> days;

  double get adherencePercentage => targetWorkoutsCount > 0
      ? (completedWorkoutsCount / targetWorkoutsCount).clamp(0.0, 1.0)
      : 0.0;

  WeeklyStats copyWith({
    int? completedWorkoutsCount,
    int? targetWorkoutsCount,
    double? totalVolumeKg,
    int? totalDurationMinutes,
    List<DayAdherence>? days,
  }) {
    return WeeklyStats(
      completedWorkoutsCount:
          completedWorkoutsCount ?? this.completedWorkoutsCount,
      targetWorkoutsCount: targetWorkoutsCount ?? this.targetWorkoutsCount,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
      totalDurationMinutes:
          totalDurationMinutes ?? this.totalDurationMinutes,
      days: days ?? this.days,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeeklyStats &&
        other.completedWorkoutsCount == completedWorkoutsCount &&
        other.targetWorkoutsCount == targetWorkoutsCount &&
        other.totalVolumeKg == totalVolumeKg &&
        other.totalDurationMinutes == totalDurationMinutes &&
        listEquals(other.days, days);
  }

  @override
  int get hashCode => Object.hash(
        completedWorkoutsCount,
        targetWorkoutsCount,
        totalVolumeKg,
        totalDurationMinutes,
        Object.hashAll(days),
      );
}
