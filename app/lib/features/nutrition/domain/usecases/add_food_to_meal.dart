import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal_food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/repositories/nutrition_repository.dart';

class AddFoodToMealUseCase {
  const AddFoodToMealUseCase(this._repository);

  final NutritionRepository _repository;

  Future<Result<MealFood, Failure>> execute({
    required DateTime date,
    required String mealType,
    required String foodId,
    required double quantityGrams,
  }) {
    if (!quantityGrams.isFinite || quantityGrams <= 0 || quantityGrams > 5000) {
      return Future.value(
        const Err(ValidationFailure('Quantidade inválida. Informe entre 1g e 5000g.')),
      );
    }

    return _repository.addFoodToMeal(
      date: date,
      mealType: mealType,
      foodId: foodId,
      quantityGrams: quantityGrams,
    );
  }
}
