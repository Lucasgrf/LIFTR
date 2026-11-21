import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';

class CreateTrainingPlanUseCase {
  const CreateTrainingPlanUseCase(this._repository);

  final TrainingRepository _repository;

  Future<Result<TrainingPlan, Failure>> execute({
    required String name,
    String? description,
    bool isActive = false,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (name.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O nome do programa de treino é obrigatório.')),
      );
    }

    return _repository.createTrainingPlan(
      name: name.trim(),
      description: description?.trim(),
      isActive: isActive,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
