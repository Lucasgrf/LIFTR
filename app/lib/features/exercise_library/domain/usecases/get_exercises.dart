import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/repositories/exercise_repository.dart';

/// Use case for retrieving all available exercises.
class GetExercisesUseCase {
  const GetExercisesUseCase(this._repository);

  final ExerciseRepository _repository;

  Future<Result<List<Exercise>, Failure>> execute() {
    return _repository.getExercises();
  }
}
