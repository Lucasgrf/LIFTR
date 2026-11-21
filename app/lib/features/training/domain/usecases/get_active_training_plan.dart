import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';

class GetActiveTrainingPlanUseCase {
  const GetActiveTrainingPlanUseCase(this._repository);

  final TrainingRepository _repository;

  Future<Result<TrainingPlan?, Failure>> execute() {
    return _repository.getActiveTrainingPlan();
  }
}
