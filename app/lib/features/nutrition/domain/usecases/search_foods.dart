import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/repositories/nutrition_repository.dart';

class SearchFoodsUseCase {
  const SearchFoodsUseCase(this._repository);

  final NutritionRepository _repository;

  Future<Result<List<Food>, Failure>> execute(String query) {
    return _repository.searchFoods(query);
  }
}
