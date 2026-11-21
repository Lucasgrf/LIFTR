import 'package:personal_fitness_os/features/nutrition/data/models/food_model.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal_food.dart';

/// DTO for `meal_foods` table in Supabase.
class MealFoodModel {
  const MealFoodModel({
    required this.id,
    required this.mealId,
    required this.foodId,
    this.food,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.createdAt,
  });

  final String id;
  final String mealId;
  final String foodId;
  final FoodModel? food;
  final double quantity;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime? createdAt;

  factory MealFoodModel.fromJson(Map<String, dynamic> json) {
    return MealFoodModel(
      id: json['id'] as String,
      mealId: json['meal_id'] as String,
      foodId: json['food_id'] as String,
      food: json['foods'] != null
          ? FoodModel.fromJson(json['foods'] as Map<String, dynamic>)
          : null,
      quantity: (json['quantity'] as num).toDouble(),
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meal_id': mealId,
      'food_id': foodId,
      'quantity': quantity,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  MealFood toDomain() {
    return MealFood(
      id: id,
      mealId: mealId,
      foodId: foodId,
      food: food?.toDomain(),
      quantityGrams: quantity,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      createdAt: createdAt,
    );
  }
}
