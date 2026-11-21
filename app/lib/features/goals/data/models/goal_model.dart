import 'package:personal_fitness_os/features/goals/data/models/goal_checkpoint_model.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_category.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';

/// DTO for `goals` table in Supabase.
class GoalModel {
  const GoalModel({
    required this.id,
    this.userId,
    required this.title,
    this.description,
    required this.category,
    this.referenceExerciseId,
    this.referenceMeasurementType,
    required this.initialValue,
    required this.targetValue,
    this.currentValue,
    this.unit = '',
    required this.startedAt,
    this.deadline,
    this.completedAt,
    this.status = GoalStatus.active,
    this.checkpoints = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? userId;
  final String title;
  final String? description;
  final GoalCategory category;
  final String? referenceExerciseId;
  final String? referenceMeasurementType;
  final double initialValue;
  final double targetValue;
  final double? currentValue;
  final String unit;
  final DateTime startedAt;
  final DateTime? deadline;
  final DateTime? completedAt;
  final GoalStatus status;
  final List<GoalCheckpointModel> checkpoints;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static GoalCategory _categoryFromString(String cat) {
    switch (cat) {
      case 'weight':
        return GoalCategory.weight;
      case 'calories':
        return GoalCategory.calories;
      case 'protein':
        return GoalCategory.protein;
      case 'training_frequency':
        return GoalCategory.trainingFrequency;
      case 'exercise_weight':
        return GoalCategory.exerciseWeight;
      case 'exercise_reps':
        return GoalCategory.exerciseReps;
      case 'measurement':
        return GoalCategory.measurement;
      case 'habit':
        return GoalCategory.habit;
      default:
        return GoalCategory.custom;
    }
  }

  static String _categoryToString(GoalCategory cat) {
    switch (cat) {
      case GoalCategory.weight:
        return 'weight';
      case GoalCategory.calories:
        return 'calories';
      case GoalCategory.protein:
        return 'protein';
      case GoalCategory.trainingFrequency:
        return 'training_frequency';
      case GoalCategory.exerciseWeight:
        return 'exercise_weight';
      case GoalCategory.exerciseReps:
        return 'exercise_reps';
      case GoalCategory.measurement:
        return 'measurement';
      case GoalCategory.habit:
        return 'habit';
      case GoalCategory.custom:
        return 'custom';
    }
  }

  static GoalStatus _statusFromString(String? st) {
    switch (st) {
      case 'completed':
        return GoalStatus.completed;
      case 'paused':
        return GoalStatus.paused;
      case 'abandoned':
        return GoalStatus.abandoned;
      default:
        return GoalStatus.active;
    }
  }

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    final checkpointsList = (json['goal_checkpoints'] as List<dynamic>?)
            ?.map((e) => GoalCheckpointModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return GoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: _categoryFromString(json['category'] as String),
      referenceExerciseId: json['reference_exercise_id'] as String?,
      referenceMeasurementType: json['reference_measurement_type'] as String?,
      initialValue: (json['initial_value'] as num).toDouble(),
      targetValue: (json['target_value'] as num).toDouble(),
      currentValue: (json['current_value'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? '',
      startedAt: DateTime.parse(json['started_at'] as String),
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      status: _statusFromString(json['status'] as String?),
      checkpoints: checkpointsList,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (userId != null) 'user_id': userId,
      'title': title,
      if (description != null) 'description': description,
      'category': _categoryToString(category),
      if (referenceExerciseId != null)
        'reference_exercise_id': referenceExerciseId,
      if (referenceMeasurementType != null)
        'reference_measurement_type': referenceMeasurementType,
      'initial_value': initialValue,
      'target_value': targetValue,
      if (currentValue != null) 'current_value': currentValue,
      'unit': unit,
      'started_at': startedAt.toIso8601String().split('T').first,
      if (deadline != null)
        'deadline': deadline!.toIso8601String().split('T').first,
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'status': status.name,
    };
  }

  Goal toDomain() {
    return Goal(
      id: id,
      userId: userId,
      title: title,
      description: description,
      category: category,
      referenceExerciseId: referenceExerciseId,
      referenceMeasurementType: referenceMeasurementType,
      initialValue: initialValue,
      targetValue: targetValue,
      currentValue: currentValue,
      unit: unit,
      startedAt: startedAt,
      deadline: deadline,
      completedAt: completedAt,
      status: status,
      checkpoints: checkpoints.map((c) => c.toDomain()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory GoalModel.fromDomain(Goal domain) {
    return GoalModel(
      id: domain.id,
      userId: domain.userId,
      title: domain.title,
      description: domain.description,
      category: domain.category,
      referenceExerciseId: domain.referenceExerciseId,
      referenceMeasurementType: domain.referenceMeasurementType,
      initialValue: domain.initialValue,
      targetValue: domain.targetValue,
      currentValue: domain.currentValue,
      unit: domain.unit,
      startedAt: domain.startedAt,
      deadline: domain.deadline,
      completedAt: domain.completedAt,
      status: domain.status,
      checkpoints: domain.checkpoints
          .map((c) => GoalCheckpointModel.fromDomain(c))
          .toList(),
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
    );
  }
}
