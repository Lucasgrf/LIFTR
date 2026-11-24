import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/features/progression/data/datasources/progression_remote_datasource.dart';
import 'package:personal_fitness_os/features/progression/data/repositories/progression_repository_impl.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/progression_recommendation.dart';
import 'package:personal_fitness_os/features/progression/domain/repositories/progression_repository.dart';
import 'package:personal_fitness_os/features/progression/domain/usecases/calculate_progression.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final progressionRemoteDataSourceProvider =
    Provider<ProgressionRemoteDataSource>((ref) {
  return SupabaseProgressionRemoteDataSource(ref.watch(supabaseClientProvider));
});

final progressionRepositoryProvider = Provider<ProgressionRepository>((ref) {
  return ProgressionRepositoryImpl(
    ref.watch(progressionRemoteDataSourceProvider),
    localSessionDataSource: ref.watch(sessionLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
    isOfflineMode: () => ref.read(isOfflineModeProvider),
    onConnectivityFallback: (offline) {
      Future.microtask(() {
        ref.read(runtimeOfflineDetectedProvider.notifier).state = offline;
      });
    },
  );
});

final calculateProgressionUseCaseProvider =
    Provider<CalculateProgressionUseCase>((ref) {
  return CalculateProgressionUseCase(
    repository: ref.watch(progressionRepositoryProvider),
  );
});

class ExerciseProgressionParams {
  const ExerciseProgressionParams({
    required this.exerciseId,
    required this.targetRepsMin,
    required this.targetRepsMax,
    this.targetRir = 2,
    this.equipment,
  });

  final String exerciseId;
  final int targetRepsMin;
  final int targetRepsMax;
  final int targetRir;
  final String? equipment;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseProgressionParams &&
        other.exerciseId == exerciseId &&
        other.targetRepsMin == targetRepsMin &&
        other.targetRepsMax == targetRepsMax &&
        other.targetRir == targetRir &&
        other.equipment == equipment;
  }

  @override
  int get hashCode => Object.hash(
        exerciseId,
        targetRepsMin,
        targetRepsMax,
        targetRir,
        equipment,
      );
}

final exerciseProgressionProvider = FutureProvider.autoDispose
    .family<ProgressionRecommendation, ExerciseProgressionParams>(
        (ref, params) async {
  final useCase = ref.watch(calculateProgressionUseCaseProvider);
  final result = await useCase.execute(
    exerciseId: params.exerciseId,
    targetRepsMin: params.targetRepsMin,
    targetRepsMax: params.targetRepsMax,
    targetRir: params.targetRir,
    equipment: params.equipment,
  );

  return result.fold(
    (recommendation) => recommendation,
    (failure) => throw failure,
  );
});
