import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/features/goals/data/datasources/goal_remote_datasource.dart';
import 'package:personal_fitness_os/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:personal_fitness_os/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';

final goalRemoteDataSourceProvider = Provider<GoalRemoteDataSource>((ref) {
  return SupabaseGoalRemoteDataSource(ref.watch(supabaseClientProvider));
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepositoryImpl(ref.watch(goalRemoteDataSourceProvider));
});
