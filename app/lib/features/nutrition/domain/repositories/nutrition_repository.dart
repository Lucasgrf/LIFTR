import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal_food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/nutrition_goal.dart';

abstract class NutritionRepository {
  Future<Result<DailyNutrition, Failure>> getDailyNutrition(DateTime date);

  Future<Result<NutritionGoal?, Failure>> getActiveNutritionGoal();

  Future<Result<NutritionGoal, Failure>> saveNutritionGoal({
    required int calories,
    required int proteinGrams,
    required int carbsGrams,
    required int fatGrams,
    String? notes,
  });

  Future<Result<List<Food>, Failure>> searchFoods(String query);

  Future<Result<Food, Failure>> createCustomFood(Food food);

  Future<Result<MealFood, Failure>> addFoodToMeal({
    required DateTime date,
    required String mealType,
    required String foodId,
    required double quantityGrams,
  });

  Future<Result<void, Failure>> removeFoodFromMeal(String mealFoodId);
}
