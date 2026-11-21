import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';

class ReorderPlanWorkoutsUseCase {
  const ReorderPlanWorkoutsUseCase(this._repository);

  final TrainingRepository _repository;

  Future<Result<void, Failure>> execute({
    required String trainingPlanId,
    required List<String> orderedWorkoutIds,
  }) {
    if (trainingPlanId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O ID do programa não pode ser vazio.')),
      );
    }

    return _repository.reorderPlanWorkouts(
      trainingPlanId: trainingPlanId.trim(),
      orderedWorkoutIds: orderedWorkoutIds,
    );
  }
}
