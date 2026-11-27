import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/today_exercise_preview_card.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/cardio_log.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_comparison_data.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_snapshot.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/repositories/weekly_comparison_repository.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/providers/weekly_comparison_providers.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/screens/weekly_comparison_screen.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/widgets/log_cardio_modal.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/widgets/weekly_summary_card.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/finish_workout_modal.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/logged_set_row.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/session_exercise_card.dart';

class _RecordingFinishSessionRepo implements SessionRepository {
  double? savedRpe;
  int? savedExecutionScore;

  @override
  Future<Result<WorkoutSession, Failure>> finishSession({
    required String sessionId,
    required int durationSeconds,
    double? perceivedExertion,
    int? executionScore,
    Mood? mood,
    String? notes,
  }) async {
    savedRpe = perceivedExertion;
    savedExecutionScore = executionScore;
    return Success(
      WorkoutSession(
        id: sessionId,
        userId: 'u-1',
        startedAt: DateTime(2026, 11, 21),
        status: SessionStatus.completed,
        durationSeconds: durationSeconds,
        perceivedExertion: perceivedExertion,
        executionScore: executionScore,
      ),
    );
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
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<void, Failure>> deleteLoggedSet(String setId) async =>
      const Success(null);

  @override
  Future<Result<LoggedSet, Failure>> restoreLoggedSet(LoggedSet set) async =>
      Success(set);

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

class _FakeWeeklyRepo implements WeeklyComparisonRepository {
  _FakeWeeklyRepo(this.data);

  final WeeklyComparisonData data;
  String? loggedModality;
  int? loggedDurationSeconds;

  @override
  Future<Result<void, Failure>> deleteStandaloneCardio(String id) async =>
      const Success(null);

  @override
  Future<Result<WeeklyComparisonData, Failure>> getWeeklyComparison({
    DateTime? referenceDate,
    int historyWeeks = 8,
  }) async =>
      Success(data);

  @override
  Future<Result<CardioLog, Failure>> logStandaloneCardio({
    required String modality,
    required int durationSeconds,
    DateTime? performedAt,
    String? notes,
  }) async {
    loggedModality = modality;
    loggedDurationSeconds = durationSeconds;
    return Success(
      CardioLog(
        id: 'cardio-1',
        userId: 'u-1',
        modality: modality,
        durationSeconds: durationSeconds,
        performedAt: performedAt ?? DateTime(2026, 11, 21),
        notes: notes,
      ),
    );
  }

  @override
  Future<Result<WeeklySnapshot, Failure>> syncWeekSnapshot(
    DateTime referenceDate,
  ) async =>
      Success(data.currentWeek);
}

void main() {
  const exCardio = Exercise(
    id: '0e0ebb59-4815-4215-ba0d-2ee74d31a204',
    name: 'Cardio',
    primaryMuscleGroup: 'Cardio',
    movementPattern: 'cardio',
    equipment: 'machine',
  );

  const exBench = Exercise(
    id: 'ex-bench',
    name: 'Supino Reto',
    primaryMuscleGroup: 'chest',
    equipment: 'barbell',
  );

  group('Cardio as Time UI', () {
    testWidgets(
        'LoggedSetRow in cardio mode shows minutes stepper, hides KG/REPS/RIR, and saves durationSeconds',
        (tester) async {
      int? savedDurationSec;
      int? savedReps;
      double? savedWeight;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: LoggedSetRow(
                setNumber: 1,
                isCardio: true,
                defaultDurationMinutes: 20,
                onSave: ({
                  required double weightKg,
                  required int repsCompleted,
                  int? durationSeconds,
                  int? rirActual,
                  required SetType setType,
                  List<DropSetEntry> dropSets = const [],
                  String? existingSetId,
                }) async {
                  savedWeight = weightKg;
                  savedReps = repsCompleted;
                  savedDurationSec = durationSeconds;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('20 min'), findsOneWidget);
      expect(find.text('RIR 2'), findsNothing);

      final semantics = tester.ensureSemantics();
      try {
        await tester.tap(find.bySemanticsLabel('Aumentar tempo de cardio'));
        await tester.pump();
        expect(find.text('25 min'), findsOneWidget);

        await tester.tap(
          find.bySemanticsLabel('Marcar bloco de cardio 1 como concluído'),
        );
        await tester.pump();
      } finally {
        semantics.dispose();
      }

      expect(savedWeight, 0.0);
      expect(savedReps, 0);
      expect(savedDurationSec, 1500);
    });

    testWidgets(
        'SessionExerciseCard in cardio mode renders time columns, hides Drop-set, and emits restSeconds=0',
        (tester) async {
      int? capturedRest;
      int? capturedDuration;

      const seCardio = SessionExercise(
        id: 'se-cardio',
        sessionId: 's-1',
        exerciseId: '0e0ebb59-4815-4215-ba0d-2ee74d31a204',
        exercise: exCardio,
        targetSetsCount: 1,
        targetRepsMin: 15,
        targetRepsMax: 20,
        targetRestSeconds: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: SessionExerciseCard(
                  sessionExercise: seCardio,
                  onLogSet: ({
                    required sessionExerciseId,
                    required setNumber,
                    required setType,
                    required weightKg,
                    required repsCompleted,
                    durationSeconds,
                    rirActual,
                    restSeconds = 180,
                    dropSets = const [],
                    existingSetId,
                  }) async {
                    capturedRest = restSeconds;
                    capturedDuration = durationSeconds;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('TEMPO (MIN)'), findsOneWidget);
      expect(find.text('Meta: 15–20 min · registro por tempo'), findsOneWidget);
      expect(find.text('Adicionar bloco de cardio'), findsOneWidget);
      expect(find.text('KG'), findsNothing);
      expect(find.text('Drop-set'), findsNothing);

      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pump();

      expect(capturedRest, 0);
      expect(capturedDuration, 900); // 15 min
    });

    testWidgets('TodayExercisePreviewCard renders target range in min for cardio',
        (tester) async {
      const weCardio = WorkoutExercise(
        id: 'we-c',
        workoutId: 'wk-1',
        exerciseId: '0e0ebb59-4815-4215-ba0d-2ee74d31a204',
        exercise: exCardio,
        setTemplates: [
          SetTemplate(
            id: 'st-c',
            workoutExerciseId: 'we-c',
            setNumber: 1,
            targetRepsMin: 15,
            targetRepsMax: 20,
            restSeconds: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            themeMode: ThemeMode.dark,
            home: Scaffold(
              body: TodayExercisePreviewCard(
                index: 0,
                workoutExercise: weCardio,
              ),
            ),
          ),
        ),
      );

      expect(find.text('15–20 min'), findsOneWidget);
      expect(find.text('Cardio por tempo · Meta 15–20 min'), findsOneWidget);
      expect(find.textContaining('1×'), findsNothing);
    });
  });

  group('FinishWorkoutModal Automatic RPE & Execution Score', () {
    testWidgets(
        'removes manual Slider, displays auto-RPE + Execution Score, and submits computed values',
        (tester) async {
      final repo = _RecordingFinishSessionRepo();
      final session = WorkoutSession(
        id: 's-auto',
        userId: 'u-1',
        workoutName: 'Upper A',
        startedAt: DateTime(2026, 11, 21, 9, 0),
        durationSeconds: 2700,
        exercises: const [
          SessionExercise(
            id: 'se-1',
            sessionId: 's-auto',
            exerciseId: 'ex-bench',
            exercise: exBench,
            targetSetsCount: 2,
            targetRepsMin: 8,
            targetRepsMax: 12,
            targetRir: 2,
            sets: [
              LoggedSet(
                id: 'ls-1',
                sessionExerciseId: 'se-1',
                setNumber: 1,
                weightKg: 85,
                repsCompleted: 12,
              ),
              LoggedSet(
                id: 'ls-2',
                sessionExerciseId: 'se-1',
                setNumber: 2,
                weightKg: 85,
                repsCompleted: 12,
              ),
            ],
          ),
        ],
      );

      var finishedCalled = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionRepositoryProvider.overrideWithValue(repo),
            activeTrainingPlanProvider.overrideWithValue(null),
            dashboardDataProvider.overrideWith((_) async => DashboardData()),
            weeklyComparisonRepositoryProvider.overrideWithValue(
              _FakeWeeklyRepo(
                WeeklyComparisonData(
                  currentWeek: WeeklySnapshot(
                    weekStart: isoWeekStart(DateTime(2026, 11, 21)),
                    weekEnd: isoWeekEnd(DateTime(2026, 11, 21)),
                  ),
                ),
              ),
            ),
            sessionPreviousWeightsProvider('s-auto').overrideWith(
              (_) async => {'ex-bench': 80.0},
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: FinishWorkoutModal(
                session: session,
                elapsedSeconds: 2700,
                onFinished: () => finishedCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsNothing);
      expect(find.text('Avaliação automática'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('9,0'), findsOneWidget);
      expect(find.text('Execução excelente'), findsOneWidget);

      await tester.ensureVisible(find.text('Salvar e concluir treino'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar e concluir treino'));
      await tester.pumpAndSettle();

      expect(finishedCalled, isTrue);
      expect(repo.savedExecutionScore, 100);
      expect(repo.savedRpe, 9.0);
    });
  });

  group('Weekly Comparison Screen, Summary Card & LogCardioModal (Dark + Light + 320x640@1.3x)',
      () {
    final curWeekStart = isoWeekStart(DateTime(2026, 11, 16));
    final prevWeekStart = curWeekStart.subtract(const Duration(days: 7));

    final populatedComparison = WeeklyComparisonData(
      currentWeek: WeeklySnapshot(
        weekStart: curWeekStart,
        weekEnd: curWeekStart.add(const Duration(days: 6)),
        workoutsCompleted: 4,
        cardioDurationSeconds: 4500, // 1h 15m
        trainingDurationSeconds: 10800, // 3h
        workingSetsCount: 64,
        totalVolumeKg: 24800,
        avgRpe: 8.5,
        avgExecutionScore: 93,
      ),
      previousWeek: WeeklySnapshot(
        weekStart: prevWeekStart,
        weekEnd: prevWeekStart.add(const Duration(days: 6)),
        workoutsCompleted: 3,
        cardioDurationSeconds: 3300, // 55 min
        trainingDurationSeconds: 9000, // 2h 30m
        workingSetsCount: 48,
        totalVolumeKg: 20100,
        avgRpe: 8.0,
        avgExecutionScore: 86,
      ),
      currentWeekDailyCardio: [
        DailyCardioBreakdown(
          day: curWeekStart,
          inSessionSeconds: 1200,
          standaloneSeconds: 0,
        ),
        DailyCardioBreakdown(
          day: curWeekStart.add(const Duration(days: 1)),
        ),
        DailyCardioBreakdown(
          day: curWeekStart.add(const Duration(days: 2)),
          standaloneSeconds: 1800,
        ),
        DailyCardioBreakdown(
          day: curWeekStart.add(const Duration(days: 3)),
        ),
        DailyCardioBreakdown(
          day: curWeekStart.add(const Duration(days: 4)),
          inSessionSeconds: 1500,
        ),
        DailyCardioBreakdown(
          day: curWeekStart.add(const Duration(days: 5)),
        ),
        DailyCardioBreakdown(
          day: curWeekStart.add(const Duration(days: 6)),
        ),
      ],
      currentWeekStandaloneCardio: [
        CardioLog(
          id: 'c-1',
          userId: 'u-1',
          modality: 'Esteira',
          durationSeconds: 1800,
          performedAt: curWeekStart.add(const Duration(days: 2, hours: 8)),
          notes: 'Inclinação 6%',
        ),
      ],
      recentWeeksHistory: [
        WeeklySnapshot(
          weekStart: curWeekStart,
          weekEnd: curWeekStart.add(const Duration(days: 6)),
          workoutsCompleted: 4,
          cardioDurationSeconds: 4500,
          avgRpe: 8.5,
          avgExecutionScore: 93,
        ),
        WeeklySnapshot(
          weekStart: prevWeekStart,
          weekEnd: prevWeekStart.add(const Duration(days: 6)),
          workoutsCompleted: 3,
          cardioDurationSeconds: 3300,
          avgRpe: 8.0,
          avgExecutionScore: 86,
        ),
      ],
    );

    final firstWeekOnlyComparison = WeeklyComparisonData(
      currentWeek: WeeklySnapshot(
        weekStart: curWeekStart,
        weekEnd: curWeekStart.add(const Duration(days: 6)),
        workoutsCompleted: 2,
        cardioDurationSeconds: 1800,
      ),
    );

    testWidgets(
        'WeeklyComparisonScreen renders populated comparison in Dark + Light themes at 320x640 @ 1.3x without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeRepo = _FakeWeeklyRepo(populatedComparison);

      for (final entry in {
        'dark': AppTheme.dark(),
        'light': AppTheme.light(),
      }.entries) {
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey('weekly_scope_${entry.key}'),
            overrides: [
              weeklyComparisonRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: MaterialApp(
              theme: entry.value,
              home: const MediaQuery(
                data: MediaQueryData(
                  size: Size(320, 640),
                  textScaler: TextScaler.linear(1.3),
                ),
                child: WeeklyComparisonScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Comparação semanal'), findsOneWidget);
        expect(find.text('1h 15m'), findsWidgets);
        expect(find.text('+20 min vs ant.'), findsOneWidget);
        expect(find.text('Esteira · 18/11'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('WeeklyComparisonScreen renders clean first-week baseline',
        (tester) async {
      final fakeRepo = _FakeWeeklyRepo(firstWeekOnlyComparison);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyComparisonRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const WeeklyComparisonScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Primeira semana'), findsOneWidget);
      expect(find.text('Baseline inicial'), findsOneWidget);
      expect(find.text('30 min'), findsWidgets);
    });

    testWidgets('LogCardioModal logs standalone cardio at 320x640 @ 1.3x without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeRepo = _FakeWeeklyRepo(firstWeekOnlyComparison);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyComparisonRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const MediaQuery(
              data: MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(1.3),
              ),
              child: Scaffold(body: LogCardioModal()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bicicleta'));
      await tester.ensureVisible(find.text('30m'));
      await tester.tap(find.text('30m'));
      await tester.pump();
      await tester.ensureVisible(find.text('Salvar cardio'));
      await tester.tap(find.text('Salvar cardio'));
      await tester.pumpAndSettle();

      expect(fakeRepo.loggedModality, 'Bicicleta');
      expect(fakeRepo.loggedDurationSeconds, 1800);
      expect(tester.takeException(), isNull);
    });

    testWidgets('WeeklySummaryCard renders cleanly at 320x640 @ 1.3x without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: WeeklySummaryCard(
                  data: populatedComparison,
                  onOpenComparison: () {},
                  onLogCardio: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resumo semanal'), findsOneWidget);
      expect(find.text('1h 15m'), findsOneWidget);
      expect(find.text('+20 min'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
