import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal_food.dart';

/// Pure Domain Entity representing a meal (e.g. Café da Manhã, Almoço, Jantar).
@immutable
class Meal {
  Meal({
    required this.id,
    required this.dailyNutritionId,
    required this.name,
    required this.mealType,
    this.eatenAt,
    this.notes,
    List<MealFood> foods = const [],
  }) : foods = List.unmodifiable(foods);

  final String id;
  final String dailyNutritionId;
  final String name;
  final String mealType;
  final DateTime? eatenAt;
  final String? notes;
  final List<MealFood> foods;

  double get totalCalories =>
      foods.fold(0.0, (sum, item) => sum + item.calories);

  double get totalProtein =>
      foods.fold(0.0, (sum, item) => sum + item.protein);

  double get totalCarbs =>
      foods.fold(0.0, (sum, item) => sum + item.carbs);

  double get totalFat =>
      foods.fold(0.0, (sum, item) => sum + item.fat);

  int get itemsCount => foods.length;

  static String defaultNameForType(String type) {
    switch (type) {
      case 'breakfast':
        return 'Café da Manhã';
      case 'morning_snack':
        return 'Lanche da Manhã';
      case 'lunch':
        return 'Almoço';
      case 'afternoon_snack':
        return 'Lanche da Tarde';
      case 'pre_workout':
        return 'Pré-Treino';
      case 'post_workout':
        return 'Pós-Treino';
      case 'dinner':
        return 'Jantar';
      case 'evening_snack':
        return 'Ceia';
      default:
        return 'Refeição Extra';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Meal &&
        other.id == id &&
        other.dailyNutritionId == dailyNutritionId &&
        other.name == name &&
        other.mealType == mealType &&
        other.eatenAt == eatenAt &&
        other.notes == notes &&
        listEquals(other.foods, foods);
  }

  @override
  int get hashCode => Object.hash(
        id,
        dailyNutritionId,
        name,
        mealType,
        eatenAt,
        notes,
        Object.hashAll(foods),
      );
}
