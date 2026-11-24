import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/theme/theme_provider.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_weight_view.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/progression/domain/repositories/progression_repository.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/workout_queue_provider.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/screens/workout_session_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubProgressionRepository implements ProgressionRepository {
  @override
  Future<Result<ExercisePerformanceHistory?, Failure>>
      getLastExercisePerformance(String exerciseId) async =>
          const Success(null);

  @override
  Future<Result<List<ExercisePerformanceHistory>, Failure>>
      getRecentExercisePerformances(
    String exerciseId, {
    int limit = 2,
  }) async =>
          const Success([]);
}

class _StubExerciseListNotifier extends ExerciseListNotifier {
  _StubExerciseListNotifier(super.ref, List<Exercise> exercises) {
    state = AsyncValue.data(exercises);
  }

  @override
  Future<void> loadExercises() async {}
}

class _RecordingSessionRepository implements SessionRepository {
  _RecordingSessionRepository({
    required WorkoutSession initialSession,
    required Map<String, Exercise> exercisesById,
    this.shouldFailSwap = false,
  }) : _session = initialSession,
       _exercisesById = exercisesById;

  WorkoutSession _session;
  final Map<String, Exercise> _exercisesById;
  final bool shouldFailSwap;

  final List<({String sessionExerciseId, String newExerciseId, String? replaced})>
      swapCalls = [];

  @override
  Future<Result<WorkoutSession, Failure>> getSessionById(String id) async =>
      Success(_session);

  @override
  Future<Result<SessionExercise, Failure>> swapSessionExercise({
    required String sessionExerciseId,
    required String newExerciseId,
    String? replacedExerciseId,
  }) async {
    swapCalls.add((
      sessionExerciseId: sessionExerciseId,
      newExerciseId: newExerciseId,
      replaced: replacedExerciseId,
    ));

    if (shouldFailSwap) {
      return const Err(ServerFailure('Falha ao salvar substituição'));
    }

    final replacement = _exercisesById[newExerciseId];
    SessionExercise? updatedExercise;
    final nextExercises = _session.exercises.map((se) {
      if (se.id != sessionExerciseId) return se;
      updatedExercise = se.copyWith(
        exerciseId: newExerciseId,
        replacedExerciseId: replacedExerciseId,
        exercise: replacement,
      );
      return updatedExercise!;
    }).toList();

    _session = _session.copyWith(exercises: nextExercises);
    return Success(updatedExercise ?? _session.exercises.first);
  }

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
  }) async {
    return Success(
      SessionExercise(
        id: 'new-se',
        sessionId: sessionId,
        exerciseId: exerciseId,
      ),
    );
  }

  @override
  Future<Result<void, Failure>> deleteLoggedSet(String setId) async =>
      const Success(null);

  @override
  Future<Result<WorkoutSession, Failure>> finishSession({
    required String sessionId,
    required int durationSeconds,
    double? perceivedExertion,
    int? executionScore,
    Mood? mood,
    String? notes,
  }) async => Success(_session);

  @override
  Future<Result<WorkoutSession?, Failure>> getActiveSession() async =>
      const Success(null);

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
  }) async {
    return Success(
      LoggedSet(
        id: existingSetId ?? 'logged-$setNumber',
        sessionExerciseId: sessionExerciseId,
        setNumber: setNumber,
        setType: setType,
        weightKg: weightKg,
        repsCompleted: repsCompleted,
        durationSeconds: durationSeconds,
        dropSets: dropSets,
      ),
    );
  }

  @override
  Future<Result<WorkoutSession, Failure>> startSession({
    String? workoutId,
    String? workoutName,
    List<SessionExercise>? initialExercises,
  }) async => Success(_session);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  group('Connectivity & Theme Providers', () {
    test('simulatedOfflineProvider resides in connectivity_providers and defaults false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(simulatedOfflineProvider), isFalse);
      container.read(simulatedOfflineProvider.notifier).state = true;
      expect(container.read(simulatedOfflineProvider), isTrue);
    });

    test('ThemeModeNotifier persists ThemeMode across restarts', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container1 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      expect(container1.read(themeModeProvider), ThemeMode.dark);
      container1.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container1.read(themeModeProvider), ThemeMode.light);
      container1.dispose();

      final container2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      expect(container2.read(themeModeProvider), ThemeMode.light);
      container2.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
      container2.dispose();

      final container3 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      expect(container3.read(themeModeProvider), ThemeMode.system);
      container3.dispose();
    });
  });

  group('UserSettingsNotifier Persistence', () {
    test('round-trips all settings fields through SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final notifier1 = UserSettingsNotifier(prefs);
      notifier1.updateBodyData(
        biologicalSex: 'F',
        age: 31,
        heightCm: 165,
        weightKg: 62.5,
        bodyFatPercent: 21.0,
      );
      notifier1.setGoal(UserGoal.cutting);
      notifier1.setExperience(UserExperience.beginner);
      notifier1.setActivityLevel(ActivityLevel.veryActive);
      notifier1.setSchedule(daysPerWeek: 5, splitName: 'Push / Pull / Legs');
      notifier1.setEquipmentIncrement(barbell: 5.0, dumbbell: 1.0, machine: 2.5);
      notifier1.setWeeklyReportSchedule('Segunda', '08:30');
      notifier1.setQuietHoursEnabled(false);
      notifier1.completeOnboarding(whatsappConnected: false);

      final restored = UserSettingsNotifier(prefs).state;
      expect(restored.biologicalSex, 'F');
      expect(restored.age, 31);
      expect(restored.heightCm, 165);
      expect(restored.weightKg, 62.5);
      expect(restored.bodyFatPercent, 21.0);
      expect(restored.goal, UserGoal.cutting);
      expect(restored.experience, UserExperience.beginner);
      expect(restored.activityLevel, ActivityLevel.veryActive);
      expect(restored.trainingDaysPerWeek, 5);
      expect(restored.selectedSplitName, 'Push / Pull / Legs');
      expect(restored.barbellIncrementKg, 5.0);
      expect(restored.dumbbellIncrementKg, 1.0);
      expect(restored.machineIncrementKg, 2.5);
      expect(restored.whatsappConnected, isFalse);
      expect(restored.weeklyReportDay, 'Segunda');
      expect(restored.weeklyReportTime, '08:30');
      expect(restored.quietHoursEnabled, isFalse);
      expect(restored.onboardingCompleted, isTrue);
    });

    test('recovers safely with defaults when stored JSON is corrupt', () async {
      SharedPreferences.setMockInitialValues({
        'liftr_user_settings_v1': '{invalid-json',
      });
      final prefs = await SharedPreferences.getInstance();

      final restored = UserSettingsNotifier(prefs).state;
      expect(restored.goal, UserGoal.bulking);
      expect(restored.weightKg, 78.4);
      expect(restored.onboardingCompleted, isFalse);
    });
  });

  group('WorkoutQueueNotifier Persistence', () {
    const w1 = Workout(id: 'w1', trainingPlanId: 'p1', name: 'A', sortOrder: 0);
    const w2 = Workout(id: 'w2', trainingPlanId: 'p1', name: 'B', sortOrder: 1);
    const w3 = Workout(id: 'w3', trainingPlanId: 'p1', name: 'C', sortOrder: 2);
    const workouts = [w1, w2, w3];

    test('persists reorder, skipFirstToEnd, selectNext and invokes sync', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final syncedOrders = <(String, List<String>)>[];

      final notifier1 = WorkoutQueueNotifier(
        prefs: prefs,
        onRemoteSync: (planId, ids) async {
          syncedOrders.add((planId, ids));
        },
      );

      notifier1.reorder('p1', workouts, 0, 3);
      expect(
        notifier1.orderedWorkouts('p1', workouts).map((w) => w.id),
        ['w2', 'w3', 'w1'],
      );

      notifier1.skipFirstToEnd('p1', notifier1.orderedWorkouts('p1', workouts));
      expect(
        notifier1.orderedWorkouts('p1', workouts).map((w) => w.id),
        ['w3', 'w1', 'w2'],
      );

      notifier1.selectNext('p1', notifier1.orderedWorkouts('p1', workouts), 'w2');
      expect(
        notifier1.orderedWorkouts('p1', workouts).map((w) => w.id),
        ['w2', 'w3', 'w1'],
      );

      expect(syncedOrders.length, 3);
      expect(syncedOrders.last.$1, 'p1');
      expect(syncedOrders.last.$2, ['w2', 'w3', 'w1']);

      final notifier2 = WorkoutQueueNotifier(prefs: prefs);
      expect(
        notifier2.orderedWorkouts('p1', workouts).map((w) => w.id),
        ['w2', 'w3', 'w1'],
      );
    });
  });

  group('computeWindowedWeightEmaSeries', () {
    test('retains prior EMA seed across cutoff boundary', () {
      final now = DateTime(2026, 11, 20);
      final entries = [
        WeightEntry(
          id: 'e1',
          weightKg: 70.0,
          measuredAt: now.subtract(const Duration(days: 45)),
        ),
        WeightEntry(
          id: 'e2',
          weightKg: 80.0,
          measuredAt: now.subtract(const Duration(days: 10)),
        ),
      ];

      final cutoff = now.subtract(const Duration(days: 30));
      final windowed = computeWindowedWeightEmaSeries(entries, cutoff: cutoff);

      expect(windowed.length, 1);
      // 0.25 * 80.0 + 0.75 * 70.0 = 72.5 (NOT 80.0 as a naive post-filter reset would yield)
      expect(windowed.first.rawKg, 80.0);
      expect(windowed.first.emaKg, closeTo(72.5, 0.0001));
    });
  });

  group('WorkoutSessionScreen Swap Persistence', () {
    const squat = Exercise(
      id: 'ex-squat',
      name: 'Agachamento Livre',
      primaryMuscleGroup: 'legs',
      equipment: 'barbell',
    );
    const hack = Exercise(
      id: 'ex-hack',
      name: 'Hack Squat',
      primaryMuscleGroup: 'legs',
      equipment: 'machine',
    );

    final baseSession = WorkoutSession(
      id: 'sess-1',
      userId: 'u-1',
      workoutId: 'w-lower',
      workoutName: 'Lower A',
      startedAt: DateTime(2026, 11, 20, 18, 0),
      exercises: const [
        SessionExercise(
          id: 'se-1',
          sessionId: 'sess-1',
          exerciseId: 'ex-squat',
          exercise: squat,
          targetSetsCount: 3,
          targetRepsMin: 8,
          targetRepsMax: 12,
        ),
      ],
    );

    Widget buildSessionApp(_RecordingSessionRepository repo) {
      return ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(repo),
          progressionRepositoryProvider
              .overrideWithValue(_StubProgressionRepository()),
          exerciseListStateProvider.overrideWith(
            (ref) => _StubExerciseListNotifier(ref, const [squat, hack]),
          ),
          historyListProvider.overrideWith((_) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const WorkoutSessionScreen(sessionId: 'sess-1'),
        ),
      );
    }

    testWidgets('persists swap via SessionRepository without blocking rest controls',
        (tester) async {
      final repo = _RecordingSessionRepository(
        initialSession: baseSession,
        exercisesById: const {'ex-squat': squat, 'ex-hack': hack},
      );

      await tester.pumpWidget(buildSessionApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trocar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hack Squat'));
      await tester.pumpAndSettle();

      expect(repo.swapCalls.length, 1);
      expect(repo.swapCalls.first.sessionExerciseId, 'se-1');
      expect(repo.swapCalls.first.newExerciseId, 'ex-hack');
      expect(repo.swapCalls.first.replaced, 'ex-squat');
      expect(find.text('Hack Squat'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('rolls back optimistic swap and shows error SnackBar on failure',
        (tester) async {
      final repo = _RecordingSessionRepository(
        initialSession: baseSession,
        exercisesById: const {'ex-squat': squat, 'ex-hack': hack},
        shouldFailSwap: true,
      );

      await tester.pumpWidget(buildSessionApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trocar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hack Squat'));
      await tester.pumpAndSettle();

      expect(repo.swapCalls.length, 1);
      expect(find.text('Agachamento Livre'), findsOneWidget);
      expect(find.text('Hack Squat'), findsNothing);
      expect(find.textContaining('Erro ao trocar exercício'), findsOneWidget);
    });
  });
}
