import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';

class DeleteTrainingPlanUseCase {
  const DeleteTrainingPlanUseCase(this._repository);

  final TrainingRepository _repository;

  Future<Result<void, Failure>> execute(String planId) {
    if (planId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O ID do plano não pode ser vazio.')),
      );
    }
    return _repository.deleteTrainingPlan(planId);
  }
}
