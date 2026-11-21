import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/nutrition_goal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/repositories/nutrition_repository.dart';

class SaveNutritionGoalUseCase {
  const SaveNutritionGoalUseCase(this._repository);

  final NutritionRepository _repository;

  Future<Result<NutritionGoal, Failure>> execute({
    required int calories,
    required int proteinGrams,
    required int carbsGrams,
    required int fatGrams,
    String? notes,
  }) {
    if (calories <= 0 || calories > 10000) {
      return Future.value(
        const Err(ValidationFailure('Calorias devem estar entre 1 e 10.000 kcal.')),
      );
    }
    if (proteinGrams < 0 || carbsGrams < 0 || fatGrams < 0) {
      return Future.value(
        const Err(ValidationFailure('Macros não podem ser negativos.')),
      );
    }

    return _repository.saveNutritionGoal(
      calories: calories,
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
      notes: notes,
    );
  }
}
