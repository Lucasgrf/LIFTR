import 'package:personal_fitness_os/features/exercise_library/data/models/exercise_model.dart';
import 'package:personal_fitness_os/features/training/data/models/set_template_model.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';

/// DTO for `workout_exercises` table in Supabase.
class WorkoutExerciseModel {
  const WorkoutExerciseModel({
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
  final ExerciseModel? exercise;
  final List<SetTemplateModel> setTemplates;
  final DateTime? createdAt;

  factory WorkoutExerciseModel.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseModel(
      id: json['id'] as String,
      workoutId: json['workout_id'] as String,
      exerciseId: json['exercise_id'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      notes: json['notes'] as String?,
      replacedExerciseId: json['replaced_exercise_id'] as String?,
      replacedAt: json['replaced_at'] != null
          ? DateTime.tryParse(json['replaced_at'] as String)
          : null,
      exercise: json['exercises'] != null
          ? ExerciseModel.fromJson(json['exercises'] as Map<String, dynamic>)
          : null,
      setTemplates: (json['set_templates'] as List<dynamic>?)
              ?.map((e) => SetTemplateModel.fromJson(e as Map<String, dynamic>))
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
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'sort_order': sortOrder,
      if (notes != null) 'notes': notes,
      if (replacedExerciseId != null) 'replaced_exercise_id': replacedExerciseId,
      if (replacedAt != null) 'replaced_at': replacedAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toFullJson() {
    return {
      ...toJson(),
      if (exercise != null) 'exercises': exercise!.toJson(),
      'set_templates': setTemplates.map((s) => s.toJson()).toList(),
    };
  }

  WorkoutExercise toDomain() {
    final sortedSets = [...setTemplates]
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

    return WorkoutExercise(
      id: id,
      workoutId: workoutId,
      exerciseId: exerciseId,
      sortOrder: sortOrder,
      notes: notes,
      replacedExerciseId: replacedExerciseId,
      replacedAt: replacedAt,
      exercise: exercise?.toDomain(),
      setTemplates: sortedSets.map((s) => s.toDomain()).toList(),
      createdAt: createdAt,
    );
  }

  factory WorkoutExerciseModel.fromDomain(WorkoutExercise entity) {
    return WorkoutExerciseModel(
      id: entity.id,
      workoutId: entity.workoutId,
      exerciseId: entity.exerciseId,
      sortOrder: entity.sortOrder,
      notes: entity.notes,
      replacedExerciseId: entity.replacedExerciseId,
      replacedAt: entity.replacedAt,
      exercise: entity.exercise != null
          ? ExerciseModel.fromDomain(entity.exercise!)
          : null,
      setTemplates: entity.setTemplates
          .map((s) => SetTemplateModel.fromDomain(s))
          .toList(),
      createdAt: entity.createdAt,
    );
  }
}
