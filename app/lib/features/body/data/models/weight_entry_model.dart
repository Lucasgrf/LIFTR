import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';

/// DTO for `weight_entries` table in Supabase.
class WeightEntryModel {
  const WeightEntryModel({
    required this.id,
    this.userId,
    required this.weight,
    required this.measuredAt,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String? userId;
  final double weight;
  final DateTime measuredAt;
  final String? notes;
  final DateTime? createdAt;

  factory WeightEntryModel.fromJson(Map<String, dynamic> json) {
    return WeightEntryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      weight: (json['weight'] as num).toDouble(),
      measuredAt: DateTime.parse(json['measured_at'] as String),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'weight': weight,
      'measured_at': measuredAt.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }

  WeightEntry toDomain() {
    return WeightEntry(
      id: id,
      userId: userId,
      weightKg: weight,
      measuredAt: measuredAt,
      notes: notes,
      createdAt: createdAt,
    );
  }

  factory WeightEntryModel.fromDomain(WeightEntry domain) {
    return WeightEntryModel(
      id: domain.id,
      userId: domain.userId,
      weight: domain.weightKg,
      measuredAt: domain.measuredAt,
      notes: domain.notes,
      createdAt: domain.createdAt,
    );
  }
}
