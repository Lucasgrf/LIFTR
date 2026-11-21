import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';

class GetTrainingPlanByIdUseCase {
  const GetTrainingPlanByIdUseCase(this._repository);

  final TrainingRepository _repository;

  Future<Result<TrainingPlan, Failure>> execute(String id) {
    if (id.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O ID do programa não pode ser vazio.')),
      );
    }
    return _repository.getTrainingPlanById(id);
  }
}
