import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_category.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_checkpoint.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';

/// Pure Domain Entity representing a fitness goal.
@immutable
class Goal {
  Goal({
    required this.id,
    this.userId,
    required this.title,
    this.description,
    required this.category,
    this.referenceExerciseId,
    this.referenceMeasurementType,
    required this.initialValue,
    required this.targetValue,
    double? currentValue,
    this.unit = '',
    required this.startedAt,
    this.deadline,
    this.completedAt,
    this.status = GoalStatus.active,
    List<GoalCheckpoint> checkpoints = const [],
    this.createdAt,
    this.updatedAt,
  })  : currentValue = currentValue ?? initialValue,
        checkpoints = List.unmodifiable(checkpoints);

  final String id;
  final String? userId;
  final String title;
  final String? description;
  final GoalCategory category;
  final String? referenceExerciseId;
  final String? referenceMeasurementType;
  final double initialValue;
  final double targetValue;
  final double currentValue;
  final String unit;
  final DateTime startedAt;
  final DateTime? deadline;
  final DateTime? completedAt;
  final GoalStatus status;
  final List<GoalCheckpoint> checkpoints;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isIncreaseGoal => targetValue >= initialValue;

  bool get isActive => status == GoalStatus.active;
  bool get isCompleted => status == GoalStatus.completed;

  double get progressPercentage {
    if (targetValue == initialValue) {
      return currentValue >= targetValue ? 1.0 : 0.0;
    }

    if (isIncreaseGoal) {
      final totalDelta = targetValue - initialValue;
      final currentDelta = currentValue - initialValue;
      return (currentDelta / totalDelta).clamp(0.0, 1.0);
    } else {
      final totalDelta = initialValue - targetValue;
      final currentDelta = initialValue - currentValue;
      return (currentDelta / totalDelta).clamp(0.0, 1.0);
    }
  }

  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    GoalCategory? category,
    String? referenceExerciseId,
    String? referenceMeasurementType,
    double? initialValue,
    double? targetValue,
    double? currentValue,
    String? unit,
    DateTime? startedAt,
    DateTime? deadline,
    DateTime? completedAt,
    GoalStatus? status,
    List<GoalCheckpoint>? checkpoints,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      referenceExerciseId: referenceExerciseId ?? this.referenceExerciseId,
      referenceMeasurementType:
          referenceMeasurementType ?? this.referenceMeasurementType,
      initialValue: initialValue ?? this.initialValue,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      startedAt: startedAt ?? this.startedAt,
      deadline: deadline ?? this.deadline,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      checkpoints: checkpoints ?? this.checkpoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Goal &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.referenceExerciseId == referenceExerciseId &&
        other.referenceMeasurementType == referenceMeasurementType &&
        other.initialValue == initialValue &&
        other.targetValue == targetValue &&
        other.currentValue == currentValue &&
        other.unit == unit &&
        other.startedAt == startedAt &&
        other.deadline == deadline &&
        other.completedAt == completedAt &&
        other.status == status &&
        listEquals(other.checkpoints, checkpoints);
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        title,
        description,
        category,
        referenceExerciseId,
        referenceMeasurementType,
        initialValue,
        targetValue,
        currentValue,
        unit,
        startedAt,
        deadline,
        completedAt,
        status,
        Object.hashAll(checkpoints),
      );
}
