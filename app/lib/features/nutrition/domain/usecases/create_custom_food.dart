import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/repositories/nutrition_repository.dart';

class CreateCustomFoodUseCase {
  const CreateCustomFoodUseCase(this._repository);

  final NutritionRepository _repository;

  Future<Result<Food, Failure>> execute(Food food) {
    if (food.name.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Nome do alimento é obrigatório.')),
      );
    }
    if (!food.calories.isFinite || food.calories < 0 || food.calories > 2000) {
      return Future.value(
        const Err(ValidationFailure('Calorias por porção inválidas.')),
      );
    }
    if (!food.servingSize.isFinite || food.servingSize <= 0) {
      return Future.value(
        const Err(ValidationFailure('Tamanho da porção deve ser maior que zero.')),
      );
    }
    if (!food.protein.isFinite ||
        food.protein < 0 ||
        !food.carbs.isFinite ||
        food.carbs < 0 ||
        !food.fat.isFinite ||
        food.fat < 0 ||
        !food.fiber.isFinite ||
        food.fiber < 0) {
      return Future.value(
        const Err(ValidationFailure(
            'Macronutrientes e fibras devem ser valores numéricos não-negativos.')),
      );
    }

    return _repository.createCustomFood(food.copyWith(isCustom: true));
  }
}
