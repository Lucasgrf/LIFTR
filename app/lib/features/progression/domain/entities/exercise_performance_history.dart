import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';

/// Pure Domain Entity representing the aggregated last session performance for a specific exercise.
@immutable
class ExercisePerformanceHistory {
  ExercisePerformanceHistory({
    required this.exerciseId,
    required this.workoutSessionId,
    this.workoutName = '',
    required this.date,
    List<LoggedSet> loggedSets = const [],
  }) : loggedSets = List.unmodifiable(loggedSets);

  final String exerciseId;
  final String workoutSessionId;
  final String workoutName;
  final DateTime date;
  final List<LoggedSet> loggedSets;

  List<LoggedSet> get workingSets =>
      loggedSets.where((s) => s.isWorkingSet).toList();

  double get maxWeightKg {
    final sets = workingSets.isNotEmpty ? workingSets : loggedSets;
    if (sets.isEmpty) return 0.0;
    return sets.map((s) => s.weightKg).reduce(max);
  }

  double get averageWeightKg {
    final sets = workingSets.isNotEmpty ? workingSets : loggedSets;
    if (sets.isEmpty) return 0.0;
    final total = sets.fold(0.0, (sum, s) => sum + s.weightKg);
    return total / sets.length;
  }

  double get totalVolumeKg =>
      loggedSets.fold(0.0, (sum, s) => sum + s.volumeKg);

  int get totalWorkingSetsCount => workingSets.length;

  String get summaryString {
    final sets = workingSets.isNotEmpty ? workingSets : loggedSets;
    if (sets.isEmpty) return 'Nenhum registro anterior';
    final repsList = sets.map((s) => '${s.repsCompleted}').join(', ');
    return '${maxWeightKg.toStringAsFixed(1)} kg × $repsList reps';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExercisePerformanceHistory &&
        other.exerciseId == exerciseId &&
        other.workoutSessionId == workoutSessionId &&
        other.workoutName == workoutName &&
        other.date == date &&
        listEquals(other.loggedSets, loggedSets);
  }

  @override
  int get hashCode => Object.hash(
        exerciseId,
        workoutSessionId,
        workoutName,
        date,
        Object.hashAll(loggedSets),
      );
}
