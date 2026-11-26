import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/widgets/liftr_brand_mark.dart';
import 'package:personal_fitness_os/features/auth/presentation/screens/login_screen.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_stats.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/screens/history_screen.dart';
import 'package:personal_fitness_os/features/insights/domain/entities/fitness_insight.dart';
import 'package:personal_fitness_os/features/insights/presentation/providers/insight_providers.dart';
import 'package:personal_fitness_os/features/profile/presentation/screens/profile_screen.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/progression/domain/repositories/progression_repository.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';
import 'package:personal_fitness_os/features/settings/presentation/screens/settings_screen.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/training_list_screen.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_comparison_data.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_snapshot.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/providers/weekly_comparison_providers.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/screens/session_summary_screen.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/screens/workout_session_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'golden_test_helpers.dart';

class _GoldenProgressionRepository implements ProgressionRepository {
  @override
  Future<Result<ExercisePerformanceHistory?, Failure>>
      getLastExercisePerformance(String exerciseId) async {
    return Success(
      ExercisePerformanceHistory(
        exerciseId: exerciseId,
        workoutSessionId: 'prev-sess',
        workoutName: 'Lower A',
        date: kFixedGoldenNow.subtract(const Duration(days: 4)),
        loggedSets: const [
          LoggedSet(
            id: 'prev-1',
            sessionExerciseId: 'prev-se',
            setNumber: 1,
            weightKg: 60,
            repsCompleted: 12,
            rirActual: 2,
          ),
          LoggedSet(
            id: 'prev-2',
            sessionExerciseId: 'prev-se',
            setNumber: 2,
            weightKg: 60,
            repsCompleted: 12,
            rirActual: 2,
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<List<ExercisePerformanceHistory>, Failure>>
      getRecentExercisePerformances(String exerciseId, {int limit = 2}) async {
    final single = await getLastExercisePerformance(exerciseId);
    return single.fold(
      (data) => Success(data == null ? const [] : [data]),
      (f) => Err(f),
    );
  }
}

class _GoldenSessionRepository implements SessionRepository {
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
        id: 'se-added',
        sessionId: sessionId,
        exerciseId: exerciseId,
        sortOrder: sortOrder,
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
  }) async {
    return Success(
      WorkoutSession(
        id: sessionId,
        userId: 'u-1',
        startedAt: kFixedGoldenNow.subtract(const Duration(minutes: 48)),
        completedAt: kFixedGoldenNow,
        status: SessionStatus.completed,
        durationSeconds: durationSeconds,
        perceivedExertion: perceivedExertion,
        executionScore: executionScore,
      ),
    );
  }

  @override
  Future<Result<WorkoutSession?, Failure>> getActiveSession() async =>
      const Success(null);

  @override
  Future<Result<WorkoutSession, Failure>> getSessionById(String id) async {
    return Success(
      WorkoutSession(
        id: id,
        userId: 'u-1',
        startedAt: kFixedGoldenNow,
      ),
    );
  }

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
        id: existingSetId ?? 'ls-$setNumber',
        sessionExerciseId: sessionExerciseId,
        setNumber: setNumber,
        setType: setType,
        weightKg: weightKg,
        repsCompleted: repsCompleted,
        durationSeconds: durationSeconds,
        rirActual: rirActual,
        isWarmup: isWarmup,
        dropSets: dropSets,
      ),
    );
  }

  @override
  Future<Result<WorkoutSession, Failure>> startSession({
    String? workoutId,
    String? workoutName,
    List<SessionExercise>? initialExercises,
  }) async {
    return Success(
      WorkoutSession(
        id: 'sess-new',
        userId: 'u-1',
        workoutId: workoutId,
        workoutName: workoutName ?? 'Treino',
        startedAt: kFixedGoldenNow,
      ),
    );
  }

  @override
  Future<Result<SessionExercise, Failure>> swapSessionExercise({
    required String sessionExerciseId,
    required String newExerciseId,
    String? replacedExerciseId,
  }) async {
    return Success(
      SessionExercise(
        id: sessionExerciseId,
        sessionId: 'sess-1',
        exerciseId: newExerciseId,
        replacedExerciseId: replacedExerciseId,
      ),
    );
  }
}

class _GoldenTrainingPlansNotifier extends TrainingPlansNotifier {
  _GoldenTrainingPlansNotifier(super.ref, List<TrainingPlan> plans) {
    state = AsyncValue.data(plans);
  }

  @override
  Future<void> loadPlans() async {}
}

class _GoldenExerciseListNotifier extends ExerciseListNotifier {
  _GoldenExerciseListNotifier(super.ref, List<Exercise> exercises) {
    state = AsyncValue.data(exercises);
  }

  @override
  Future<void> loadExercises() async {}
}

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    prefs = await initializeGoldenTest();
  });

  const tSquat = Exercise(
    id: 'ex-squat',
    name: 'Agachamento Livre',
    primaryMuscleGroup: 'legs',
    equipment: 'barbell',
  );
  const tBench = Exercise(
    id: 'ex-bench',
    name: 'Supino Reto',
    primaryMuscleGroup: 'chest',
    equipment: 'barbell',
  );

  const tLowerA = Workout(
    id: 'w-lower-a',
    trainingPlanId: 'p-1',
    name: 'Lower A',
    dayOfWeek: 1,
    sortOrder: 0,
    estimatedDurationMinutes: 50,
    exercises: [
      WorkoutExercise(
        id: 'we-1',
        workoutId: 'w-lower-a',
        exerciseId: 'ex-squat',
        exercise: tSquat,
        setTemplates: [
          SetTemplate(
            id: 'st-1',
            workoutExerciseId: 'we-1',
            setNumber: 1,
            targetRepsMin: 8,
            targetRepsMax: 12,
            targetWeight: 60,
          ),
          SetTemplate(
            id: 'st-2',
            workoutExerciseId: 'we-1',
            setNumber: 2,
            targetRepsMin: 8,
            targetRepsMax: 12,
            targetWeight: 60,
          ),
        ],
      ),
    ],
  );

  const tUpperB = Workout(
    id: 'w-upper-b',
    trainingPlanId: 'p-1',
    name: 'Upper B',
    dayOfWeek: 3,
    sortOrder: 1,
    estimatedDurationMinutes: 48,
    exercises: [
      WorkoutExercise(
        id: 'we-2',
        workoutId: 'w-upper-b',
        exerciseId: 'ex-bench',
        exercise: tBench,
        setTemplates: [
          SetTemplate(
            id: 'st-3',
            workoutExerciseId: 'we-2',
            setNumber: 1,
            targetRepsMin: 8,
            targetRepsMax: 12,
            targetWeight: 70,
          ),
        ],
      ),
    ],
  );

  const tPlan = TrainingPlan(
    id: 'p-1',
    userId: 'u-1',
    name: 'Upper / Lower',
    isActive: true,
    workouts: [tLowerA, tUpperB],
  );

  final tCompletedSession = WorkoutSession(
    id: 'sess-prev',
    userId: 'u-1',
    workoutId: 'w-upper-b',
    workoutName: 'Upper B',
    startedAt: kFixedGoldenNow.subtract(const Duration(days: 2, hours: 1)),
    completedAt: kFixedGoldenNow.subtract(const Duration(days: 2)),
    durationSeconds: 2940,
    status: SessionStatus.completed,
    perceivedExertion: 8.5,
    executionScore: 92,
    mood: Mood.good,
    exercises: const [
      SessionExercise(
        id: 'se-done-1',
        sessionId: 'sess-prev',
        exerciseId: 'ex-bench',
        exercise: tBench,
        targetSetsCount: 3,
        targetRepsMin: 8,
        targetRepsMax: 12,
        sets: [
          LoggedSet(
            id: 'ls-d1',
            sessionExerciseId: 'se-done-1',
            setNumber: 1,
            weightKg: 70,
            repsCompleted: 10,
          ),
          LoggedSet(
            id: 'ls-d2',
            sessionExerciseId: 'se-done-1',
            setNumber: 2,
            weightKg: 70,
            repsCompleted: 10,
          ),
          LoggedSet(
            id: 'ls-d3',
            sessionExerciseId: 'se-done-1',
            setNumber: 3,
            weightKg: 70,
            repsCompleted: 10,
          ),
        ],
      ),
    ],
  );

  final tActiveSessionWithDrop = WorkoutSession(
    id: 'sess-active',
    userId: 'u-1',
    workoutId: 'w-lower-a',
    workoutName: 'Lower A',
    startedAt: kFixedGoldenNow.subtract(
      const Duration(minutes: 42, seconds: 15),
    ),
    durationSeconds: 2535,
    exercises: const [
      SessionExercise(
        id: 'se-1',
        sessionId: 'sess-active',
        exerciseId: 'ex-squat',
        exercise: tSquat,
        targetSetsCount: 2,
        targetRepsMin: 8,
        targetRepsMax: 12,
        sets: [
          LoggedSet(
            id: 'ls-1',
            sessionExerciseId: 'se-1',
            setNumber: 1,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 10,
          ),
          LoggedSet(
            id: 'ls-2',
            sessionExerciseId: 'se-1',
            setNumber: 2,
            setType: SetType.dropSet,
            weightKg: 70.0,
            repsCompleted: 10,
            dropSets: [
              DropSetEntry(weightKg: 50.0, repsCompleted: 12),
            ],
          ),
        ],
      ),
      SessionExercise(
        id: 'se-2',
        sessionId: 'sess-active',
        exerciseId: 'ex-bench',
        exercise: tBench,
        targetSetsCount: 2,
        targetRepsMin: 8,
        targetRepsMax: 12,
        sets: [
          LoggedSet(
            id: 'ls-3',
            sessionExerciseId: 'se-2',
            setNumber: 1,
            setType: SetType.working,
            weightKg: 65.0,
            repsCompleted: 10,
          ),
        ],
      ),
    ],
  );

  final tActiveSessionFourSets = WorkoutSession(
    id: 'sess-4sets',
    userId: 'u-1',
    workoutId: 'w-lower-a',
    workoutName: 'Lower A',
    startedAt: kFixedGoldenNow.subtract(
      const Duration(minutes: 42, seconds: 15),
    ),
    durationSeconds: 2535,
    exercises: const [
      SessionExercise(
        id: 'se-4sets-1',
        sessionId: 'sess-4sets',
        exerciseId: 'ex-squat',
        exercise: tSquat,
        targetSetsCount: 4,
        targetRepsMin: 8,
        targetRepsMax: 12,
        sets: [
          LoggedSet(
            id: 'ls-4-1',
            sessionExerciseId: 'se-4sets-1',
            setNumber: 1,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 10,
          ),
          LoggedSet(
            id: 'ls-4-2',
            sessionExerciseId: 'se-4sets-1',
            setNumber: 2,
            setType: SetType.dropSet,
            weightKg: 80.0,
            repsCompleted: 10,
            dropSets: [
              DropSetEntry(weightKg: 60.0, repsCompleted: 8),
            ],
          ),
          LoggedSet(
            id: 'ls-4-3',
            sessionExerciseId: 'se-4sets-1',
            setNumber: 3,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 9,
          ),
        ],
      ),
    ],
  );

  final tSummarySession = tActiveSessionWithDrop.copyWith(
    status: SessionStatus.completed,
    completedAt: kFixedGoldenNow,
    durationSeconds: 3120,
    perceivedExertion: 8.5,
    executionScore: 95,
    mood: Mood.excellent,
  );

  final tWeekStart = DateTime(2026, 11, 16);
  final tWeekSummary = WeeklyComparisonData(
    currentWeek: WeeklySnapshot(
      weekStart: tWeekStart,
      weekEnd: tWeekStart.add(const Duration(days: 6)),
      workoutsCompleted: 3,
      cardioDurationSeconds: 3600,
      trainingDurationSeconds: 9000,
      workingSetsCount: 36,
      totalVolumeKg: 12400,
      avgRpe: 8.3,
      avgExecutionScore: 93,
    ),
    previousWeek: WeeklySnapshot(
      weekStart: tWeekStart.subtract(const Duration(days: 7)),
      weekEnd: tWeekStart.subtract(const Duration(days: 1)),
      workoutsCompleted: 3,
      cardioDurationSeconds: 2400,
      trainingDurationSeconds: 8400,
      workingSetsCount: 32,
      totalVolumeKg: 11100,
      avgRpe: 8.1,
      avgExecutionScore: 90,
    ),
  );

  for (final entry in {
    'dark': ThemeMode.dark,
    'light': ThemeMode.light,
  }.entries) {
    final themeLabel = entry.key;
    final themeMode = entry.value;

    group('Baseline Goldens ($themeLabel)', () {
      testWidgets('Dashboard (Hoje)', (tester) async {
        final dashboardData = DashboardData(
          activePlan: tPlan,
          todayWorkout: tLowerA,
          lastCompletedSession: tCompletedSession,
        );
        final insights = [
          FitnessInsight(
            id: 'in-1',
            title: 'Agachamento pronto para subir',
            description: 'Complete 2x12 hoje para liberar 62,5 kg.',
            category: InsightCategory.consistency,
            severity: InsightSeverity.success,
            createdAt: kFixedGoldenNow,
          ),
        ];

        await pumpGoldenWidget(
          tester,
          themeMode: themeMode,
          prefs: prefs,
          child: const DashboardScreen(),
          overrides: [
            dashboardDataProvider.overrideWith((_) async => dashboardData),
            currentWeekSummaryProvider.overrideWith((_) async => tWeekSummary),
            fitnessInsightsProvider.overrideWith((_) async => insights),
            progressionRepositoryProvider
                .overrideWithValue(_GoldenProgressionRepository()),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          ],
        );

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('pngs/dashboard_$themeLabel.png'),
        );
      });

      testWidgets('WorkoutSessionScreen active with 2 exercises + drop-set',
          (tester) async {
        await pumpGoldenWidget(
          tester,
          themeMode: themeMode,
          prefs: prefs,
          settle: false,
          child: const WorkoutSessionScreen(sessionId: 'sess-active'),
          overrides: [
            liveSessionDetailProvider('sess-active')
                .overrideWith((_) async => tActiveSessionWithDrop),
            progressionRepositoryProvider
                .overrideWithValue(_GoldenProgressionRepository()),
            sessionRepositoryProvider
                .overrideWithValue(_GoldenSessionRepository()),
            exerciseListStateProvider.overrideWith(
              (ref) => _GoldenExerciseListNotifier(ref, [tSquat, tBench]),
            ),
            historyListProvider.overrideWith((_) async => [tCompletedSession]),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          ],
        );

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('pngs/workout_session_$themeLabel.png'),
        );

        // Dispose active Timer.periodic cleanly before teardown check.
        await tester.pumpWidget(const SizedBox.shrink());
      });

      if (themeLabel == 'dark') {
        for (final spec in const [(360.0, 800.0), (393.0, 852.0), (412.0, 915.0)]) {
          final width = spec.$1;
          final height = spec.$2;
          testWidgets('WorkoutSessionScreen active at ${width.toInt()}dp',
              (tester) async {
            await pumpGoldenWidget(
              tester,
              themeMode: themeMode,
              prefs: prefs,
              settle: false,
              width: width,
              height: height,
              child: const WorkoutSessionScreen(sessionId: 'sess-active'),
              overrides: [
                liveSessionDetailProvider('sess-active')
                    .overrideWith((_) async => tActiveSessionWithDrop),
                progressionRepositoryProvider
                    .overrideWithValue(_GoldenProgressionRepository()),
                sessionRepositoryProvider
                    .overrideWithValue(_GoldenSessionRepository()),
                exerciseListStateProvider.overrideWith(
                  (ref) => _GoldenExerciseListNotifier(ref, [tSquat, tBench]),
                ),
                historyListProvider
                    .overrideWith((_) async => [tCompletedSession]),
                isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
              ],
            );

            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('pngs/workout_session_dark_${width.toInt()}.png'),
            );

            await tester.pumpWidget(const SizedBox.shrink());
          });

          testWidgets(
              'WorkoutSessionScreen 4 sets (1 active, 3 completed) at ${width.toInt()}dp',
              (tester) async {
            await pumpGoldenWidget(
              tester,
              themeMode: themeMode,
              prefs: prefs,
              settle: false,
              width: width,
              height: height,
              child: const WorkoutSessionScreen(sessionId: 'sess-4sets'),
              overrides: [
                liveSessionDetailProvider('sess-4sets')
                    .overrideWith((_) async => tActiveSessionFourSets),
                progressionRepositoryProvider
                    .overrideWithValue(_GoldenProgressionRepository()),
                sessionRepositoryProvider
                    .overrideWithValue(_GoldenSessionRepository()),
                exerciseListStateProvider.overrideWith(
                  (ref) => _GoldenExerciseListNotifier(ref, [tSquat, tBench]),
                ),
                historyListProvider
                    .overrideWith((_) async => [tCompletedSession]),
                isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
              ],
            );

            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                'pngs/workout_session_4sets_dark_${width.toInt()}.png',
              ),
            );

            await tester.pumpWidget(const SizedBox.shrink());
          });
        }
      }

      testWidgets('SessionSummaryScreen', (tester) async {
        await pumpGoldenWidget(
          tester,
          themeMode: themeMode,
          prefs: prefs,
          child: const SessionSummaryScreen(sessionId: 'sess-active'),
          overrides: [
            liveSessionDetailProvider('sess-active')
                .overrideWith((_) async => tSummarySession),
            progressionRepositoryProvider
                .overrideWithValue(_GoldenProgressionRepository()),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          ],
        );

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('pngs/session_summary_$themeLabel.png'),
        );
      });

      testWidgets('TrainingListScreen', (tester) async {
        await pumpGoldenWidget(
          tester,
          themeMode: themeMode,
          prefs: prefs,
          child: const TrainingListScreen(),
          overrides: [
            trainingPlansStateProvider.overrideWith(
              (ref) => _GoldenTrainingPlansNotifier(ref, [tPlan]),
            ),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          ],
        );

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('pngs/training_list_$themeLabel.png'),
        );
      });

      testWidgets('HistoryScreen (Consistência tab)', (tester) async {
        await pumpGoldenWidget(
          tester,
          themeMode: themeMode,
          prefs: prefs,
          child: const HistoryScreen(),
          overrides: [
            historyListProvider.overrideWith((_) async => [tCompletedSession]),
            currentWeekSummaryProvider.overrideWith((_) async => tWeekSummary),
            weightHistoryProvider.overrideWith(
              (_) async => [
                WeightEntry(
                  id: 'w-1',
                  weightKg: 78.2,
                  measuredAt:
                      kFixedGoldenNow.subtract(const Duration(days: 3)),
                ),
                WeightEntry(
                  id: 'w-2',
                  weightKg: 78.4,
                  measuredAt: kFixedGoldenNow,
                ),
              ],
            ),
            weightStatsProvider.overrideWith(
              (_) async => const WeightStats(deltaVsPreviousWeekKg: 0.2),
            ),
          ],
        );

        await tester.tap(find.text('Consistência'));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('pngs/progress_consistency_$themeLabel.png'),
        );
      });

      testWidgets('ProfileScreen', (tester) async {
        await pumpGoldenWidget(
          tester,
          themeMode: themeMode,
          prefs: prefs,
          child: const ProfileScreen(),
        );

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('pngs/profile_$themeLabel.png'),
        );
      });

      testWidgets('SettingsScreen', (tester) async {
        await pumpGoldenWidget(
          tester,
          themeMode: themeMode,
          prefs: prefs,
          child: const SettingsScreen(),
          overrides: [
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          ],
        );

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('pngs/settings_$themeLabel.png'),
        );
      });

      testWidgets('LoginScreen', (tester) async {
        await pumpGoldenWidget(
          tester,
          themeMode: themeMode,
          prefs: prefs,
          child: const LoginScreen(),
        );

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('pngs/login_$themeLabel.png'),
        );
      });

      testWidgets('LiftrWordmark isolated', (tester) async {
        await pumpGoldenWidget(
          tester,
          themeMode: themeMode,
          prefs: prefs,
          height: 160,
          child: const Scaffold(
            body: Center(
              child: LiftrWordmark(height: 36),
            ),
          ),
        );

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('pngs/liftr_wordmark_$themeLabel.png'),
        );
      });
    });
  }
}
