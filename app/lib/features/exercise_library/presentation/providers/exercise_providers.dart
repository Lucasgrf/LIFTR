import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/features/exercise_library/data/datasources/exercise_local_datasource.dart';
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

final exerciseLocalDataSourceProvider = Provider<ExerciseLocalDataSource?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs == null) return null;
  final userId = ref.watch(activeUserIdProvider);
  return ExerciseLocalDataSource(prefs, userId: userId);
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final remoteDataSource = ref.watch(exerciseRemoteDataSourceProvider);
  final localDataSource = ref.watch(exerciseLocalDataSourceProvider);
  final networkInfo = ref.watch(networkInfoProvider);

  return ExerciseRepositoryImpl(
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
      (failure) => state = AsyncValue.error(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    );
  }

  Future<void> refresh() => loadExercises();
}

final exerciseListStateProvider =
    StateNotifierProvider<ExerciseListNotifier, AsyncValue<List<Exercise>>>((ref) {
  ref.watch(activeUserIdProvider);
  return ExerciseListNotifier(ref);
});

const Set<String> shoulderMuscleKeys = {
  'shoulders',
  'anterior_deltoid',
  'lateral_deltoid',
  'posterior_deltoid',
};

/// Returns whether [exercise] belongs to [selectedMuscle], treating
/// `'shoulders'` as inclusive of all deltoid sub-groups.
bool matchesMuscleGroupFilter(Exercise exercise, String selectedMuscle) {
  final normalizedSelected = selectedMuscle.toLowerCase().trim();
  if (normalizedSelected.isEmpty) return true;

  bool matchesValue(String raw) {
    final normalized = raw.toLowerCase().trim();
    if (normalizedSelected == 'shoulders' ||
        normalizedSelected.contains('deltoid') ||
        normalizedSelected.contains('shoulder')) {
      return shoulderMuscleKeys.contains(normalized) ||
          normalized.contains('deltoid') ||
          normalized.contains('shoulder');
    }
    return normalized == normalizedSelected;
  }

  if (matchesValue(exercise.primaryMuscleGroup)) return true;
  return exercise.secondaryMuscles.any(matchesValue);
}

/// Pure filter helper shared across exercise library & workout pickers.
List<Exercise> filterExercises(
  List<Exercise> exercises, {
  String query = '',
  String? selectedMuscle,
  String? selectedEquipment,
}) {
  final normalizedQuery = query.toLowerCase().trim();

  return exercises.where((exercise) {
    if (normalizedQuery.isNotEmpty) {
      final matchesName =
          exercise.name.toLowerCase().contains(normalizedQuery);
      final matchesPrimary =
          exercise.primaryMuscleGroup.toLowerCase().contains(normalizedQuery);
      final matchesSecondary = exercise.secondaryMuscles.any(
        (m) => m.toLowerCase().contains(normalizedQuery),
      );
      final matchesEquipment = exercise.equipment != null &&
          exercise.equipment!.toLowerCase().contains(normalizedQuery);

      if (!matchesName &&
          !matchesPrimary &&
          !matchesSecondary &&
          !matchesEquipment) {
        return false;
      }
    }

    if (selectedMuscle != null && selectedMuscle.trim().isNotEmpty) {
      if (!matchesMuscleGroupFilter(exercise, selectedMuscle)) {
        return false;
      }
    }

    if (selectedEquipment != null && selectedEquipment.trim().isNotEmpty) {
      if (exercise.equipment?.toLowerCase() !=
          selectedEquipment.toLowerCase()) {
        return false;
      }
    }

    return true;
  }).toList();
}

/// Filtered exercises provider that reacts to search query and selected filters.
final filteredExercisesListProvider = Provider<AsyncValue<List<Exercise>>>((ref) {
  final asyncExercises = ref.watch(exerciseListStateProvider);
  final query = ref.watch(exerciseSearchQueryProvider);
  final selectedMuscle = ref.watch(exerciseSelectedMuscleFilterProvider);
  final selectedEquipment = ref.watch(exerciseSelectedEquipmentFilterProvider);

  return asyncExercises.whenData(
    (exercises) => filterExercises(
      exercises,
      query: query,
      selectedMuscle: selectedMuscle,
      selectedEquipment: selectedEquipment,
    ),
  );
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
