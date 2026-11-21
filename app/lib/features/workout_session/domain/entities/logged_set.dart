import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';

/// Represents an immediate weight-drop segment within a drop-set.
@immutable
class DropSetEntry {
  const DropSetEntry({
    required this.weightKg,
    required this.repsCompleted,
  });

  final double weightKg;
  final int repsCompleted;

  double get volumeKg => weightKg * repsCompleted;

  DropSetEntry copyWith({
    double? weightKg,
    int? repsCompleted,
  }) {
    return DropSetEntry(
      weightKg: weightKg ?? this.weightKg,
      repsCompleted: repsCompleted ?? this.repsCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weight_kg': weightKg,
      'reps_completed': repsCompleted,
    };
  }

  factory DropSetEntry.fromJson(Map<String, dynamic> json) {
    return DropSetEntry(
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      repsCompleted: (json['reps_completed'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DropSetEntry &&
        other.weightKg == weightKg &&
        other.repsCompleted == repsCompleted;
  }

  @override
  int get hashCode => Object.hash(weightKg, repsCompleted);
}

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
    this.dropSets = const [],
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
  final List<DropSetEntry> dropSets;
  final DateTime? completedAt;

  bool get isWorkingSet =>
      !isWarmup &&
      (setType == SetType.working ||
          setType == SetType.dropSet ||
          setType == SetType.myoRep);

  bool get hasDropSets => dropSets.isNotEmpty;

  String get formattedDropSummary {
    if (dropSets.isEmpty) return '';
    return dropSets.map((d) {
      final w = d.weightKg == d.weightKg.toInt()
          ? d.weightKg.toInt().toString()
          : d.weightKg.toStringAsFixed(1).replaceAll('.', ',');
      return '+${d.repsCompleted}×${w}kg';
    }).join(' ');
  }

  double get volumeKg {
    if (!isWorkingSet) return 0.0;
    final dropsVolume =
        dropSets.fold(0.0, (sum, d) => sum + d.weightKg * d.repsCompleted);
    return (weightKg * repsCompleted) + dropsVolume;
  }

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
    List<DropSetEntry>? dropSets,
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
      dropSets: dropSets ?? this.dropSets,
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
        listEquals(other.dropSets, dropSets) &&
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
        Object.hashAll(dropSets),
        completedAt,
      );
}
