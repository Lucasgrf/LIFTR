import 'package:personal_fitness_os/features/nutrition/domain/entities/food.dart';

/// Pure Domain Entity representing a specific food quantity logged in a meal.
class MealFood {
  const MealFood({
    required this.id,
    required this.mealId,
    required this.foodId,
    this.food,
    required this.quantityGrams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.createdAt,
  });

  final String id;
  final String mealId;
  final String foodId;
  final Food? food;
  final double quantityGrams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime? createdAt;

  String get foodName => food?.displayName ?? 'Alimento';

  MealFood copyWith({
    String? id,
    String? mealId,
    String? foodId,
    Food? food,
    double? quantityGrams,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    DateTime? createdAt,
  }) {
    return MealFood(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      foodId: foodId ?? this.foodId,
      food: food ?? this.food,
      quantityGrams: quantityGrams ?? this.quantityGrams,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MealFood &&
        other.id == id &&
        other.mealId == mealId &&
        other.foodId == foodId &&
        other.food == food &&
        other.quantityGrams == quantityGrams &&
        other.calories == calories &&
        other.protein == protein &&
        other.carbs == carbs &&
        other.fat == fat;
  }

  @override
  int get hashCode => Object.hash(
        id,
        mealId,
        foodId,
        food,
        quantityGrams,
        calories,
        protein,
        carbs,
        fat,
      );
}
