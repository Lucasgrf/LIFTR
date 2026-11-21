import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';

/// Pure Domain Entity representing a set template in a workout exercise.
@immutable
class SetTemplate {
  const SetTemplate({
    required this.id,
    required this.workoutExerciseId,
    required this.setNumber,
    this.setType = SetType.working,
    this.targetRepsMin,
    this.targetRepsMax,
    this.targetRirMin,
    this.targetRirMax,
    this.targetWeight,
    this.restSeconds = 120,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String workoutExerciseId;
  final int setNumber;
  final SetType setType;
  final int? targetRepsMin;
  final int? targetRepsMax;
  final int? targetRirMin;
  final int? targetRirMax;
  final double? targetWeight;
  final int restSeconds;
  final String? notes;
  final DateTime? createdAt;

  bool get isWorkingSet => setType == SetType.working;

  String get repRangeText {
    if (targetRepsMin != null && targetRepsMax != null) {
      if (targetRepsMin == targetRepsMax) return '$targetRepsMin';
      return '$targetRepsMin-$targetRepsMax';
    }
    if (targetRepsMin != null) return '$targetRepsMin+';
    if (targetRepsMax != null) return 'até $targetRepsMax';
    return '-';
  }

  String get rirRangeText {
    if (targetRirMin != null && targetRirMax != null) {
      if (targetRirMin == targetRirMax) return '$targetRirMin';
      return '$targetRirMin-$targetRirMax';
    }
    if (targetRirMin != null) return '$targetRirMin+';
    return '-';
  }

  SetTemplate copyWith({
    String? id,
    String? workoutExerciseId,
    int? setNumber,
    SetType? setType,
    int? targetRepsMin,
    int? targetRepsMax,
    int? targetRirMin,
    int? targetRirMax,
    double? targetWeight,
    int? restSeconds,
    String? notes,
    DateTime? createdAt,
  }) {
    return SetTemplate(
      id: id ?? this.id,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      setNumber: setNumber ?? this.setNumber,
      setType: setType ?? this.setType,
      targetRepsMin: targetRepsMin ?? this.targetRepsMin,
      targetRepsMax: targetRepsMax ?? this.targetRepsMax,
      targetRirMin: targetRirMin ?? this.targetRirMin,
      targetRirMax: targetRirMax ?? this.targetRirMax,
      targetWeight: targetWeight ?? this.targetWeight,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SetTemplate &&
        other.id == id &&
        other.workoutExerciseId == workoutExerciseId &&
        other.setNumber == setNumber &&
        other.setType == setType &&
        other.targetRepsMin == targetRepsMin &&
        other.targetRepsMax == targetRepsMax &&
        other.targetRirMin == targetRirMin &&
        other.targetRirMax == targetRirMax &&
        other.targetWeight == targetWeight &&
        other.restSeconds == restSeconds &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
        id,
        workoutExerciseId,
        setNumber,
        setType,
        targetRepsMin,
        targetRepsMax,
        targetRirMin,
        targetRirMax,
        targetWeight,
        restSeconds,
        notes,
      );
}
