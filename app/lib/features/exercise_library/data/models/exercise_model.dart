import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';

/// Data Transfer Object representing an exercise row in PostgreSQL / Supabase.
class ExerciseModel {
  const ExerciseModel({
    required this.id,
    required this.name,
    required this.primaryMuscleGroup,
    this.userId,
    this.secondaryMuscles = const [],
    this.equipment,
    this.movementPattern,
    this.instructions,
    this.commonMistakes,
    this.videoUrl,
    this.personalNotes,
    this.isCustom = false,
    this.createdAt,
    this.deletedAt,
  });

  final String id;
  final String? userId;
  final String name;
  final String primaryMuscleGroup;
  final List<String> secondaryMuscles;
  final String? equipment;
  final String? movementPattern;
  final String? instructions;
  final String? commonMistakes;
  final String? videoUrl;
  final String? personalNotes;
  final bool isCustom;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      primaryMuscleGroup: json['primary_muscle_group'] as String,
      secondaryMuscles: (json['secondary_muscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      equipment: json['equipment'] as String?,
      movementPattern: json['movement_pattern'] as String?,
      instructions: json['instructions'] as String?,
      commonMistakes: json['common_mistakes'] as String?,
      videoUrl: json['video_url'] as String?,
      personalNotes: json['personal_notes'] as String?,
      isCustom: json['is_custom'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'primary_muscle_group': primaryMuscleGroup,
      'secondary_muscles': secondaryMuscles,
      if (equipment != null) 'equipment': equipment,
      if (movementPattern != null) 'movement_pattern': movementPattern,
      if (instructions != null) 'instructions': instructions,
      if (commonMistakes != null) 'common_mistakes': commonMistakes,
      if (videoUrl != null) 'video_url': videoUrl,
      if (personalNotes != null) 'personal_notes': personalNotes,
      'is_custom': isCustom,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  Exercise toDomain() {
    return Exercise(
      id: id,
      userId: userId,
      name: name,
      primaryMuscleGroup: primaryMuscleGroup,
      secondaryMuscles: secondaryMuscles,
      equipment: equipment,
      movementPattern: movementPattern,
      instructions: instructions,
      commonMistakes: commonMistakes,
      videoUrl: videoUrl,
      personalNotes: personalNotes,
      isCustom: isCustom,
      createdAt: createdAt,
      deletedAt: deletedAt,
    );
  }

  factory ExerciseModel.fromDomain(Exercise exercise) {
    return ExerciseModel(
      id: exercise.id,
      userId: exercise.userId,
      name: exercise.name,
      primaryMuscleGroup: exercise.primaryMuscleGroup,
      secondaryMuscles: exercise.secondaryMuscles,
      equipment: exercise.equipment,
      movementPattern: exercise.movementPattern,
      instructions: exercise.instructions,
      commonMistakes: exercise.commonMistakes,
      videoUrl: exercise.videoUrl,
      personalNotes: exercise.personalNotes,
      isCustom: exercise.isCustom,
      createdAt: exercise.createdAt,
      deletedAt: exercise.deletedAt,
    );
  }
}
