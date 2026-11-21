import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/features/calendar/domain/entities/day_activity_summary.dart';

/// Pure Domain Aggregate for an entire month of user fitness activities.
@immutable
class MonthActivityData {
  MonthActivityData({
    required this.year,
    required this.month,
    List<DayActivitySummary> days = const [],
  }) : days = List.unmodifiable(days);

  final int year;
  final int month;
  final List<DayActivitySummary> days;

  int get totalCompletedWorkouts =>
      days.where((d) => d.hasWorkout).length;

  int get totalWeightLogDays =>
      days.where((d) => d.hasWeight).length;

  int get totalNutritionLogDays =>
      days.where((d) => d.hasNutrition).length;

  double get totalVolumeKg =>
      days.fold(0.0, (sum, d) => sum + (d.workoutSession?.totalVolumeKg ?? 0.0));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonthActivityData &&
        other.year == year &&
        other.month == month &&
        listEquals(other.days, days);
  }

  @override
  int get hashCode => Object.hash(
        year,
        month,
        Object.hashAll(days),
      );
}
