import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/cardio_log.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_snapshot.dart';

@immutable
class DailyCardioBreakdown {
  const DailyCardioBreakdown({
    required this.day,
    this.inSessionSeconds = 0,
    this.standaloneSeconds = 0,
  });

  final DateTime day;
  final int inSessionSeconds;
  final int standaloneSeconds;

  int get totalSeconds => inSessionSeconds + standaloneSeconds;

  int get totalMinutes => (totalSeconds / 60).round();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyCardioBreakdown &&
        other.day == day &&
        other.inSessionSeconds == inSessionSeconds &&
        other.standaloneSeconds == standaloneSeconds;
  }

  @override
  int get hashCode => Object.hash(day, inSessionSeconds, standaloneSeconds);
}

@immutable
class WeeklyComparisonData {
  WeeklyComparisonData({
    required this.currentWeek,
    this.previousWeek,
    List<DailyCardioBreakdown> currentWeekDailyCardio = const [],
    List<CardioLog> currentWeekStandaloneCardio = const [],
    List<WeeklySnapshot> recentWeeksHistory = const [],
  })  : currentWeekDailyCardio = List.unmodifiable(currentWeekDailyCardio),
        currentWeekStandaloneCardio =
            List.unmodifiable(currentWeekStandaloneCardio),
        recentWeeksHistory = List.unmodifiable(recentWeeksHistory);

  final WeeklySnapshot currentWeek;
  final WeeklySnapshot? previousWeek;
  final List<DailyCardioBreakdown> currentWeekDailyCardio;
  final List<CardioLog> currentWeekStandaloneCardio;
  final List<WeeklySnapshot> recentWeeksHistory;

  bool get hasPreviousWeek => previousWeek != null;

  int? get cardioDeltaSeconds => previousWeek == null
      ? null
      : currentWeek.cardioDurationSeconds -
          previousWeek!.cardioDurationSeconds;

  int? get workoutsDelta => previousWeek == null
      ? null
      : currentWeek.workoutsCompleted - previousWeek!.workoutsCompleted;

  int? get workingSetsDelta => previousWeek == null
      ? null
      : currentWeek.workingSetsCount - previousWeek!.workingSetsCount;

  double? get volumeDeltaKg => previousWeek == null
      ? null
      : currentWeek.totalVolumeKg - previousWeek!.totalVolumeKg;

  int? get trainingDurationDeltaSeconds => previousWeek == null
      ? null
      : currentWeek.trainingDurationSeconds -
          previousWeek!.trainingDurationSeconds;

  double? get avgRpeDelta =>
      (previousWeek?.avgRpe != null && currentWeek.avgRpe != null)
          ? double.parse(
              (currentWeek.avgRpe! - previousWeek!.avgRpe!).toStringAsFixed(1),
            )
          : null;

  double? get avgExecutionScoreDelta =>
      (previousWeek?.avgExecutionScore != null &&
              currentWeek.avgExecutionScore != null)
          ? double.parse(
              (currentWeek.avgExecutionScore! -
                      previousWeek!.avgExecutionScore!)
                  .toStringAsFixed(1),
            )
          : null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeeklyComparisonData &&
        other.currentWeek == currentWeek &&
        other.previousWeek == previousWeek &&
        listEquals(other.currentWeekDailyCardio, currentWeekDailyCardio) &&
        listEquals(
          other.currentWeekStandaloneCardio,
          currentWeekStandaloneCardio,
        ) &&
        listEquals(other.recentWeeksHistory, recentWeeksHistory);
  }

  @override
  int get hashCode => Object.hash(
        currentWeek,
        previousWeek,
        Object.hashAll(currentWeekDailyCardio),
        Object.hashAll(currentWeekStandaloneCardio),
        Object.hashAll(recentWeeksHistory),
      );
}
