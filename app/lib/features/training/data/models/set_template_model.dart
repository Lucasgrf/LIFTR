import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';

/// DTO for `set_templates` table in Supabase.
class SetTemplateModel {
  const SetTemplateModel({
    required this.id,
    required this.workoutExerciseId,
    required this.setNumber,
    this.setType = 'working',
    this.targetRepsMin,
    this.targetRepsMax,
    this.targetRirMin,
    this.targetRirMax,
    this.targetWeight,
    this.restSeconds = 120,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String workoutExerciseId;
  final int setNumber;
  final String setType;
  final int? targetRepsMin;
  final int? targetRepsMax;
  final int? targetRirMin;
  final int? targetRirMax;
  final double? targetWeight;
  final int restSeconds;
  final String? notes;
  final DateTime? createdAt;

  factory SetTemplateModel.fromJson(Map<String, dynamic> json) {
    return SetTemplateModel(
      id: json['id'] as String,
      workoutExerciseId: json['workout_exercise_id'] as String,
      setNumber: json['set_number'] as int? ?? 1,
      setType: json['set_type'] as String? ?? 'working',
      targetRepsMin: json['target_reps_min'] as int?,
      targetRepsMax: json['target_reps_max'] as int?,
      targetRirMin: json['target_rir_min'] as int?,
      targetRirMax: json['target_rir_max'] as int?,
      targetWeight: json['target_weight'] != null
          ? (json['target_weight'] as num).toDouble()
          : null,
      restSeconds: json['rest_seconds'] as int? ?? 120,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workout_exercise_id': workoutExerciseId,
      'set_number': setNumber,
      'set_type': setType,
      if (targetRepsMin != null) 'target_reps_min': targetRepsMin,
      if (targetRepsMax != null) 'target_reps_max': targetRepsMax,
      if (targetRirMin != null) 'target_rir_min': targetRirMin,
      if (targetRirMax != null) 'target_rir_max': targetRirMax,
      if (targetWeight != null) 'target_weight': targetWeight,
      'rest_seconds': restSeconds,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  static SetType parseSetType(String raw) {
    switch (raw.toLowerCase()) {
      case 'mobility':
        return SetType.mobility;
      case 'warmup':
        return SetType.warmup;
      case 'ramp_up':
      case 'rampup':
        return SetType.rampUp;
      case 'working':
        return SetType.working;
      default:
        return SetType.working;
    }
  }

  static String setTypeToString(SetType type) {
    switch (type) {
      case SetType.mobility:
        return 'mobility';
      case SetType.warmup:
        return 'warmup';
      case SetType.rampUp:
        return 'ramp_up';
      case SetType.working:
        return 'working';
      case SetType.dropSet:
      case SetType.myoRep:
        return 'working';
    }
  }

  SetTemplate toDomain() {
    return SetTemplate(
      id: id,
      workoutExerciseId: workoutExerciseId,
      setNumber: setNumber,
      setType: parseSetType(setType),
      targetRepsMin: targetRepsMin,
      targetRepsMax: targetRepsMax,
      targetRirMin: targetRirMin,
      targetRirMax: targetRirMax,
      targetWeight: targetWeight,
      restSeconds: restSeconds,
      notes: notes,
      createdAt: createdAt,
    );
  }

  factory SetTemplateModel.fromDomain(SetTemplate template) {
    return SetTemplateModel(
      id: template.id,
      workoutExerciseId: template.workoutExerciseId,
      setNumber: template.setNumber,
      setType: setTypeToString(template.setType),
      targetRepsMin: template.targetRepsMin,
      targetRepsMax: template.targetRepsMax,
      targetRirMin: template.targetRirMin,
      targetRirMax: template.targetRirMax,
      targetWeight: template.targetWeight,
      restSeconds: template.restSeconds,
      notes: template.notes,
      createdAt: template.createdAt,
    );
  }

  SetTemplateModel copyWith({
    String? id,
    String? workoutExerciseId,
    int? setNumber,
    String? setType,
    int? targetRepsMin,
    int? targetRepsMax,
    int? targetRirMin,
    int? targetRirMax,
    double? targetWeight,
    int? restSeconds,
    String? notes,
    DateTime? createdAt,
  }) {
    return SetTemplateModel(
      id: id ?? this.id,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      setNumber: setNumber ?? this.setNumber,
      setType: setType ?? this.setType,
      targetRepsMin: targetRepsMin ?? this.targetRepsMin,
      targetRepsMax: targetRepsMax ?? this.targetRepsMax,
      targetRirMin: targetRirMin ?? this.targetRirMin,
      targetRirMax: targetRirMax ?? this.targetRirMax,
      targetWeight: targetWeight ?? this.targetWeight,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
