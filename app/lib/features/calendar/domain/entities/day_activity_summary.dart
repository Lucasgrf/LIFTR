import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

/// Pure Domain Entity summarizing a user's fitness activities on a specific day.
@immutable
class DayActivitySummary {
  const DayActivitySummary({
    required this.date,
    this.workoutSession,
    this.weightEntry,
    this.dailyNutrition,
  });

  final DateTime date;
  final WorkoutSession? workoutSession;
  final WeightEntry? weightEntry;
  final DailyNutrition? dailyNutrition;

  bool get hasWorkout => workoutSession != null;
  bool get hasWeight => weightEntry != null;
  bool get hasNutrition => dailyNutrition != null && dailyNutrition!.meals.isNotEmpty;

  bool get isFullAdherence => hasWorkout && hasWeight && hasNutrition;

  DayActivitySummary copyWith({
    DateTime? date,
    WorkoutSession? workoutSession,
    WeightEntry? weightEntry,
    DailyNutrition? dailyNutrition,
  }) {
    return DayActivitySummary(
      date: date ?? this.date,
      workoutSession: workoutSession ?? this.workoutSession,
      weightEntry: weightEntry ?? this.weightEntry,
      dailyNutrition: dailyNutrition ?? this.dailyNutrition,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayActivitySummary &&
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day &&
        other.workoutSession == workoutSession &&
        other.weightEntry == weightEntry &&
        other.dailyNutrition == dailyNutrition;
  }

  @override
  int get hashCode => Object.hash(
        date.year,
        date.month,
        date.day,
        workoutSession,
        weightEntry,
        dailyNutrition,
      );
}
