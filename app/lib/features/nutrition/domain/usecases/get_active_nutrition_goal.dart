import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/nutrition_goal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/repositories/nutrition_repository.dart';

class GetActiveNutritionGoalUseCase {
  const GetActiveNutritionGoalUseCase(this._repository);

  final NutritionRepository _repository;

  Future<Result<NutritionGoal?, Failure>> execute() {
    return _repository.getActiveNutritionGoal();
  }
}
