import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/features/exercise_library/data/models/exercise_model.dart';
import 'package:personal_fitness_os/features/training/data/models/set_template_model.dart';
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
    this.targetRestSeconds = AppConstants.defaultRestSeconds,
    this.targetSetsCount = 3,
    this.targetRepsMin = 8,
    this.targetRepsMax = 12,
    this.targetRir = 2,
    this.prescribedSetTypes = const [],
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
  final int targetRepsMin;
  final int targetRepsMax;
  final int targetRir;
  final List<SetType> prescribedSetTypes;
  final DateTime? createdAt;

  factory SessionExerciseModel.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? workoutExerciseJson,
  }) {
    final templatesRaw =
        workoutExerciseJson?['set_templates'] as List<dynamic>?;
    final templates = templatesRaw
            ?.whereType<Map<String, dynamic>>()
            .map(SetTemplateModel.fromJson)
            .toList() ??
        const <SetTemplateModel>[];
    final sortedTemplates = [...templates]
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

    final workingTemplates = sortedTemplates
        .where((t) =>
            SetTemplateModel.parseSetType(t.setType) == SetType.working ||
            SetTemplateModel.parseSetType(t.setType) == SetType.dropSet ||
            SetTemplateModel.parseSetType(t.setType) == SetType.myoRep)
        .toList();
    final primaryTemplate =
        workingTemplates.firstOrNull ?? sortedTemplates.firstOrNull;

    final int resolvedTargetSetsCount;
    if (json['target_sets_count'] != null) {
      resolvedTargetSetsCount = (json['target_sets_count'] as num).toInt();
    } else if (workingTemplates.isNotEmpty) {
      resolvedTargetSetsCount = workingTemplates.length;
    } else if (sortedTemplates.isNotEmpty) {
      resolvedTargetSetsCount = sortedTemplates.length;
    } else {
      resolvedTargetSetsCount = 3;
    }

    final int resolvedRestSeconds;
    if (json['target_rest_seconds'] != null) {
      resolvedRestSeconds = (json['target_rest_seconds'] as num).toInt();
    } else if (primaryTemplate != null && primaryTemplate.restSeconds > 0) {
      resolvedRestSeconds = primaryTemplate.restSeconds;
    } else {
      resolvedRestSeconds = AppConstants.defaultRestSeconds;
    }

    final resolvedRepsMin = (json['target_reps_min'] as num?)?.toInt() ??
        primaryTemplate?.targetRepsMin ??
        8;
    final resolvedRepsMax = (json['target_reps_max'] as num?)?.toInt() ??
        primaryTemplate?.targetRepsMax ??
        12;
    final resolvedRir = (json['target_rir'] as num?)?.toInt() ??
        primaryTemplate?.targetRirMin ??
        2;

    final List<SetType> resolvedPrescribedTypes;
    if (json['prescribed_set_types'] is List) {
      resolvedPrescribedTypes = (json['prescribed_set_types'] as List<dynamic>)
          .map((e) => LoggedSetModel.parseSetType(e.toString()))
          .toList();
    } else if (sortedTemplates.isNotEmpty) {
      resolvedPrescribedTypes = sortedTemplates
          .map((t) => SetTemplateModel.parseSetType(t.setType))
          .toList();
    } else {
      resolvedPrescribedTypes = const [];
    }

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
      targetRestSeconds: resolvedRestSeconds,
      targetSetsCount: resolvedTargetSetsCount,
      targetRepsMin: resolvedRepsMin,
      targetRepsMax: resolvedRepsMax,
      targetRir: resolvedRir,
      prescribedSetTypes: resolvedPrescribedTypes,
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

  Map<String, dynamic> toFullJson() {
    return {
      ...toJson(),
      'target_rest_seconds': targetRestSeconds,
      'target_sets_count': targetSetsCount,
      'target_reps_min': targetRepsMin,
      'target_reps_max': targetRepsMax,
      'target_rir': targetRir,
      if (prescribedSetTypes.isNotEmpty)
        'prescribed_set_types':
            prescribedSetTypes.map(LoggedSetModel.setTypeToString).toList(),
      if (exercise != null) 'exercises': exercise!.toJson(),
      'logged_sets': sets.map((s) => s.toJson()).toList(),
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
      targetRepsMin: targetRepsMin,
      targetRepsMax: targetRepsMax,
      targetRir: targetRir,
      prescribedSetTypes: prescribedSetTypes,
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
      targetRepsMin: entity.targetRepsMin,
      targetRepsMax: entity.targetRepsMax,
      targetRir: entity.targetRir,
      prescribedSetTypes: entity.prescribedSetTypes,
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
    int? targetRepsMin,
    int? targetRepsMax,
    int? targetRir,
    List<SetType>? prescribedSetTypes,
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
      targetRepsMin: targetRepsMin ?? this.targetRepsMin,
      targetRepsMax: targetRepsMax ?? this.targetRepsMax,
      targetRir: targetRir ?? this.targetRir,
      prescribedSetTypes: prescribedSetTypes ?? this.prescribedSetTypes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
