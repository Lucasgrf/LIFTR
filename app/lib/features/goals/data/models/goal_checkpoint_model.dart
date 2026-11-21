import 'package:personal_fitness_os/features/goals/domain/entities/goal_checkpoint.dart';

/// DTO for `goal_checkpoints` table in Supabase.
class GoalCheckpointModel {
  const GoalCheckpointModel({
    required this.id,
    required this.goalId,
    required this.value,
    required this.recordedAt,
    this.notes,
  });

  final String id;
  final String goalId;
  final double value;
  final DateTime recordedAt;
  final String? notes;

  factory GoalCheckpointModel.fromJson(Map<String, dynamic> json) {
    return GoalCheckpointModel(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      value: (json['value'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'goal_id': goalId,
      'value': value,
      'recorded_at': recordedAt.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }

  GoalCheckpoint toDomain() {
    return GoalCheckpoint(
      id: id,
      goalId: goalId,
      value: value,
      recordedAt: recordedAt,
      notes: notes,
    );
  }

  factory GoalCheckpointModel.fromDomain(GoalCheckpoint domain) {
    return GoalCheckpointModel(
      id: domain.id,
      goalId: domain.goalId,
      value: domain.value,
      recordedAt: domain.recordedAt,
      notes: domain.notes,
    );
  }
}
