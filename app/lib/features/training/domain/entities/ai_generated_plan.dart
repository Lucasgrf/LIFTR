import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';

/// Represents a single set template specification inside a generated or shared plan.
@immutable
class GeneratedSetSpec {
  const GeneratedSetSpec({
    this.setType = SetType.working,
    this.targetRepsMin,
    this.targetRepsMax,
    this.targetRirMin,
    this.targetRirMax,
    this.targetWeight,
    this.restSeconds = AppConstants.defaultRestSeconds,
    this.notes,
  });

  final SetType setType;
  final int? targetRepsMin;
  final int? targetRepsMax;
  final int? targetRirMin;
  final int? targetRirMax;
  final double? targetWeight;
  final int restSeconds;
  final String? notes;

  static SetType parseSetType(String? raw) {
    switch (raw) {
      case 'mobility':
        return SetType.mobility;
      case 'warmup':
        return SetType.warmup;
      case 'ramp_up':
        return SetType.rampUp;
      case 'drop_set':
        return SetType.dropSet;
      case 'myo_rep':
        return SetType.myoRep;
      default:
        return SetType.working;
    }
  }

  static String setTypeToWire(SetType type) {
    switch (type) {
      case SetType.mobility:
        return 'mobility';
      case SetType.warmup:
        return 'warmup';
      case SetType.rampUp:
        return 'ramp_up';
      case SetType.working:
        return 'working';
      case SetType.dropSet:
        return 'drop_set';
      case SetType.myoRep:
        return 'myo_rep';
    }
  }

  Map<String, dynamic> toJson() => {
        't': setTypeToWire(setType),
        if (targetRepsMin != null) 'rmin': targetRepsMin,
        if (targetRepsMax != null) 'rmax': targetRepsMax,
        if (targetRirMin != null) 'imin': targetRirMin,
        if (targetRirMax != null) 'imax': targetRirMax,
        if (targetWeight != null) 'w': targetWeight,
        'rest': restSeconds,
        if (notes != null && notes!.isNotEmpty) 'n': notes,
      };

  factory GeneratedSetSpec.fromJson(Map<String, dynamic> json) {
    return GeneratedSetSpec(
      setType: parseSetType(json['t'] as String?),
      targetRepsMin: (json['rmin'] as num?)?.toInt(),
      targetRepsMax: (json['rmax'] as num?)?.toInt(),
      targetRirMin: (json['imin'] as num?)?.toInt(),
      targetRirMax: (json['imax'] as num?)?.toInt(),
      targetWeight: (json['w'] as num?)?.toDouble(),
      restSeconds:
          (json['rest'] as num?)?.toInt() ?? AppConstants.defaultRestSeconds,
      notes: json['n'] as String?,
    );
  }
}

/// Represents an exercise prescription inside a generated or imported workout.
@immutable
class GeneratedExerciseSpec {
  const GeneratedExerciseSpec({
    this.exerciseId,
    required this.exerciseName,
    this.primaryMuscleGroup,
    this.equipment,
    this.movementPattern,
    this.isCardio = false,
    this.setsCount = 3,
    this.targetRepsMin,
    this.targetRepsMax,
    this.targetDurationMinutes,
    this.targetRirMin,
    this.targetRirMax,
    this.restSeconds = AppConstants.defaultRestSeconds,
    this.notes,
    this.exactSets,
  });

  final String? exerciseId;
  final String exerciseName;
  final String? primaryMuscleGroup;
  final String? equipment;
  final String? movementPattern;
  final bool isCardio;
  final int setsCount;
  final int? targetRepsMin;
  final int? targetRepsMax;
  final int? targetDurationMinutes;
  final int? targetRirMin;
  final int? targetRirMax;
  final int restSeconds;
  final String? notes;
  final List<GeneratedSetSpec>? exactSets;

  String get prescriptionSummary {
    if (isCardio) {
      final min = targetDurationMinutes ?? 15;
      return '$min min · Cardio';
    }
    final count = exactSets?.length ?? setsCount;
    if (targetRepsMin != null && targetRepsMax != null) {
      final reps = targetRepsMin == targetRepsMax
          ? '$targetRepsMin'
          : '$targetRepsMin-$targetRepsMax';
      return '$count × $reps reps';
    }
    return '$count séries';
  }

  factory GeneratedExerciseSpec.fromJson(Map<String, dynamic> json) {
    final exactRaw = json['exact_sets'] as List<dynamic>?;
    final exactSets = exactRaw
        ?.map((item) => GeneratedSetSpec.fromJson(item as Map<String, dynamic>))
        .toList();
    final isCardio = (json['is_cardio'] as bool?) ??
        (json['movement_pattern'] == 'cardio') ||
        (json['primary_muscle_group'] == 'cardio');

    return GeneratedExerciseSpec(
      exerciseId: json['exercise_id'] as String?,
      exerciseName: (json['exercise_name'] as String? ?? 'Exercício').trim(),
      primaryMuscleGroup: json['primary_muscle_group'] as String?,
      equipment: json['equipment'] as String?,
      movementPattern: json['movement_pattern'] as String?,
      isCardio: isCardio,
      setsCount:
          exactSets?.length ?? (json['sets_count'] as num?)?.toInt() ?? 3,
      targetRepsMin: (json['target_reps_min'] as num?)?.toInt(),
      targetRepsMax: (json['target_reps_max'] as num?)?.toInt(),
      targetDurationMinutes:
          (json['target_duration_minutes'] as num?)?.toInt(),
      targetRirMin: (json['target_rir_min'] as num?)?.toInt(),
      targetRirMax: (json['target_rir_max'] as num?)?.toInt(),
      restSeconds: (json['rest_seconds'] as num?)?.toInt() ??
          (isCardio ? 0 : AppConstants.defaultRestSeconds),
      notes: json['notes'] as String?,
      exactSets: exactSets,
    );
  }

  Map<String, dynamic> toJson() => {
        if (exerciseId != null) 'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        if (primaryMuscleGroup != null)
          'primary_muscle_group': primaryMuscleGroup,
        if (equipment != null) 'equipment': equipment,
        if (movementPattern != null) 'movement_pattern': movementPattern,
        'is_cardio': isCardio,
        'sets_count': setsCount,
        'target_reps_min': targetRepsMin,
        'target_reps_max': targetRepsMax,
        'target_duration_minutes': targetDurationMinutes,
        'target_rir_min': targetRirMin,
        'target_rir_max': targetRirMax,
        'rest_seconds': restSeconds,
        if (notes != null) 'notes': notes,
        if (exactSets != null)
          'exact_sets': exactSets!.map((s) => s.toJson()).toList(),
      };
}

/// Represents a single workout day inside a generated or imported plan.
@immutable
class GeneratedWorkoutSpec {
  const GeneratedWorkoutSpec({
    required this.name,
    this.dayOfWeek,
    this.estimatedDurationMinutes = 55,
    this.notes,
    this.exercises = const [],
  });

  final String name;
  final int? dayOfWeek;
  final int estimatedDurationMinutes;
  final String? notes;
  final List<GeneratedExerciseSpec> exercises;

  int get workingSetsCount => exercises.fold(
        0,
        (sum, ex) => sum + (ex.isCardio ? 0 : ex.setsCount),
      );

  factory GeneratedWorkoutSpec.fromJson(Map<String, dynamic> json) {
    final exList = (json['exercises'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              GeneratedExerciseSpec.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    return GeneratedWorkoutSpec(
      name: (json['name'] as String? ?? 'Sessão').trim(),
      dayOfWeek: (json['day_of_week'] as num?)?.toInt(),
      estimatedDurationMinutes:
          (json['estimated_duration_minutes'] as num?)?.toInt() ?? 55,
      notes: json['notes'] as String?,
      exercises: exList,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'day_of_week': dayOfWeek,
        'estimated_duration_minutes': estimatedDurationMinutes,
        if (notes != null) 'notes': notes,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}

/// Draft training plan produced either by Gemini AI or by decoding a share code.
@immutable
class GeneratedTrainingPlan {
  const GeneratedTrainingPlan({
    required this.planName,
    required this.splitType,
    this.description,
    this.rationale,
    this.workouts = const [],
  });

  final String planName;
  final String splitType;
  final String? description;
  final String? rationale;
  final List<GeneratedWorkoutSpec> workouts;

  int get totalWorkoutsCount => workouts.length;

  int get totalExercisesCount =>
      workouts.fold(0, (sum, w) => sum + w.exercises.length);

  int get totalWorkingSetsCount =>
      workouts.fold(0, (sum, w) => sum + w.workingSetsCount);

  factory GeneratedTrainingPlan.fromJson(Map<String, dynamic> json) {
    final rawWorkouts = (json['workouts'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              GeneratedWorkoutSpec.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    return GeneratedTrainingPlan(
      planName: (json['plan_name'] as String? ?? 'Programa LIFTR').trim(),
      splitType: (json['split_type'] as String? ?? 'Personalizado').trim(),
      description: json['description'] as String?,
      rationale: json['rationale'] as String?,
      workouts: rawWorkouts,
    );
  }

  Map<String, dynamic> toJson() => {
        'plan_name': planName,
        'split_type': splitType,
        if (description != null) 'description': description,
        if (rationale != null) 'rationale': rationale,
        'workouts': workouts.map((w) => w.toJson()).toList(),
      };
}
