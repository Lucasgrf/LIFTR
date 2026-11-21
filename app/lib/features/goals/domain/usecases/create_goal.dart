import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/domain/repositories/goal_repository.dart';

class CreateGoalUseCase {
  const CreateGoalUseCase(this._repository);

  final GoalRepository _repository;

  Future<Result<Goal, Failure>> execute(Goal goal) {
    if (goal.title.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Título da meta é obrigatório.')),
      );
    }
    if (!goal.initialValue.isFinite || !goal.targetValue.isFinite) {
      return Future.value(
        const Err(ValidationFailure('Valores inicial e alvo devem ser números válidos.')),
      );
    }

    return _repository.createGoal(goal);
  }
}
