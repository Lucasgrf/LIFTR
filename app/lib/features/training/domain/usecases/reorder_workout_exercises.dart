import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';

class ReorderWorkoutExercisesUseCase {
  const ReorderWorkoutExercisesUseCase(this._repository);

  final TrainingRepository _repository;

  Future<Result<void, Failure>> execute({
    required String workoutId,
    required List<String> orderedWorkoutExerciseIds,
  }) {
    if (workoutId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O ID do treino não pode ser vazio.')),
      );
    }

    return _repository.reorderWorkoutExercises(
      workoutId: workoutId.trim(),
      orderedWorkoutExerciseIds: orderedWorkoutExerciseIds,
    );
  }
}
