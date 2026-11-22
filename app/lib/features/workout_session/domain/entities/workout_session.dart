import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';

enum SessionStatus { inProgress, completed, abandoned }

/// Pure Domain Entity representing an active or completed workout execution.
@immutable
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.userId,
    this.workoutId,
    this.workoutName = 'Treino Avulso',
    required this.startedAt,
    this.completedAt,
    this.durationSeconds = 0,
    this.status = SessionStatus.inProgress,
    this.perceivedExertion,
    this.executionScore,
    this.mood,
    this.notes,
    this.readinessScore,
    this.exercises = const [],
    this.createdAt,
  });

  final String id;
  final String userId;
  final String? workoutId;
  final String workoutName;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationSeconds;
  final SessionStatus status;
  final double? perceivedExertion; // 1 to 10 RPE
  final int? executionScore; // 0 to 100 automatic adherence score
  final Mood? mood;
  final String? notes;
  final int? readinessScore;
  final List<SessionExercise> exercises;
  final DateTime? createdAt;

  bool get isInProgress => status == SessionStatus.inProgress;
  bool get isCompleted => status == SessionStatus.completed;

  int get totalExercisesCount => exercises.length;

  int get totalCompletedSetsCount =>
      exercises.fold(0, (sum, e) => sum + e.completedSetsCount);

  int get totalWorkingSetsCount => exercises
      .where((e) => !e.isCardio)
      .fold(0, (sum, e) => sum + e.completedWorkingSetsCount);

  int get totalCardioDurationSeconds =>
      exercises.fold(0, (sum, e) => sum + e.totalCardioDurationSeconds);

  double get totalVolumeKg => exercises
      .where((e) => !e.isCardio)
      .fold(0.0, (sum, e) => sum + e.totalVolumeKg);

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  WorkoutSession copyWith({
    String? id,
    String? userId,
    String? workoutId,
    String? workoutName,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationSeconds,
    SessionStatus? status,
    double? perceivedExertion,
    int? executionScore,
    Mood? mood,
    String? notes,
    int? readinessScore,
    List<SessionExercise>? exercises,
    DateTime? createdAt,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutId: workoutId ?? this.workoutId,
      workoutName: workoutName ?? this.workoutName,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      perceivedExertion: perceivedExertion ?? this.perceivedExertion,
      executionScore: executionScore ?? this.executionScore,
      mood: mood ?? this.mood,
      notes: notes ?? this.notes,
      readinessScore: readinessScore ?? this.readinessScore,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutSession &&
        other.id == id &&
        other.userId == userId &&
        other.workoutId == workoutId &&
        other.workoutName == workoutName &&
        other.startedAt == startedAt &&
        other.completedAt == completedAt &&
        other.durationSeconds == durationSeconds &&
        other.status == status &&
        other.perceivedExertion == perceivedExertion &&
        other.executionScore == executionScore &&
        other.mood == mood &&
        other.notes == notes &&
        other.readinessScore == readinessScore &&
        listEquals(other.exercises, exercises);
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        workoutId,
        workoutName,
        startedAt,
        completedAt,
        durationSeconds,
        status,
        perceivedExertion,
        executionScore,
        mood,
        notes,
        readinessScore,
        Object.hashAll(exercises),
      );
}
