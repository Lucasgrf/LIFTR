import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';

/// Pure Domain Entity representing an exercise within a specific workout.
@immutable
class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    this.sortOrder = 0,
    this.notes,
    this.replacedExerciseId,
    this.replacedAt,
    this.exercise,
    this.setTemplates = const [],
    this.createdAt,
  });

  final String id;
  final String workoutId;
  final String exerciseId;
  final int sortOrder;
  final String? notes;
  final String? replacedExerciseId;
  final DateTime? replacedAt;
  final Exercise? exercise;
  final List<SetTemplate> setTemplates;
  final DateTime? createdAt;

  int get workingSetsCount =>
      setTemplates.where((s) => s.isWorkingSet).length;

  int get totalSetsCount => setTemplates.length;

  WorkoutExercise copyWith({
    String? id,
    String? workoutId,
    String? exerciseId,
    int? sortOrder,
    String? notes,
    String? replacedExerciseId,
    DateTime? replacedAt,
    Exercise? exercise,
    List<SetTemplate>? setTemplates,
    DateTime? createdAt,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      sortOrder: sortOrder ?? this.sortOrder,
      notes: notes ?? this.notes,
      replacedExerciseId: replacedExerciseId ?? this.replacedExerciseId,
      replacedAt: replacedAt ?? this.replacedAt,
      exercise: exercise ?? this.exercise,
      setTemplates: setTemplates ?? this.setTemplates,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutExercise &&
        other.id == id &&
        other.workoutId == workoutId &&
        other.exerciseId == exerciseId &&
        other.sortOrder == sortOrder &&
        other.notes == notes &&
        other.replacedExerciseId == replacedExerciseId &&
        other.replacedAt == replacedAt &&
        other.exercise == exercise &&
        listEquals(other.setTemplates, setTemplates);
  }

  @override
  int get hashCode => Object.hash(
        id,
        workoutId,
        exerciseId,
        sortOrder,
        notes,
        replacedExerciseId,
        replacedAt,
        exercise,
        Object.hashAll(setTemplates),
      );
}
