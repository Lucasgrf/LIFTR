import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/weekly_stats.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

/// Pure Domain Aggregate representing all data needed for the Dashboard ("Hoje") screen.
@immutable
class DashboardData {
  DashboardData({
    this.activePlan,
    this.activeSession,
    this.todayWorkout,
    this.lastCompletedSession,
    this.weeklyStats = const WeeklyStats.empty(),
    this.todayNutrition,
    List<Goal> activeGoals = const [],
  }) : activeGoals = List.unmodifiable(activeGoals);

  final TrainingPlan? activePlan;
  final WorkoutSession? activeSession;
  final Workout? todayWorkout;
  final WorkoutSession? lastCompletedSession;
  final WeeklyStats weeklyStats;
  final DailyNutrition? todayNutrition;
  final List<Goal> activeGoals;

  bool get hasActiveSession => activeSession != null;
  bool get hasActivePlan => activePlan != null;
  bool get hasTodayWorkout => todayWorkout != null;
  bool get hasLastCompletedSession => lastCompletedSession != null;
  bool get hasNutrition => todayNutrition != null;
  bool get hasActiveGoals => activeGoals.isNotEmpty;

  DashboardData copyWith({
    TrainingPlan? activePlan,
    WorkoutSession? activeSession,
    Workout? todayWorkout,
    WorkoutSession? lastCompletedSession,
    WeeklyStats? weeklyStats,
    DailyNutrition? todayNutrition,
    List<Goal>? activeGoals,
  }) {
    return DashboardData(
      activePlan: activePlan ?? this.activePlan,
      activeSession: activeSession ?? this.activeSession,
      todayWorkout: todayWorkout ?? this.todayWorkout,
      lastCompletedSession: lastCompletedSession ?? this.lastCompletedSession,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      todayNutrition: todayNutrition ?? this.todayNutrition,
      activeGoals: activeGoals ?? this.activeGoals,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardData &&
        other.activePlan == activePlan &&
        other.activeSession == activeSession &&
        other.todayWorkout == todayWorkout &&
        other.lastCompletedSession == lastCompletedSession &&
        other.weeklyStats == weeklyStats &&
        other.todayNutrition == todayNutrition &&
        listEquals(other.activeGoals, activeGoals);
  }

  @override
  int get hashCode => Object.hash(
        activePlan,
        activeSession,
        todayWorkout,
        lastCompletedSession,
        weeklyStats,
        todayNutrition,
        Object.hashAll(activeGoals),
      );
}
