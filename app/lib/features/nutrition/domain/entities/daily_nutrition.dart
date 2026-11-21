import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/nutrition_goal.dart';

/// Pure Domain Aggregate representing all nutrition tracking for a specific day.
@immutable
class DailyNutrition {
  DailyNutrition({
    required this.id,
    this.userId,
    required this.date,
    this.goal,
    List<Meal> meals = const [],
    this.notes,
  }) : meals = List.unmodifiable(meals);

  final String id;
  final String? userId;
  final DateTime date;
  final NutritionGoal? goal;
  final List<Meal> meals;
  final String? notes;

  double get totalCalories =>
      meals.fold(0.0, (sum, meal) => sum + meal.totalCalories);

  double get totalProtein =>
      meals.fold(0.0, (sum, meal) => sum + meal.totalProtein);

  double get totalCarbs =>
      meals.fold(0.0, (sum, meal) => sum + meal.totalCarbs);

  double get totalFat =>
      meals.fold(0.0, (sum, meal) => sum + meal.totalFat);

  double get remainingCalories {
    if (goal == null) return 0.0;
    return goal!.calories - totalCalories;
  }

  double get proteinProgress {
    if (goal == null || goal!.proteinGrams <= 0) return 0.0;
    return (totalProtein / goal!.proteinGrams).clamp(0.0, 1.0);
  }

  double get carbsProgress {
    if (goal == null || goal!.carbsGrams <= 0) return 0.0;
    return (totalCarbs / goal!.carbsGrams).clamp(0.0, 1.0);
  }

  double get fatProgress {
    if (goal == null || goal!.fatGrams <= 0) return 0.0;
    return (totalFat / goal!.fatGrams).clamp(0.0, 1.0);
  }

  double get caloriesProgress {
    if (goal == null || goal!.calories <= 0) return 0.0;
    return (totalCalories / goal!.calories).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyNutrition &&
        other.id == id &&
        other.userId == userId &&
        other.date == date &&
        other.goal == goal &&
        other.notes == notes &&
        listEquals(other.meals, meals);
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        date,
        goal,
        notes,
        Object.hashAll(meals),
      );
}
