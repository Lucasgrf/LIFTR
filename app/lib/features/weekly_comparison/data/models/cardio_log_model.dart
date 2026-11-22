import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/cardio_log.dart';

class CardioLogModel {
  const CardioLogModel({
    required this.id,
    required this.userId,
    required this.modality,
    required this.durationSeconds,
    required this.performedAt,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String modality;
  final int durationSeconds;
  final DateTime performedAt;
  final String? notes;
  final DateTime? createdAt;

  factory CardioLogModel.fromJson(Map<String, dynamic> json) {
    return CardioLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      modality: json['modality'] as String? ?? 'Cardio',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      performedAt: json['performed_at'] != null
          ? DateTime.parse(json['performed_at'] as String)
          : DateTime.now(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'modality': modality,
      'duration_seconds': durationSeconds,
      'performed_at': performedAt.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  CardioLog toDomain() {
    return CardioLog(
      id: id,
      userId: userId,
      modality: modality,
      durationSeconds: durationSeconds,
      performedAt: performedAt,
      notes: notes,
      createdAt: createdAt,
    );
  }

  factory CardioLogModel.fromDomain(CardioLog entity) {
    return CardioLogModel(
      id: entity.id,
      userId: entity.userId,
      modality: entity.modality,
      durationSeconds: entity.durationSeconds,
      performedAt: entity.performedAt,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }
}
