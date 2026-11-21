import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/history/domain/entities/exercise_history_record.dart';
import 'package:personal_fitness_os/features/history/domain/entities/history_event_type.dart';
import 'package:personal_fitness_os/features/history/domain/entities/timeline_event.dart';
import 'package:personal_fitness_os/features/history/domain/usecases/get_exercise_history.dart';
import 'package:personal_fitness_os/features/history/domain/usecases/get_unified_timeline.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

final getUnifiedTimelineUseCaseProvider =
    Provider<GetUnifiedTimelineUseCase>((ref) {
  return GetUnifiedTimelineUseCase(ref.watch(historyRepositoryProvider));
});

final getExerciseHistoryUseCaseProvider =
    Provider<GetExerciseHistoryUseCase>((ref) {
  return GetExerciseHistoryUseCase(ref.watch(historyRepositoryProvider));
});

final timelineFilterTypeProvider =
    StateProvider.autoDispose<HistoryEventType?>((ref) => null);

final timelineFilterDaysProvider =
    StateProvider.autoDispose<int?>((ref) => null);

final unifiedTimelineProvider =
    FutureProvider.autoDispose<List<TimelineEvent>>((ref) async {
  final type = ref.watch(timelineFilterTypeProvider);
  final days = ref.watch(timelineFilterDaysProvider);

  DateTime? start;
  if (days != null) {
    start = DateTime.now().subtract(Duration(days: days));
  }

  final useCase = ref.watch(getUnifiedTimelineUseCaseProvider);
  final result = await useCase.execute(
    type: type,
    start: start,
    limit: 60,
  );

  return result.fold(
    (events) => events,
    (failure) => throw failure,
  );
});

final exerciseHistoryProvider = FutureProvider.autoDispose
    .family<List<ExerciseHistoryRecord>, String>((ref, exerciseId) async {
  final useCase = ref.watch(getExerciseHistoryUseCaseProvider);
  final result = await useCase.execute(exerciseId);

  return result.fold(
    (records) => records,
    (failure) => throw failure,
  );
});

final historyListProvider =
    FutureProvider.autoDispose<List<WorkoutSession>>((ref) async {
  final useCase = ref.watch(getWorkoutHistoryUseCaseProvider);
  final result = await useCase.execute(limit: 50);

  return result.fold(
    (sessions) => sessions,
    (failure) => throw failure,
  );
});
