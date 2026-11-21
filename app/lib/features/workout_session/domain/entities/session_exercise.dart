import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';

/// Pure Domain Entity representing an exercise performed during a live workout session.
@immutable
class SessionExercise {
  const SessionExercise({
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
  final Exercise? exercise;
  final List<LoggedSet> sets;
  final int targetRestSeconds;
  final int targetSetsCount;
  final int targetRepsMin;
  final int targetRepsMax;
  final int targetRir;
  final List<SetType> prescribedSetTypes;
  final DateTime? createdAt;

  int get completedSetsCount => sets.length;

  int get completedWorkingSetsCount =>
      sets.where((s) => s.isWorkingSet).length;

  double get totalVolumeKg =>
      sets.fold(0.0, (sum, set) => sum + set.volumeKg);

  SessionExercise copyWith({
    String? id,
    String? sessionId,
    String? exerciseId,
    int? sortOrder,
    String? notes,
    String? replacedExerciseId,
    Exercise? exercise,
    List<LoggedSet>? sets,
    int? targetRestSeconds,
    int? targetSetsCount,
    int? targetRepsMin,
    int? targetRepsMax,
    int? targetRir,
    List<SetType>? prescribedSetTypes,
    DateTime? createdAt,
  }) {
    return SessionExercise(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionExercise &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.exerciseId == exerciseId &&
        other.sortOrder == sortOrder &&
        other.notes == notes &&
        other.replacedExerciseId == replacedExerciseId &&
        other.exercise == exercise &&
        listEquals(other.sets, sets) &&
        other.targetRestSeconds == targetRestSeconds &&
        other.targetSetsCount == targetSetsCount &&
        other.targetRepsMin == targetRepsMin &&
        other.targetRepsMax == targetRepsMax &&
        other.targetRir == targetRir &&
        listEquals(other.prescribedSetTypes, prescribedSetTypes);
  }

  @override
  int get hashCode => Object.hash(
        id,
        sessionId,
        exerciseId,
        sortOrder,
        notes,
        replacedExerciseId,
        exercise,
        Object.hashAll(sets),
        targetRestSeconds,
        targetSetsCount,
        targetRepsMin,
        targetRepsMax,
        targetRir,
        Object.hashAll(prescribedSetTypes),
      );
}
