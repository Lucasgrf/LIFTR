import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';

/// Pure Domain Entity representing a periodic training plan / split.
@immutable
class TrainingPlan {
  const TrainingPlan({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.isActive = false,
    this.startDate,
    this.endDate,
    this.workouts = const [],
    this.createdAt,
    this.deletedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<Workout> workouts;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  int get totalWorkoutsCount => workouts.length;

  int get totalWeeklySetsCount =>
      workouts.fold(0, (sum, w) => sum + w.totalWorkingSetsCount);

  TrainingPlan copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    List<Workout>? workouts,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return TrainingPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      workouts: workouts ?? this.workouts,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrainingPlan &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.description == description &&
        other.isActive == isActive &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        listEquals(other.workouts, workouts) &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        name,
        description,
        isActive,
        startDate,
        endDate,
        Object.hashAll(workouts),
        deletedAt,
      );
}
