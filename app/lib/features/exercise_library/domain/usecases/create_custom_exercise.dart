import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/repositories/exercise_repository.dart';

/// Use case for creating a user-defined custom exercise.
class CreateCustomExerciseUseCase {
  const CreateCustomExerciseUseCase(this._repository);

  final ExerciseRepository _repository;

  Future<Result<Exercise, Failure>> execute({
    required String name,
    required String primaryMuscleGroup,
    List<String>? secondaryMuscles,
    String? equipment,
    String? movementPattern,
    String? instructions,
    String? commonMistakes,
    String? videoUrl,
    String? personalNotes,
  }) {
    if (name.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O nome do exercício é obrigatório.')),
      );
    }
    if (primaryMuscleGroup.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O grupo muscular principal é obrigatório.')),
      );
    }

    return _repository.createCustomExercise(
      name: name.trim(),
      primaryMuscleGroup: primaryMuscleGroup.trim(),
      secondaryMuscles: secondaryMuscles,
      equipment: equipment?.trim(),
      movementPattern: movementPattern?.trim(),
      instructions: instructions?.trim(),
      commonMistakes: commonMistakes?.trim(),
      videoUrl: videoUrl?.trim(),
      personalNotes: personalNotes?.trim(),
    );
  }
}
