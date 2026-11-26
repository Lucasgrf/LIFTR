import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/history/domain/entities/exercise_history_record.dart';
import 'package:personal_fitness_os/features/history/domain/usecases/get_exercise_history.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/routing/app_router.dart';

final getExerciseHistoryUseCaseProvider =
    Provider<GetExerciseHistoryUseCase>((ref) {
  return GetExerciseHistoryUseCase(ref.watch(historyRepositoryProvider));
});

final exerciseHistoryProvider = FutureProvider.autoDispose
    .family<List<ExerciseHistoryRecord>, String>((ref, exerciseId) async {
  ref.watch(activeUserIdProvider);
  final useCase = ref.watch(getExerciseHistoryUseCaseProvider);
  final result = await useCase.execute(exerciseId);

  return result.fold(
    (records) => records,
    (failure) => throw failure,
  );
});

final historyListProvider =
    FutureProvider.autoDispose<List<WorkoutSession>>((ref) async {
  ref.watch(activeUserIdProvider);
  final useCase = ref.watch(getWorkoutHistoryUseCaseProvider);
  final result = await useCase.execute(limit: 50);

  return result.fold(
    (sessions) => sessions,
    (failure) => throw failure,
  );
});
