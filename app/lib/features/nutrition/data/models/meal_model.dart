import 'package:personal_fitness_os/features/nutrition/data/models/meal_food_model.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal.dart';

/// DTO for `meals` table in Supabase.
class MealModel {
  const MealModel({
    required this.id,
    required this.dailyNutritionId,
    required this.name,
    required this.mealType,
    this.eatenAt,
    this.notes,
    this.foods = const [],
    this.createdAt,
  });

  final String id;
  final String dailyNutritionId;
  final String name;
  final String mealType;
  final DateTime? eatenAt;
  final String? notes;
  final List<MealFoodModel> foods;
  final DateTime? createdAt;

  factory MealModel.fromJson(Map<String, dynamic> json) {
    final foodsList = (json['meal_foods'] as List<dynamic>?)
            ?.map((e) => MealFoodModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return MealModel(
      id: json['id'] as String,
      dailyNutritionId: json['daily_nutrition_id'] as String,
      name: json['name'] as String? ?? Meal.defaultNameForType(json['meal_type'] as String? ?? 'other'),
      mealType: json['meal_type'] as String? ?? 'other',
      eatenAt: json['eaten_at'] != null
          ? DateTime.tryParse(json['eaten_at'] as String)
          : null,
      notes: json['notes'] as String?,
      foods: foodsList,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'daily_nutrition_id': dailyNutritionId,
      'name': name,
      'meal_type': mealType,
      if (eatenAt != null) 'eaten_at': eatenAt!.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }

  Meal toDomain() {
    return Meal(
      id: id,
      dailyNutritionId: dailyNutritionId,
      name: name,
      mealType: mealType,
      eatenAt: eatenAt,
      notes: notes,
      foods: foods.map((f) => f.toDomain()).toList(),
    );
  }
}
