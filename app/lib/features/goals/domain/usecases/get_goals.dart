import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';
import 'package:personal_fitness_os/features/goals/domain/repositories/goal_repository.dart';

class GetGoalsUseCase {
  const GetGoalsUseCase(this._repository);

  final GoalRepository _repository;

  Future<Result<List<Goal>, Failure>> execute({GoalStatus? status}) {
    return _repository.getGoals(status: status);
  }
}
