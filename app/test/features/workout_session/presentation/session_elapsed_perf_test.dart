import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/progression/domain/repositories/progression_repository.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/screens/workout_session_screen.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/session_elapsed_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoopProgressionRepository implements ProgressionRepository {
  @override
  Future<Result<ExercisePerformanceHistory?, Failure>>
      getLastExercisePerformance(String exerciseId) async =>
          const Success(null);

  @override
  Future<Result<List<ExercisePerformanceHistory>, Failure>>
      getRecentExercisePerformances(String exerciseId, {int limit = 2}) async =>
          const Success([]);
}

class _NoopSessionRepository implements SessionRepository {
  @override
  Future<Result<void, Failure>> abandonSession(String sessionId) async =>
      const Success(null);

  @override
  Future<Result<SessionExercise, Failure>> addExerciseToSession({
    required String sessionId,
    required String exerciseId,
    int sortOrder = 0,
    String? notes,
    int targetRestSeconds = AppConstants.defaultRestSeconds,
    int targetSetsCount = 3,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<void, Failure>> deleteLoggedSet(String setId) async =>
      const Success(null);

  @override
  Future<Result<LoggedSet, Failure>> restoreLoggedSet(LoggedSet set) async =>
      Success(set);

  @override
  Future<Result<WorkoutSession, Failure>> finishSession({
    required String sessionId,
    required int durationSeconds,
    double? perceivedExertion,
    int? executionScore,
    Mood? mood,
    String? notes,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<WorkoutSession?, Failure>> getActiveSession() async =>
      const Success(null);

  @override
  Future<Result<WorkoutSession, Failure>> getSessionById(String id) async =>
      throw UnimplementedError();

  @override
  Future<Result<LoggedSet, Failure>> logSet({
    required String sessionExerciseId,
    required int setNumber,
    SetType setType = SetType.working,
    required double weightKg,
    required int repsCompleted,
    int? durationSeconds,
    int? rirActual,
    double? rpeActual,
    int? restSecondsActual,
    ExecutionQuality? executionQuality,
    bool isWarmup = false,
    String? notes,
    List<DropSetEntry> dropSets = const [],
    String? existingSetId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<WorkoutSession, Failure>> startSession({
    String? workoutId,
    String? workoutName,
    List<SessionExercise>? initialExercises,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<SessionExercise, Failure>> swapSessionExercise({
    required String sessionExerciseId,
    required String newExerciseId,
    String? replacedExerciseId,
  }) async =>
      throw UnimplementedError();
}

class _NoopExerciseListNotifier extends ExerciseListNotifier {
  _NoopExerciseListNotifier(super.ref) {
    state = const AsyncValue.data([
      Exercise(
        id: 'ex-1',
        name: 'Supino Reto',
        primaryMuscleGroup: 'chest',
        equipment: 'barbell',
      ),
    ]);
  }

  @override
  Future<void> loadExercises() async {}
}

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('PERF-01 SessionElapsedText', () {
    testWidgets('shows real resumed elapsed time and ticks without rebuilding siblings',
        (tester) async {
      final startedAt = DateTime(2026, 11, 20, 18, 0, 0);
      var currentNow = DateTime(2026, 11, 20, 18, 18, 25);
      var siblingBuilds = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Column(
              children: [
                SessionElapsedText(
                  startedAt: startedAt,
                  nowProvider: () => currentNow,
                ),
                Builder(
                  builder: (_) {
                    siblingBuilds++;
                    return const Text('Sibling');
                  },
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('18:25'), findsOneWidget);
      expect(siblingBuilds, 1);

      for (var i = 1; i <= 5; i++) {
        currentNow = currentNow.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.text('18:30'), findsOneWidget);
      expect(siblingBuilds, 1);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
        'WorkoutSessionScreen shows resumed elapsed time and does not rebuild exercise ListView every second',
        (tester) async {
      final startedAt = DateTime(2026, 11, 20, 18, 0, 0);
      var currentNow = DateTime(2026, 11, 20, 18, 18, 25);

      final session = WorkoutSession(
        id: 'sess-resume',
        userId: 'u-1',
        workoutId: 'w-1',
        workoutName: 'Treino A',
        startedAt: startedAt,
        exercises: const [
          SessionExercise(
            id: 'se-1',
            sessionId: 'sess-resume',
            exerciseId: 'ex-1',
            exercise: Exercise(
              id: 'ex-1',
              name: 'Supino Reto',
              primaryMuscleGroup: 'chest',
              equipment: 'barbell',
            ),
            targetSetsCount: 3,
            targetRepsMin: 8,
            targetRepsMax: 12,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appClockProvider.overrideWithValue(() => currentNow),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
            liveSessionDetailProvider('sess-resume')
                .overrideWith((_) async => session),
            progressionRepositoryProvider
                .overrideWithValue(_NoopProgressionRepository()),
            sessionRepositoryProvider
                .overrideWithValue(_NoopSessionRepository()),
            exerciseListStateProvider
                .overrideWith((ref) => _NoopExerciseListNotifier(ref)),
            historyListProvider.overrideWith((_) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const WorkoutSessionScreen(sessionId: 'sess-resume'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('18:25'), findsOneWidget);
      expect(find.text('00:00'), findsNothing);

      final initialListView = tester.widget<ListView>(find.byType(ListView));

      for (var i = 0; i < 5; i++) {
        currentNow = currentNow.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.text('18:30'), findsOneWidget);
      final afterListView = tester.widget<ListView>(find.byType(ListView));
      expect(identical(initialListView, afterListView), isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
