import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/session_exercise_model.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

/// DTO for `workout_sessions` table in Supabase.
class WorkoutSessionModel {
  const WorkoutSessionModel({
    required this.id,
    required this.userId,
    this.workoutId,
    this.workoutName = 'Treino Avulso',
    required this.startedAt,
    this.completedAt,
    this.durationSeconds = 0,
    this.status = 'in_progress',
    this.perceivedExertion,
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
  final String status;
  final double? perceivedExertion;
  final String? mood;
  final String? notes;
  final int? readinessScore;
  final List<SessionExerciseModel> exercises;
  final DateTime? createdAt;

  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) {
    String name = 'Treino Avulso';
    if (json['workouts'] != null && json['workouts'] is Map<String, dynamic>) {
      name = json['workouts']['name'] as String? ?? name;
    }

    return WorkoutSessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      workoutId: json['workout_id'] as String?,
      workoutName: name,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      status: json['status'] as String? ?? 'in_progress',
      perceivedExertion: (json['perceived_exertion'] as num?)?.toDouble(),
      mood: json['mood'] as String?,
      notes: json['notes'] as String?,
      readinessScore: json['readiness_score'] as int?,
      exercises: (json['workout_session_exercises'] as List<dynamic>?)
              ?.map((e) =>
                  SessionExerciseModel.fromJson(e as Map<String, dynamic>))
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
      'user_id': userId,
      if (workoutId != null) 'workout_id': workoutId,
      'started_at': startedAt.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'duration_seconds': durationSeconds,
      'status': status,
      if (perceivedExertion != null) 'perceived_exertion': perceivedExertion,
      if (mood != null) 'mood': mood,
      if (notes != null) 'notes': notes,
      if (readinessScore != null) 'readiness_score': readinessScore,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  static SessionStatus parseStatus(String raw) {
    switch (raw.toLowerCase()) {
      case 'in_progress':
        return SessionStatus.inProgress;
      case 'completed':
        return SessionStatus.completed;
      case 'abandoned':
        return SessionStatus.abandoned;
      default:
        return SessionStatus.inProgress;
    }
  }

  static String statusToString(SessionStatus s) {
    switch (s) {
      case SessionStatus.inProgress:
        return 'in_progress';
      case SessionStatus.completed:
        return 'completed';
      case SessionStatus.abandoned:
        return 'abandoned';
    }
  }

  static Mood? parseMood(String? raw) {
    if (raw == null) return null;
    switch (raw.toLowerCase()) {
      case 'awful':
      case 'terrible':
        return Mood.awful;
      case 'bad':
        return Mood.bad;
      case 'neutral':
        return Mood.neutral;
      case 'good':
        return Mood.good;
      case 'excellent':
        return Mood.excellent;
      default:
        return null;
    }
  }

  static String? moodToString(Mood? m) {
    if (m == null) return null;
    return m.name;
  }

  WorkoutSession toDomain() {
    final sortedExercises = [...exercises]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return WorkoutSession(
      id: id,
      userId: userId,
      workoutId: workoutId,
      workoutName: workoutName,
      startedAt: startedAt,
      completedAt: completedAt,
      durationSeconds: durationSeconds,
      status: parseStatus(status),
      perceivedExertion: perceivedExertion,
      mood: parseMood(mood),
      notes: notes,
      readinessScore: readinessScore,
      exercises: sortedExercises.map((e) => e.toDomain()).toList(),
      createdAt: createdAt,
    );
  }

  factory WorkoutSessionModel.fromDomain(WorkoutSession entity) {
    return WorkoutSessionModel(
      id: entity.id,
      userId: entity.userId,
      workoutId: entity.workoutId,
      workoutName: entity.workoutName,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      durationSeconds: entity.durationSeconds,
      status: statusToString(entity.status),
      perceivedExertion: entity.perceivedExertion,
      mood: moodToString(entity.mood),
      notes: entity.notes,
      readinessScore: entity.readinessScore,
      exercises: entity.exercises
          .map((e) => SessionExerciseModel.fromDomain(e))
          .toList(),
      createdAt: entity.createdAt,
    );
  }

  WorkoutSessionModel copyWith({
    String? id,
    String? userId,
    String? workoutId,
    String? workoutName,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationSeconds,
    String? status,
    double? perceivedExertion,
    String? mood,
    String? notes,
    int? readinessScore,
    List<SessionExerciseModel>? exercises,
    DateTime? createdAt,
  }) {
    return WorkoutSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutId: workoutId ?? this.workoutId,
      workoutName: workoutName ?? this.workoutName,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      perceivedExertion: perceivedExertion ?? this.perceivedExertion,
      mood: mood ?? this.mood,
      notes: notes ?? this.notes,
      readinessScore: readinessScore ?? this.readinessScore,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
