import 'package:personal_fitness_os/features/training/data/models/workout_model.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';

/// DTO for `training_plans` table in Supabase.
class TrainingPlanModel {
  const TrainingPlanModel({
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
  final List<WorkoutModel> workouts;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  factory TrainingPlanModel.fromJson(Map<String, dynamic> json) {
    return TrainingPlanModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      workouts: (json['workouts'] as List<dynamic>?)
              ?.map((w) => WorkoutModel.fromJson(w as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      if (description != null) 'description': description,
      'is_active': isActive,
      if (startDate != null) 'start_date': startDate!.toIso8601String().split('T').first,
      if (endDate != null) 'end_date': endDate!.toIso8601String().split('T').first,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  TrainingPlan toDomain() {
    final sortedWorkouts = [...workouts]
      ..sort((a, b) {
        if (a.dayOfWeek != null && b.dayOfWeek != null) {
          return a.dayOfWeek!.compareTo(b.dayOfWeek!);
        }
        return a.sortOrder.compareTo(b.sortOrder);
      });

    return TrainingPlan(
      id: id,
      userId: userId,
      name: name,
      description: description,
      isActive: isActive,
      startDate: startDate,
      endDate: endDate,
      workouts: sortedWorkouts.map((w) => w.toDomain()).toList(),
      createdAt: createdAt,
      deletedAt: deletedAt,
    );
  }

  factory TrainingPlanModel.fromDomain(TrainingPlan entity) {
    return TrainingPlanModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      description: entity.description,
      isActive: entity.isActive,
      startDate: entity.startDate,
      endDate: entity.endDate,
      workouts: entity.workouts
          .map((w) => WorkoutModel.fromDomain(w))
          .toList(),
      createdAt: entity.createdAt,
      deletedAt: entity.deletedAt,
    );
  }

  TrainingPlanModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    List<WorkoutModel>? workouts,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return TrainingPlanModel(
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
}
