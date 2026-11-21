import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/nutrition/domain/repositories/nutrition_repository.dart';

class RemoveFoodFromMealUseCase {
  const RemoveFoodFromMealUseCase(this._repository);

  final NutritionRepository _repository;

  Future<Result<void, Failure>> execute(String mealFoodId) {
    return _repository.removeFoodFromMeal(mealFoodId);
  }
}
