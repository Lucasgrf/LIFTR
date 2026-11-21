import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/domain/repositories/goal_repository.dart';

class GetGoalByIdUseCase {
  const GetGoalByIdUseCase(this._repository);

  final GoalRepository _repository;

  Future<Result<Goal, Failure>> execute(String goalId) {
    if (goalId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('ID da meta inválido.')),
      );
    }
    return _repository.getGoalById(goalId);
  }
}
