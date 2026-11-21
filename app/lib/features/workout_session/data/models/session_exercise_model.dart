import 'package:personal_fitness_os/features/exercise_library/data/models/exercise_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/logged_set_model.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';

/// DTO for `workout_session_exercises` table in Supabase.
class SessionExerciseModel {
  const SessionExerciseModel({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    this.sortOrder = 0,
    this.notes,
    this.replacedExerciseId,
    this.exercise,
    this.sets = const [],
    this.targetRestSeconds = 120,
    this.targetSetsCount = 3,
    this.createdAt,
  });

  final String id;
  final String sessionId;
  final String exerciseId;
  final int sortOrder;
  final String? notes;
  final String? replacedExerciseId;
  final ExerciseModel? exercise;
  final List<LoggedSetModel> sets;
  final int targetRestSeconds;
  final int targetSetsCount;
  final DateTime? createdAt;

  factory SessionExerciseModel.fromJson(Map<String, dynamic> json) {
    return SessionExerciseModel(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      exerciseId: json['exercise_id'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      notes: json['notes'] as String?,
      replacedExerciseId: json['replaced_exercise_id'] as String?,
      exercise: json['exercises'] != null
          ? ExerciseModel.fromJson(json['exercises'] as Map<String, dynamic>)
          : null,
      sets: (json['logged_sets'] as List<dynamic>?)
              ?.map((e) => LoggedSetModel.fromJson(e as Map<String, dynamic>))
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
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'sort_order': sortOrder,
      if (notes != null) 'notes': notes,
      if (replacedExerciseId != null) 'replaced_exercise_id': replacedExerciseId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  SessionExercise toDomain() {
    final sortedSets = [...sets]
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

    return SessionExercise(
      id: id,
      sessionId: sessionId,
      exerciseId: exerciseId,
      sortOrder: sortOrder,
      notes: notes,
      replacedExerciseId: replacedExerciseId,
      exercise: exercise?.toDomain(),
      sets: sortedSets.map((s) => s.toDomain()).toList(),
      targetRestSeconds: targetRestSeconds,
      targetSetsCount: targetSetsCount,
      createdAt: createdAt,
    );
  }

  factory SessionExerciseModel.fromDomain(SessionExercise entity) {
    return SessionExerciseModel(
      id: entity.id,
      sessionId: entity.sessionId,
      exerciseId: entity.exerciseId,
      sortOrder: entity.sortOrder,
      notes: entity.notes,
      replacedExerciseId: entity.replacedExerciseId,
      exercise: entity.exercise != null
          ? ExerciseModel.fromDomain(entity.exercise!)
          : null,
      sets: entity.sets.map((s) => LoggedSetModel.fromDomain(s)).toList(),
      targetRestSeconds: entity.targetRestSeconds,
      targetSetsCount: entity.targetSetsCount,
      createdAt: entity.createdAt,
    );
  }

  SessionExerciseModel copyWith({
    String? id,
    String? sessionId,
    String? exerciseId,
    int? sortOrder,
    String? notes,
    String? replacedExerciseId,
    ExerciseModel? exercise,
    List<LoggedSetModel>? sets,
    int? targetRestSeconds,
    int? targetSetsCount,
    DateTime? createdAt,
  }) {
    return SessionExerciseModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      sortOrder: sortOrder ?? this.sortOrder,
      notes: notes ?? this.notes,
      replacedExerciseId: replacedExerciseId ?? this.replacedExerciseId,
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      targetRestSeconds: targetRestSeconds ?? this.targetRestSeconds,
      targetSetsCount: targetSetsCount ?? this.targetSetsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
