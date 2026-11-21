import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/repositories/exercise_repository.dart';

/// Use case for updating personal notes on an exercise.
class UpdateExerciseNotesUseCase {
  const UpdateExerciseNotesUseCase(this._repository);

  final ExerciseRepository _repository;

  Future<Result<Exercise, Failure>> execute({
    required String exerciseId,
    required String notes,
  }) {
    if (exerciseId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O ID do exercício é obrigatório.')),
      );
    }

    return _repository.updateExerciseNotes(
      exerciseId: exerciseId,
      notes: notes.trim(),
    );
  }
}
