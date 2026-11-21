import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';

/// Pure Domain Entity representing a workout session within a training plan.
@immutable
class Workout {
  const Workout({
    required this.id,
    required this.trainingPlanId,
    required this.name,
    this.dayOfWeek,
    this.sortOrder = 0,
    this.notes,
    this.estimatedDurationMinutes,
    this.exercises = const [],
    this.createdAt,
  });

  final String id;
  final String trainingPlanId;
  final String name;
  final int? dayOfWeek; // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
  final int sortOrder;
  final String? notes;
  final int? estimatedDurationMinutes;
  final List<WorkoutExercise> exercises;
  final DateTime? createdAt;

  int get totalExercisesCount => exercises.length;

  int get totalWorkingSetsCount =>
      exercises.fold(0, (sum, e) => sum + e.workingSetsCount);

  String get dayOfWeekLabel {
    if (dayOfWeek == null) return 'Dia livre';
    switch (dayOfWeek) {
      case 0:
        return 'Domingo';
      case 1:
        return 'Segunda-feira';
      case 2:
        return 'Terça-feira';
      case 3:
        return 'Quarta-feira';
      case 4:
        return 'Quinta-feira';
      case 5:
        return 'Sexta-feira';
      case 6:
        return 'Sábado';
      default:
        return 'Dia $dayOfWeek';
    }
  }

  Workout copyWith({
    String? id,
    String? trainingPlanId,
    String? name,
    int? dayOfWeek,
    int? sortOrder,
    String? notes,
    int? estimatedDurationMinutes,
    List<WorkoutExercise>? exercises,
    DateTime? createdAt,
  }) {
    return Workout(
      id: id ?? this.id,
      trainingPlanId: trainingPlanId ?? this.trainingPlanId,
      name: name ?? this.name,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      sortOrder: sortOrder ?? this.sortOrder,
      notes: notes ?? this.notes,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Workout &&
        other.id == id &&
        other.trainingPlanId == trainingPlanId &&
        other.name == name &&
        other.dayOfWeek == dayOfWeek &&
        other.sortOrder == sortOrder &&
        other.notes == notes &&
        other.estimatedDurationMinutes == estimatedDurationMinutes &&
        listEquals(other.exercises, exercises);
  }

  @override
  int get hashCode => Object.hash(
        id,
        trainingPlanId,
        name,
        dayOfWeek,
        sortOrder,
        notes,
        estimatedDurationMinutes,
        Object.hashAll(exercises),
      );
}
