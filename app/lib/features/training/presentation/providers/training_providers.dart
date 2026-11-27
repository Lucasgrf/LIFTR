import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/features/training/data/datasources/training_local_datasource.dart';
import 'package:personal_fitness_os/features/training/data/datasources/training_remote_datasource.dart';
import 'package:personal_fitness_os/features/training/data/repositories/training_repository_impl.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/add_exercise_to_workout.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/add_workout_to_plan.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/configure_set_templates.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/create_training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/delete_training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/get_active_training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/get_training_plan_by_id.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/get_training_plans.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/reorder_plan_workouts.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/reorder_workout_exercises.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/set_active_training_plan.dart';
import 'package:personal_fitness_os/routing/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- INFRASTRUCTURE PROVIDERS ---

final trainingRemoteDataSourceProvider = Provider<TrainingRemoteDataSource>((ref) {
  return SupabaseTrainingRemoteDataSource(Supabase.instance.client);
});

final trainingLocalDataSourceProvider = Provider<TrainingLocalDataSource?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs == null) return null;
  final userId = ref.watch(activeUserIdProvider);
  return TrainingLocalDataSource(prefs, userId: userId);
});

final trainingRepositoryProvider = Provider<TrainingRepository>((ref) {
  final remoteDataSource = ref.watch(trainingRemoteDataSourceProvider);
  final localDataSource = ref.watch(trainingLocalDataSourceProvider);
  final networkInfo = ref.watch(networkInfoProvider);

  return TrainingRepositoryImpl(
    remoteDataSource,
    localDataSource: localDataSource,
    networkInfo: networkInfo,
    isOfflineMode: () => ref.read(isOfflineModeProvider),
    onConnectivityFallback: (offline) {
      Future.microtask(() {
        ref.read(runtimeOfflineDetectedProvider.notifier).state = offline;
      });
    },
  );
});

// --- USE CASE PROVIDERS ---

final getTrainingPlansUseCaseProvider = Provider<GetTrainingPlansUseCase>((ref) {
  return GetTrainingPlansUseCase(ref.watch(trainingRepositoryProvider));
});

final getActiveTrainingPlanUseCaseProvider = Provider<GetActiveTrainingPlanUseCase>((ref) {
  return GetActiveTrainingPlanUseCase(ref.watch(trainingRepositoryProvider));
});

final getTrainingPlanByIdUseCaseProvider = Provider<GetTrainingPlanByIdUseCase>((ref) {
  return GetTrainingPlanByIdUseCase(ref.watch(trainingRepositoryProvider));
});

final createTrainingPlanUseCaseProvider = Provider<CreateTrainingPlanUseCase>((ref) {
  return CreateTrainingPlanUseCase(ref.watch(trainingRepositoryProvider));
});

final setActiveTrainingPlanUseCaseProvider = Provider<SetActiveTrainingPlanUseCase>((ref) {
  return SetActiveTrainingPlanUseCase(ref.watch(trainingRepositoryProvider));
});

final addWorkoutToPlanUseCaseProvider = Provider<AddWorkoutToPlanUseCase>((ref) {
  return AddWorkoutToPlanUseCase(ref.watch(trainingRepositoryProvider));
});

final addExerciseToWorkoutUseCaseProvider = Provider<AddExerciseToWorkoutUseCase>((ref) {
  return AddExerciseToWorkoutUseCase(ref.watch(trainingRepositoryProvider));
});

final configureSetTemplatesUseCaseProvider = Provider<ConfigureSetTemplatesUseCase>((ref) {
  return ConfigureSetTemplatesUseCase(ref.watch(trainingRepositoryProvider));
});

final reorderWorkoutExercisesUseCaseProvider = Provider<ReorderWorkoutExercisesUseCase>((ref) {
  return ReorderWorkoutExercisesUseCase(ref.watch(trainingRepositoryProvider));
});

final reorderPlanWorkoutsUseCaseProvider = Provider<ReorderPlanWorkoutsUseCase>((ref) {
  return ReorderPlanWorkoutsUseCase(ref.watch(trainingRepositoryProvider));
});

final deleteTrainingPlanUseCaseProvider = Provider<DeleteTrainingPlanUseCase>((ref) {
  return DeleteTrainingPlanUseCase(ref.watch(trainingRepositoryProvider));
});

// --- STATE NOTIFIERS ---

class TrainingPlansNotifier extends StateNotifier<AsyncValue<List<TrainingPlan>>> {
  TrainingPlansNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadPlans();
  }

  final Ref _ref;

  Future<void> loadPlans() async {
    await _fetchPlans(preserveExistingOnError: false);
  }

  Future<bool> refresh() => _fetchPlans(preserveExistingOnError: true);

  Future<bool> _fetchPlans({required bool preserveExistingOnError}) async {
    final previous = state;
    if (!preserveExistingOnError || !previous.hasValue) {
      state = const AsyncValue.loading();
    }
    final useCase = _ref.read(getTrainingPlansUseCaseProvider);
    final result = await useCase.execute();

    return result.fold(
      (plans) {
        state = AsyncValue.data(plans);
        return true;
      },
      (failure) {
        if (preserveExistingOnError && previous.hasValue) {
          state = previous;
        } else {
          state = AsyncValue.error(
            failure,
            failure.stackTrace ?? StackTrace.current,
          );
        }
        return false;
      },
    );
  }
}

final trainingPlansStateProvider =
    StateNotifierProvider<TrainingPlansNotifier, AsyncValue<List<TrainingPlan>>>((ref) {
  ref.watch(activeUserIdProvider);
  return TrainingPlansNotifier(ref);
});

/// Active training plan provider
final activeTrainingPlanProvider = Provider<TrainingPlan?>((ref) {
  final plansAsync = ref.watch(trainingPlansStateProvider);
  return plansAsync.when(
    data: (plans) => plans.where((p) => p.isActive).firstOrNull,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Training plan detail provider by plan ID
final trainingPlanDetailProvider =
    FutureProvider.autoDispose.family<TrainingPlan, String>((ref, planId) async {
  final useCase = ref.watch(getTrainingPlanByIdUseCaseProvider);
  final result = await useCase.execute(planId);

  return result.fold(
    (plan) => plan,
    (failure) => throw Exception(failure.message),
  );
});

/// Workout detail provider by looking inside the active / target plan
final workoutDetailProvider =
    FutureProvider.autoDispose.family<Workout, ({String planId, String workoutId})>(
        (ref, params) async {
  final plan = await ref.watch(trainingPlanDetailProvider(params.planId).future);
  final workout = plan.workouts.where((w) => w.id == params.workoutId).firstOrNull;

  if (workout == null) {
    throw Exception('Treino não encontrado.');
  }

  return workout;
});
