import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';

/// Pure Domain Entity representing an actual set performed during a workout session.
@immutable
class LoggedSet {
  const LoggedSet({
    required this.id,
    required this.sessionExerciseId,
    required this.setNumber,
    this.setType = SetType.working,
    required this.weightKg,
    required this.repsCompleted,
    this.rirActual,
    this.rpeActual,
    this.restSecondsActual,
    this.executionQuality,
    this.isWarmup = false,
    this.notes,
    this.completedAt,
  });

  final String id;
  final String sessionExerciseId;
  final int setNumber;
  final SetType setType;
  final double weightKg;
  final int repsCompleted;
  final int? rirActual;
  final double? rpeActual;
  final int? restSecondsActual;
  final ExecutionQuality? executionQuality;
  final bool isWarmup;
  final String? notes;
  final DateTime? completedAt;

  bool get isWorkingSet => !isWarmup && (setType == SetType.working || setType == SetType.dropSet || setType == SetType.myoRep);

  double get volumeKg => isWorkingSet ? weightKg * repsCompleted : 0.0;

  LoggedSet copyWith({
    String? id,
    String? sessionExerciseId,
    int? setNumber,
    SetType? setType,
    double? weightKg,
    int? repsCompleted,
    int? rirActual,
    double? rpeActual,
    int? restSecondsActual,
    ExecutionQuality? executionQuality,
    bool? isWarmup,
    String? notes,
    DateTime? completedAt,
  }) {
    return LoggedSet(
      id: id ?? this.id,
      sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
      setNumber: setNumber ?? this.setNumber,
      setType: setType ?? this.setType,
      weightKg: weightKg ?? this.weightKg,
      repsCompleted: repsCompleted ?? this.repsCompleted,
      rirActual: rirActual ?? this.rirActual,
      rpeActual: rpeActual ?? this.rpeActual,
      restSecondsActual: restSecondsActual ?? this.restSecondsActual,
      executionQuality: executionQuality ?? this.executionQuality,
      isWarmup: isWarmup ?? this.isWarmup,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoggedSet &&
        other.id == id &&
        other.sessionExerciseId == sessionExerciseId &&
        other.setNumber == setNumber &&
        other.setType == setType &&
        other.weightKg == weightKg &&
        other.repsCompleted == repsCompleted &&
        other.rirActual == rirActual &&
        other.rpeActual == rpeActual &&
        other.restSecondsActual == restSecondsActual &&
        other.executionQuality == executionQuality &&
        other.isWarmup == isWarmup &&
        other.notes == notes &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        sessionExerciseId,
        setNumber,
        setType,
        weightKg,
        repsCompleted,
        rirActual,
        rpeActual,
        restSecondsActual,
        executionQuality,
        isWarmup,
        notes,
        completedAt,
      );
}
