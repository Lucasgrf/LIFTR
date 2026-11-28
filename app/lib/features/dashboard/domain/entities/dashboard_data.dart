import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/weekly_stats.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

/// Pure Domain Aggregate representing all data needed for the Dashboard ("Hoje") screen.
@immutable
class DashboardData {
  const DashboardData({
    this.activePlan,
    this.activeSession,
    this.todayWorkout,
    this.lastCompletedSession,
    this.weeklyStats = const WeeklyStats.empty(),
    this.weeklySessions = const [],
  });

  final TrainingPlan? activePlan;
  final WorkoutSession? activeSession;
  final Workout? todayWorkout;
  final WorkoutSession? lastCompletedSession;
  final WeeklyStats weeklyStats;
  final List<WorkoutSession> weeklySessions;

  bool get hasActiveSession => activeSession != null;
  bool get hasActivePlan => activePlan != null;
  bool get hasTodayWorkout => todayWorkout != null;
  bool get hasLastCompletedSession => lastCompletedSession != null;

  DashboardData copyWith({
    TrainingPlan? activePlan,
    WorkoutSession? activeSession,
    Workout? todayWorkout,
    WorkoutSession? lastCompletedSession,
    WeeklyStats? weeklyStats,
    List<WorkoutSession>? weeklySessions,
  }) {
    return DashboardData(
      activePlan: activePlan ?? this.activePlan,
      activeSession: activeSession ?? this.activeSession,
      todayWorkout: todayWorkout ?? this.todayWorkout,
      lastCompletedSession: lastCompletedSession ?? this.lastCompletedSession,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      weeklySessions: weeklySessions ?? this.weeklySessions,
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
        listEquals(other.weeklySessions, weeklySessions);
  }

  @override
  int get hashCode => Object.hash(
    activePlan,
    activeSession,
    todayWorkout,
    lastCompletedSession,
    weeklyStats,
    Object.hashAll(weeklySessions),
  );
}
