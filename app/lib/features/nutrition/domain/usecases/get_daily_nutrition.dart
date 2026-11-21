import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';
import 'package:personal_fitness_os/features/nutrition/domain/repositories/nutrition_repository.dart';

class GetDailyNutritionUseCase {
  const GetDailyNutritionUseCase(this._repository);

  final NutritionRepository _repository;

  Future<Result<DailyNutrition, Failure>> execute(DateTime date) {
    return _repository.getDailyNutrition(date);
  }
}
