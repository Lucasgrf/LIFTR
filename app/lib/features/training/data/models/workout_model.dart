import 'package:personal_fitness_os/features/training/data/models/workout_exercise_model.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';

/// DTO for `workouts` table in Supabase.
class WorkoutModel {
  const WorkoutModel({
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
  final int? dayOfWeek;
  final int sortOrder;
  final String? notes;
  final int? estimatedDurationMinutes;
  final List<WorkoutExerciseModel> exercises;
  final DateTime? createdAt;

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    return WorkoutModel(
      id: json['id'] as String,
      trainingPlanId: json['training_plan_id'] as String,
      name: json['name'] as String,
      dayOfWeek: json['day_of_week'] as int?,
      sortOrder: json['sort_order'] as int? ?? 0,
      notes: json['notes'] as String?,
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int?,
      exercises: (json['workout_exercises'] as List<dynamic>?)
              ?.map((e) =>
                  WorkoutExerciseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'training_plan_id': trainingPlanId,
      'name': name,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      'sort_order': sortOrder,
      if (notes != null) 'notes': notes,
      if (estimatedDurationMinutes != null)
        'estimated_duration_minutes': estimatedDurationMinutes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Workout toDomain() {
    final sortedExercises = [...exercises]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Workout(
      id: id,
      trainingPlanId: trainingPlanId,
      name: name,
      dayOfWeek: dayOfWeek,
      sortOrder: sortOrder,
      notes: notes,
      estimatedDurationMinutes: estimatedDurationMinutes,
      exercises: sortedExercises.map((e) => e.toDomain()).toList(),
      createdAt: createdAt,
    );
  }

  factory WorkoutModel.fromDomain(Workout entity) {
    return WorkoutModel(
      id: entity.id,
      trainingPlanId: entity.trainingPlanId,
      name: entity.name,
      dayOfWeek: entity.dayOfWeek,
      sortOrder: entity.sortOrder,
      notes: entity.notes,
      estimatedDurationMinutes: entity.estimatedDurationMinutes,
      exercises: entity.exercises
          .map((e) => WorkoutExerciseModel.fromDomain(e))
          .toList(),
      createdAt: entity.createdAt,
    );
  }
}
