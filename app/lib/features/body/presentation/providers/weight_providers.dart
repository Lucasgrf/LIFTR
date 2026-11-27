import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/features/body/data/datasources/weight_remote_datasource.dart';
import 'package:personal_fitness_os/features/body/data/repositories/weight_repository_impl.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_stats.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/weight_repository.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/get_weight_history.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/get_weight_stats.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/upsert_daily_weight.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';

final weightRemoteDataSourceProvider = Provider<WeightRemoteDataSource>((ref) {
  return SupabaseWeightRemoteDataSource(ref.watch(supabaseClientProvider));
});

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  return WeightRepositoryImpl(ref.watch(weightRemoteDataSourceProvider));
});

final getWeightHistoryUseCaseProvider =
    Provider<GetWeightHistoryUseCase>((ref) {
  return GetWeightHistoryUseCase(ref.watch(weightRepositoryProvider));
});

final getWeightStatsUseCaseProvider = Provider<GetWeightStatsUseCase>((ref) {
  return GetWeightStatsUseCase(ref.watch(weightRepositoryProvider));
});

/// Nullable provider so callers remain safe when Supabase is unconfigured
/// in isolated tests unless [weightRepositoryProvider] is explicitly overridden.
final upsertDailyWeightUseCaseProvider = Provider<UpsertDailyWeightUseCase?>((
  ref,
) {
  try {
    return UpsertDailyWeightUseCase(ref.watch(weightRepositoryProvider));
  } catch (_) {
    return null;
  }
});

final weightStatsProvider =
    FutureProvider.autoDispose<WeightStats>((ref) async {
  final useCase = ref.watch(getWeightStatsUseCaseProvider);
  final result = await useCase.execute();

  return result.fold(
    (stats) => stats,
    (failure) => throw failure,
  );
});

final weightHistoryProvider =
    FutureProvider.autoDispose<List<WeightEntry>>((ref) async {
  final useCase = ref.watch(getWeightHistoryUseCaseProvider);
  final result = await useCase.execute();

  return result.fold(
    (history) => history,
    (failure) => throw failure,
  );
});
