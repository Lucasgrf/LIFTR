import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/repositories/exercise_repository.dart';

/// Use case for fetching a single exercise by ID.
class GetExerciseByIdUseCase {
  const GetExerciseByIdUseCase(this._repository);

  final ExerciseRepository _repository;

  Future<Result<Exercise, Failure>> execute(String id) {
    if (id.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O ID do exercício não pode ser vazio.')),
      );
    }
    return _repository.getExerciseById(id);
  }
}
