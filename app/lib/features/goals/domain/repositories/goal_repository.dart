import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_checkpoint.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';

abstract class GoalRepository {
  Future<Result<List<Goal>, Failure>> getGoals({GoalStatus? status});

  Future<Result<Goal, Failure>> getGoalById(String goalId);

  Future<Result<Goal, Failure>> createGoal(Goal goal);

  Future<Result<Goal, Failure>> updateGoalStatus(
      String goalId, GoalStatus status);

  Future<Result<GoalCheckpoint, Failure>> addGoalCheckpoint({
    required String goalId,
    required double value,
    String? notes,
    DateTime? recordedAt,
  });

  Future<Result<void, Failure>> deleteGoal(String goalId);
}
