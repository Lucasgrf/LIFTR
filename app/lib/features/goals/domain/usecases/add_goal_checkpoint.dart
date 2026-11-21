import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_checkpoint.dart';
import 'package:personal_fitness_os/features/goals/domain/repositories/goal_repository.dart';

class AddGoalCheckpointUseCase {
  const AddGoalCheckpointUseCase(this._repository);

  final GoalRepository _repository;

  Future<Result<GoalCheckpoint, Failure>> execute({
    required String goalId,
    required double value,
    String? notes,
    DateTime? recordedAt,
  }) {
    if (goalId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('ID da meta inválido.')),
      );
    }
    if (!value.isFinite) {
      return Future.value(
        const Err(ValidationFailure('Valor do checkpoint inválido.')),
      );
    }

    return _repository.addGoalCheckpoint(
      goalId: goalId,
      value: value,
      notes: notes,
      recordedAt: recordedAt,
    );
  }
}
