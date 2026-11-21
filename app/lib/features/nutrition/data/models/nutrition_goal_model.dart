import 'package:personal_fitness_os/features/nutrition/domain/entities/nutrition_goal.dart';

/// DTO for `nutrition_goals` table in Supabase.
class NutritionGoalModel {
  const NutritionGoalModel({
    required this.id,
    this.userId,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.effectiveFrom,
    this.effectiveUntil,
    this.notes,
  });

  final String id;
  final String? userId;
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final DateTime? effectiveFrom;
  final DateTime? effectiveUntil;
  final String? notes;

  factory NutritionGoalModel.fromJson(Map<String, dynamic> json) {
    return NutritionGoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      calories: json['calories'] as int,
      proteinGrams: json['protein_grams'] as int,
      carbsGrams: json['carbs_grams'] as int,
      fatGrams: json['fat_grams'] as int,
      effectiveFrom: json['effective_from'] != null
          ? DateTime.tryParse(json['effective_from'] as String)
          : null,
      effectiveUntil: json['effective_until'] != null
          ? DateTime.tryParse(json['effective_until'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'calories': calories,
      'protein_grams': proteinGrams,
      'carbs_grams': carbsGrams,
      'fat_grams': fatGrams,
      if (effectiveFrom != null)
        'effective_from': effectiveFrom!.toIso8601String().split('T').first,
      if (effectiveUntil != null)
        'effective_until': effectiveUntil!.toIso8601String().split('T').first,
      if (notes != null) 'notes': notes,
    };
  }

  NutritionGoal toDomain() {
    return NutritionGoal(
      id: id,
      userId: userId,
      calories: calories,
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
      effectiveFrom: effectiveFrom,
      effectiveUntil: effectiveUntil,
      notes: notes,
    );
  }

  factory NutritionGoalModel.fromDomain(NutritionGoal domain) {
    return NutritionGoalModel(
      id: domain.id,
      userId: domain.userId,
      calories: domain.calories,
      proteinGrams: domain.proteinGrams,
      carbsGrams: domain.carbsGrams,
      fatGrams: domain.fatGrams,
      effectiveFrom: domain.effectiveFrom,
      effectiveUntil: domain.effectiveUntil,
      notes: domain.notes,
    );
  }
}
