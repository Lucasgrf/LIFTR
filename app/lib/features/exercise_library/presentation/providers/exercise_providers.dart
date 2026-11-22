import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/exercise_library/data/datasources/exercise_remote_datasource.dart';
import 'package:personal_fitness_os/features/exercise_library/data/repositories/exercise_repository_impl.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/repositories/exercise_repository.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/usecases/create_custom_exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/usecases/get_exercise_by_id.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/usecases/get_exercises.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/usecases/search_exercises.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/usecases/update_exercise_notes.dart';
import 'package:personal_fitness_os/routing/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- INFRASTRUCTURE PROVIDERS ---

final exerciseRemoteDataSourceProvider = Provider<ExerciseRemoteDataSource>((ref) {
  return SupabaseExerciseRemoteDataSource(Supabase.instance.client);
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final remoteDataSource = ref.watch(exerciseRemoteDataSourceProvider);
  return ExerciseRepositoryImpl(remoteDataSource);
});

// --- USE CASE PROVIDERS ---

final getExercisesUseCaseProvider = Provider<GetExercisesUseCase>((ref) {
  return GetExercisesUseCase(ref.watch(exerciseRepositoryProvider));
});

final searchExercisesUseCaseProvider = Provider<SearchExercisesUseCase>((ref) {
  return SearchExercisesUseCase(ref.watch(exerciseRepositoryProvider));
});

final getExerciseByIdUseCaseProvider = Provider<GetExerciseByIdUseCase>((ref) {
  return GetExerciseByIdUseCase(ref.watch(exerciseRepositoryProvider));
});

final createCustomExerciseUseCaseProvider = Provider<CreateCustomExerciseUseCase>((ref) {
  return CreateCustomExerciseUseCase(ref.watch(exerciseRepositoryProvider));
});

final updateExerciseNotesUseCaseProvider = Provider<UpdateExerciseNotesUseCase>((ref) {
  return UpdateExerciseNotesUseCase(ref.watch(exerciseRepositoryProvider));
});

// --- FILTER & QUERY STATE PROVIDERS ---

final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');

final exerciseSelectedMuscleFilterProvider = StateProvider<String?>((ref) => null);

final exerciseSelectedEquipmentFilterProvider = StateProvider<String?>((ref) => null);

// --- LIST STATE NOTIFIER ---

class ExerciseListNotifier extends StateNotifier<AsyncValue<List<Exercise>>> {
  ExerciseListNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadExercises();
  }

  final Ref _ref;

  Future<void> loadExercises() async {
    state = const AsyncValue.loading();
    final useCase = _ref.read(getExercisesUseCaseProvider);
    final result = await useCase.execute();

    result.fold(
      (exercises) => state = AsyncValue.data(exercises),
      (failure) => state = AsyncValue.error(failure.message, failure.stackTrace ?? StackTrace.current),
    );
  }

  Future<void> refresh() => loadExercises();
}

final exerciseListStateProvider =
    StateNotifierProvider<ExerciseListNotifier, AsyncValue<List<Exercise>>>((ref) {
  ref.watch(activeUserIdProvider);
  return ExerciseListNotifier(ref);
});

/// Filtered exercises provider that reacts to search query and selected filters.
final filteredExercisesListProvider = Provider<AsyncValue<List<Exercise>>>((ref) {
  final asyncExercises = ref.watch(exerciseListStateProvider);
  final query = ref.watch(exerciseSearchQueryProvider).toLowerCase().trim();
  final selectedMuscle = ref.watch(exerciseSelectedMuscleFilterProvider);
  final selectedEquipment = ref.watch(exerciseSelectedEquipmentFilterProvider);

  return asyncExercises.whenData((exercises) {
    return exercises.where((exercise) {
      // Query filter
      if (query.isNotEmpty) {
        final matchesName = exercise.name.toLowerCase().contains(query);
        final matchesPrimary = exercise.primaryMuscleGroup.toLowerCase().contains(query);
        final matchesSecondary = exercise.secondaryMuscles.any(
          (m) => m.toLowerCase().contains(query),
        );
        final matchesEquipment = exercise.equipment != null &&
            exercise.equipment!.toLowerCase().contains(query);

        if (!matchesName && !matchesPrimary && !matchesSecondary && !matchesEquipment) {
          return false;
        }
      }

      // Muscle group filter
      if (selectedMuscle != null && selectedMuscle.isNotEmpty) {
        final normalizedSelected = selectedMuscle.toLowerCase();
        final matchesPrimary = exercise.primaryMuscleGroup.toLowerCase() == normalizedSelected;
        final matchesSecondary = exercise.secondaryMuscles.any(
          (m) => m.toLowerCase() == normalizedSelected,
        );

        if (!matchesPrimary && !matchesSecondary) {
          return false;
        }
      }

      // Equipment filter
      if (selectedEquipment != null && selectedEquipment.isNotEmpty) {
        if (exercise.equipment?.toLowerCase() != selectedEquipment.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  });
});

/// Detail provider for a specific exercise ID.
final exerciseDetailProvider =
    FutureProvider.family<Exercise, String>((ref, exerciseId) async {
  final useCase = ref.watch(getExerciseByIdUseCaseProvider);
  final result = await useCase.execute(exerciseId);

  return result.fold(
    (exercise) => exercise,
    (failure) => throw Exception(failure.message),
  );
});
