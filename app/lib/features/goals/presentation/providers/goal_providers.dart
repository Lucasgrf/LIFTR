import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/features/goals/data/datasources/goal_remote_datasource.dart';
import 'package:personal_fitness_os/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';
import 'package:personal_fitness_os/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/add_goal_checkpoint.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/create_goal.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/delete_goal.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/get_goal_by_id.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/get_goals.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/update_goal_status.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';

final goalRemoteDataSourceProvider = Provider<GoalRemoteDataSource>((ref) {
  return SupabaseGoalRemoteDataSource(ref.watch(supabaseClientProvider));
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepositoryImpl(ref.watch(goalRemoteDataSourceProvider));
});

final getGoalsUseCaseProvider = Provider<GetGoalsUseCase>((ref) {
  return GetGoalsUseCase(ref.watch(goalRepositoryProvider));
});

final getGoalByIdUseCaseProvider = Provider<GetGoalByIdUseCase>((ref) {
  return GetGoalByIdUseCase(ref.watch(goalRepositoryProvider));
});

final createGoalUseCaseProvider = Provider<CreateGoalUseCase>((ref) {
  return CreateGoalUseCase(ref.watch(goalRepositoryProvider));
});

final updateGoalStatusUseCaseProvider = Provider<UpdateGoalStatusUseCase>((ref) {
  return UpdateGoalStatusUseCase(ref.watch(goalRepositoryProvider));
});

final addGoalCheckpointUseCaseProvider =
    Provider<AddGoalCheckpointUseCase>((ref) {
  return AddGoalCheckpointUseCase(ref.watch(goalRepositoryProvider));
});

final deleteGoalUseCaseProvider = Provider<DeleteGoalUseCase>((ref) {
  return DeleteGoalUseCase(ref.watch(goalRepositoryProvider));
});

final goalStatusFilterProvider =
    StateProvider.autoDispose<GoalStatus?>((ref) => GoalStatus.active);

final goalsListProvider =
    FutureProvider.autoDispose<List<Goal>>((ref) async {
  final status = ref.watch(goalStatusFilterProvider);
  final useCase = ref.watch(getGoalsUseCaseProvider);
  final result = await useCase.execute(status: status);

  return result.fold(
    (goals) => goals,
    (failure) => throw failure,
  );
});

final goalDetailProvider =
    FutureProvider.autoDispose.family<Goal, String>((ref, goalId) async {
  final useCase = ref.watch(getGoalByIdUseCaseProvider);
  final result = await useCase.execute(goalId);

  return result.fold(
    (goal) => goal,
    (failure) => throw failure,
  );
});
