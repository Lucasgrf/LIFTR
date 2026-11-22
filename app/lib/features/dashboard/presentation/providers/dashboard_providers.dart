import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:personal_fitness_os/features/dashboard/domain/usecases/get_dashboard_data.dart';
import 'package:personal_fitness_os/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_fitness_os/features/history/data/datasources/history_remote_datasource.dart';
import 'package:personal_fitness_os/features/history/data/repositories/history_repository_impl.dart';
import 'package:personal_fitness_os/features/history/domain/repositories/history_repository.dart';
import 'package:personal_fitness_os/features/history/domain/usecases/get_workout_history.dart';
import 'package:personal_fitness_os/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/routing/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- History Providers ---

final historyRemoteDataSourceProvider = Provider<HistoryRemoteDataSource>((ref) {
  return SupabaseHistoryRemoteDataSource(Supabase.instance.client);
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl(ref.watch(historyRemoteDataSourceProvider));
});

final getWorkoutHistoryUseCaseProvider = Provider<GetWorkoutHistoryUseCase>((ref) {
  return GetWorkoutHistoryUseCase(ref.watch(historyRepositoryProvider));
});

// --- Dashboard Providers ---

final getDashboardDataUseCaseProvider = Provider<GetDashboardDataUseCase>((ref) {
  return GetDashboardDataUseCase(
    trainingRepository: ref.watch(trainingRepositoryProvider),
    sessionRepository: ref.watch(sessionRepositoryProvider),
    historyRepository: ref.watch(historyRepositoryProvider),
    nutritionRepository: ref.watch(nutritionRepositoryProvider),
    goalRepository: ref.watch(goalRepositoryProvider),
    localSessionDataSource: ref.watch(sessionLocalDataSourceProvider),
  );
});

final dashboardDataProvider =
    FutureProvider.autoDispose<DashboardData>((ref) async {
  ref.watch(activeUserIdProvider);
  final useCase = ref.watch(getDashboardDataUseCaseProvider);
  final result = await useCase.execute();

  return result.fold(
    (data) => data,
    (failure) => throw Exception(failure.message),
  );
});
