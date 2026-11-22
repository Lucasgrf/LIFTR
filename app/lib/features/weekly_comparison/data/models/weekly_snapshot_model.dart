import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_snapshot.dart';

class WeeklySnapshotModel {
  const WeeklySnapshotModel({
    this.id,
    this.userId,
    required this.weekStart,
    required this.weekEnd,
    this.workoutsCompleted = 0,
    this.cardioDurationSeconds = 0,
    this.trainingDurationSeconds = 0,
    this.workingSetsCount = 0,
    this.totalVolumeKg = 0.0,
    this.avgRpe,
    this.avgExecutionScore,
    this.updatedAt,
  });

  final String? id;
  final String? userId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int workoutsCompleted;
  final int cardioDurationSeconds;
  final int trainingDurationSeconds;
  final int workingSetsCount;
  final double totalVolumeKg;
  final double? avgRpe;
  final double? avgExecutionScore;
  final DateTime? updatedAt;

  factory WeeklySnapshotModel.fromJson(Map<String, dynamic> json) {
    final start = DateTime.parse(json['week_start'] as String);
    final end = DateTime.parse(json['week_end'] as String);
    return WeeklySnapshotModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      weekStart: DateTime(start.year, start.month, start.day),
      weekEnd: DateTime(end.year, end.month, end.day),
      workoutsCompleted: (json['workouts_completed'] as num?)?.toInt() ?? 0,
      cardioDurationSeconds:
          (json['cardio_duration_seconds'] as num?)?.toInt() ?? 0,
      trainingDurationSeconds:
          (json['training_duration_seconds'] as num?)?.toInt() ?? 0,
      workingSetsCount: (json['working_sets_count'] as num?)?.toInt() ?? 0,
      totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble() ?? 0.0,
      avgRpe: (json['avg_rpe'] as num?)?.toDouble(),
      avgExecutionScore: (json['avg_execution_score'] as num?)?.toDouble(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'week_start': isoDateKey(weekStart),
      'week_end': isoDateKey(weekEnd),
      'workouts_completed': workoutsCompleted,
      'cardio_duration_seconds': cardioDurationSeconds,
      'training_duration_seconds': trainingDurationSeconds,
      'working_sets_count': workingSetsCount,
      'total_volume_kg': totalVolumeKg,
      if (avgRpe != null) 'avg_rpe': avgRpe,
      if (avgExecutionScore != null) 'avg_execution_score': avgExecutionScore,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpsertJson(String resolvedUserId) {
    return {
      'user_id': resolvedUserId,
      'week_start': isoDateKey(weekStart),
      'week_end': isoDateKey(weekEnd),
      'workouts_completed': workoutsCompleted,
      'cardio_duration_seconds': cardioDurationSeconds,
      'training_duration_seconds': trainingDurationSeconds,
      'working_sets_count': workingSetsCount,
      'total_volume_kg': totalVolumeKg,
      'avg_rpe': avgRpe,
      'avg_execution_score': avgExecutionScore,
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  WeeklySnapshot toDomain() {
    return WeeklySnapshot(
      id: id,
      userId: userId,
      weekStart: weekStart,
      weekEnd: weekEnd,
      workoutsCompleted: workoutsCompleted,
      cardioDurationSeconds: cardioDurationSeconds,
      trainingDurationSeconds: trainingDurationSeconds,
      workingSetsCount: workingSetsCount,
      totalVolumeKg: totalVolumeKg,
      avgRpe: avgRpe,
      avgExecutionScore: avgExecutionScore,
      updatedAt: updatedAt,
    );
  }

  factory WeeklySnapshotModel.fromDomain(WeeklySnapshot entity) {
    return WeeklySnapshotModel(
      id: entity.id,
      userId: entity.userId,
      weekStart: entity.weekStart,
      weekEnd: entity.weekEnd,
      workoutsCompleted: entity.workoutsCompleted,
      cardioDurationSeconds: entity.cardioDurationSeconds,
      trainingDurationSeconds: entity.trainingDurationSeconds,
      workingSetsCount: entity.workingSetsCount,
      totalVolumeKg: entity.totalVolumeKg,
      avgRpe: entity.avgRpe,
      avgExecutionScore: entity.avgExecutionScore,
      updatedAt: entity.updatedAt,
    );
  }
}
