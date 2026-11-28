import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/theme/theme_provider.dart';
import 'package:personal_fitness_os/features/auth/presentation/screens/login_screen.dart';
import 'package:personal_fitness_os/features/auth/presentation/screens/register_screen.dart';
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
import 'package:personal_fitness_os/features/onboarding/presentation/screens/onboarding_screen.dart';
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
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/screens/session_summary_screen.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/screens/workout_session_screen.dart';

class _FakeProgressionRepository implements ProgressionRepository {
  @override
  Future<Result<ExercisePerformanceHistory?, Failure>>
  getLastExercisePerformance(String exerciseId) async {
    return Success(
      ExercisePerformanceHistory(
        exerciseId: exerciseId,
        workoutSessionId: 'prev-session',
        workoutName: 'Lower A',
        date: DateTime(2026, 11, 15),
        loggedSets: const [
          LoggedSet(
            id: 'prev-1',
            sessionExerciseId: 'prev-se',
            setNumber: 1,
            weightKg: 60.0,
            repsCompleted: 12,
            rirActual: 2,
          ),
          LoggedSet(
            id: 'prev-2',
            sessionExerciseId: 'prev-se',
            setNumber: 2,
            weightKg: 60.0,
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
    return Success([
      ExercisePerformanceHistory(
        exerciseId: exerciseId,
        workoutSessionId: 'prev-session',
        workoutName: 'Lower A',
        date: DateTime(2026, 11, 15),
        loggedSets: const [
          LoggedSet(
            id: 'prev-1',
            sessionExerciseId: 'prev-se',
            setNumber: 1,
            weightKg: 60.0,
            repsCompleted: 12,
            rirActual: 2,
          ),
          LoggedSet(
            id: 'prev-2',
            sessionExerciseId: 'prev-se',
            setNumber: 2,
            weightKg: 60.0,
            repsCompleted: 12,
            rirActual: 2,
          ),
        ],
      ),
    ]);
  }
}

class _FakeSessionRepository implements SessionRepository {
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
        sortOrder: sortOrder,
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
  }) async {
    return Success(
      WorkoutSession(
        id: sessionId,
        userId: 'u-1',
        startedAt: DateTime(2026, 11, 20),
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
      WorkoutSession(id: id, userId: 'u-1', startedAt: DateTime(2026, 11, 20)),
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
        id: existingSetId ?? 'logged-$setNumber',
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
        id: 'started-1',
        userId: 'u-1',
        workoutId: workoutId,
        workoutName: workoutName ?? 'Treino',
        startedAt: DateTime(2026, 11, 20),
      ),
    );
  }
}

class _FakeTrainingPlansNotifier extends TrainingPlansNotifier {
  _FakeTrainingPlansNotifier(super.ref, List<TrainingPlan> plans) {
    state = AsyncValue.data(plans);
  }

  @override
  Future<void> loadPlans() async {}
}

class _FakeExerciseListNotifier extends ExerciseListNotifier {
  _FakeExerciseListNotifier(super.ref, List<Exercise> exercises) {
    state = AsyncValue.data(exercises);
  }

  @override
  Future<void> loadExercises() async {}
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  const tSquat = Exercise(
    id: 'ex-squat',
    name: 'Agachamento Livre',
    primaryMuscleGroup: 'legs',
    equipment: 'barbell',
  );
  const tHack = Exercise(
    id: 'ex-hack',
    name: 'Hack Squat',
    primaryMuscleGroup: 'legs',
    equipment: 'machine',
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
          SetTemplate(
            id: 'st-3',
            workoutExerciseId: 'we-1',
            setNumber: 3,
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
            id: 'st-4',
            workoutExerciseId: 'we-2',
            setNumber: 1,
            targetRepsMin: 8,
            targetRepsMax: 12,
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

  final tActiveSession = WorkoutSession(
    id: 'sess-1',
    userId: 'u-1',
    workoutId: 'w-lower-a',
    workoutName: 'Lower A',
    startedAt: DateTime(2026, 11, 20, 18, 0),
    durationSeconds: 3120,
    exercises: const [
      SessionExercise(
        id: 'se-1',
        sessionId: 'sess-1',
        exerciseId: 'ex-squat',
        exercise: tSquat,
        targetSetsCount: 3,
        targetRepsMin: 8,
        targetRepsMax: 12,
        sets: [
          LoggedSet(
            id: 'ls-1',
            sessionExerciseId: 'se-1',
            setNumber: 1,
            weightKg: 60.0,
            repsCompleted: 12,
          ),
          LoggedSet(
            id: 'ls-2',
            sessionExerciseId: 'se-1',
            setNumber: 2,
            weightKg: 60.0,
            repsCompleted: 12,
          ),
          LoggedSet(
            id: 'ls-3',
            sessionExerciseId: 'se-1',
            setNumber: 3,
            weightKg: 60.0,
            repsCompleted: 12,
          ),
        ],
      ),
      SessionExercise(
        id: 'se-2',
        sessionId: 'sess-1',
        exerciseId: 'ex-bench',
        exercise: tBench,
        targetSetsCount: 3,
        targetRepsMin: 8,
        targetRepsMax: 12,
        sets: [],
      ),
    ],
  );

  Widget wrapApp(
    Widget child, {
    List<Override> overrides = const [],
    Size viewport = const Size(390, 844),
    bool disableAnimations = false,
    ThemeMode themeMode = ThemeMode.dark,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MediaQuery(
        data: MediaQueryData(
          size: viewport,
          disableAnimations: disableAnimations,
        ),
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          home: child,
        ),
      ),
    );
  }

  group('LIFTR Design System Tokens', () {
    test(
      'AppTheme dark and light expose required ThemeExtensions and tokens',
      () {
        final dark = AppTheme.dark();
        final light = AppTheme.light();

        final darkColors = dark.extension<AppColors>()!;
        final darkFitness = dark.extension<FitnessColors>()!;
        final darkRadius = dark.extension<AppRadius>()!;
        final darkSpacing = dark.extension<AppSpacing>()!;

        expect(darkColors.background, const Color(0xFF151A2E));
        expect(darkColors.surface, const Color(0xFF151A2E));
        expect(darkColors.primary, const Color(0xFF8FA8FF));
        expect(darkColors.onPrimary, const Color(0xFF151A2E));
        expect(darkColors.danger, const Color(0xFFFF8A7A));
        expect(darkFitness.progressUp, const Color(0xFF8FA8FF));
        expect(darkFitness.warmupTag, const Color(0xFFA9B0C2));
        expect(darkRadius.xl, 20);
        expect(darkSpacing.space16, 16);
        expect(dark.colorScheme.primary, const Color(0xFF8FA8FF));
        expect(dark.colorScheme.primary == Colors.blue, isFalse);

        final lightColors = light.extension<AppColors>()!;
        expect(lightColors.background, const Color(0xFFF4F5F0));
        expect(lightColors.primary, const Color(0xFF1C3FAA));
        expect(lightColors.onPrimary, const Color(0xFFF4F5F0));
      },
    );
  });

  group('Auth & Onboarding Screens', () {
    testWidgets('LoginScreen and RegisterScreen render LIFTR identity', (
      tester,
    ) async {
      await tester.pumpWidget(wrapApp(const LoginScreen()));
      expect(find.bySemanticsLabel('liftr'), findsOneWidget);
      expect(
        find.text('Seu próximo treino, sem calendário fixo.'),
        findsOneWidget,
      );
      expect(find.text('Entrar'), findsOneWidget);

      await tester.pumpWidget(wrapApp(const RegisterScreen()));
      expect(find.bySemanticsLabel('liftr'), findsOneWidget);
      expect(find.text('Criar conta'), findsOneWidget);
    });

    testWidgets(
      'OnboardingScreen advances 6 steps and updates split dynamically',
      (tester) async {
        await tester.pumpWidget(wrapApp(const OnboardingScreen()));

        expect(find.text('Passo 1 de 6'), findsOneWidget);
        expect(find.text('Seus dados corporais'), findsOneWidget);
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        expect(find.text('Passo 2 de 6'), findsOneWidget);
        await tester.tap(find.text('Cutting'));
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        expect(find.text('Passo 3 de 6'), findsOneWidget);
        await tester.tap(find.text('Iniciante'));
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        expect(find.text('Passo 4 de 6'), findsOneWidget);
        await tester.tap(find.text('Levemente ativo'));
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        expect(find.text('Passo 5 de 6'), findsOneWidget);
        expect(find.text('4 dias → Upper / Lower'), findsOneWidget);

        await tester.tap(find.text('3'));
        await tester.pump();
        expect(find.text('3 dias → Full Body 3×'), findsOneWidget);

        await tester.tap(find.text('6'));
        await tester.pump();
        expect(find.text('6 dias → Push / Pull / Legs 2×'), findsOneWidget);

        await tester.tap(find.text('Confirmar programa'));
        await tester.pumpAndSettle();

        expect(find.text('Passo 6 de 6'), findsOneWidget);
        expect(find.text('Conectar WhatsApp'), findsOneWidget);
        expect(find.text('Pular e fazer depois'), findsOneWidget);
      },
    );
  });

  group('DashboardScreen (Hoje)', () {
    testWidgets(
      'renders the current ficha, queue controls, and no legacy insight',
      (tester) async {
        final dashboardData = DashboardData(
          activePlan: tPlan,
          todayWorkout: tLowerA,
        );
        await tester.pumpWidget(
          wrapApp(
            const DashboardScreen(),
            themeMode: ThemeMode.light,
            overrides: [
              dashboardDataProvider.overrideWith((_) async => dashboardData),
              progressionRepositoryProvider.overrideWithValue(
                _FakeProgressionRepository(),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hoje'), findsNothing);
        expect(find.text('Lower A'), findsOneWidget);
        expect(find.textContaining('Ficha 1 de 2'), findsOneWidget);
        expect(find.text('próxima da fila'), findsOneWidget);
        expect(find.text('Trocar treino'), findsOneWidget);
        expect(find.text('Começar Lower A'), findsOneWidget);
        expect(find.text('Agachamento Livre'), findsOneWidget);
        expect(
          find.textContaining('Agachamento pronto para subir'),
          findsNothing,
        );
        expect(find.textContaining('Segundo insight oculto'), findsNothing);

        expect(find.text('NUTRIÇÃO HOJE'), findsNothing);
        expect(find.text('METAS EM ANDAMENTO'), findsNothing);
        expect(find.text('Consistência Semanal'), findsNothing);

        // Test skipping current workout in rotating queue
        await tester.tap(find.text('Trocar treino'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pular Lower A'));
        await tester.pumpAndSettle();
        expect(find.text('Upper B'), findsOneWidget);
      },
    );
  });

  group('WorkoutSessionScreen & Viewports', () {
    for (final entry in {
      'compact 375x812': const Size(375, 812),
      'large 428x926': const Size(428, 926),
      'tablet 768x1024': const Size(768, 1024),
    }.entries) {
      testWidgets('renders cleanly without overflow on ${entry.key}', (
        tester,
      ) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapApp(
            const WorkoutSessionScreen(sessionId: 'sess-1'),
            viewport: entry.value,
            overrides: [
              liveSessionDetailProvider(
                'sess-1',
              ).overrideWith((_) async => tActiveSession),
              progressionRepositoryProvider.overrideWithValue(
                _FakeProgressionRepository(),
              ),
              sessionRepositoryProvider.overrideWithValue(
                _FakeSessionRepository(),
              ),
              exerciseListStateProvider.overrideWith(
                (ref) =>
                    _FakeExerciseListNotifier(ref, [tSquat, tHack, tBench]),
              ),
              historyListProvider.overrideWith((_) async => [tActiveSession]),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Lower A'), findsOneWidget);
        expect(find.text('Finalizar'), findsOneWidget);
        expect(find.text('Agachamento Livre'), findsOneWidget);
        expect(find.text('Trocar'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Supino Reto'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Supino Reto'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Agachamento Livre'),
          -120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
        await tester.pumpAndSettle();

        // Open swap sheet
        await tester.ensureVisible(find.text('Trocar'));
        await tester.tap(find.text('Trocar'));
        await tester.pumpAndSettle();
        expect(find.text('Trocar exercício'), findsOneWidget);
        expect(find.text('Hack Squat'), findsOneWidget);
        await tester.tap(find.text('Hack Squat'));
        await tester.pumpAndSettle();
        expect(find.text('Hack Squat'), findsOneWidget);

        // Expand completed Set 1 (compact by default) and toggle warmup badge
        await tester.tap(find.bySemanticsLabel(RegExp(r'^Série 1,')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('1').first);
        await tester.pumpAndSettle();
        expect(find.text('AQ'), findsWidgets);

        // Tap check button to start Rest Timer (-15s, +15s, Pular)
        await tester.tap(find.byIcon(Icons.check_rounded).first);
        await tester.pump();
        expect(find.text('Descanso'), findsOneWidget);
        expect(find.text('-15s'), findsOneWidget);
        expect(find.text('+15s'), findsOneWidget);
        expect(find.text('Pular'), findsOneWidget);

        await tester.tap(find.text('Pular'));
        await tester.pumpAndSettle();
        expect(find.text('Descanso'), findsNothing);
      });
    }
  });

  group('SessionSummaryScreen', () {
    testWidgets('renders celebration metrics, SUBIR block and WhatsApp note', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapApp(
          const SessionSummaryScreen(sessionId: 'sess-1'),
          overrides: [
            liveSessionDetailProvider(
              'sess-1',
            ).overrideWith((_) async => tActiveSession),
            trainingPlansStateProvider.overrideWith(
              (ref) => _FakeTrainingPlansNotifier(ref, [tPlan]),
            ),
            progressionRepositoryProvider.overrideWithValue(
              _FakeProgressionRepository(),
            ),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(false)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FEITO'), findsOneWidget);
      expect(find.textContaining('séries.'), findsOneWidget);
      expect(find.textContaining('kg no total.'), findsOneWidget);
      expect(find.text('Agachamento Livre'), findsWidgets);
      expect(find.textContaining('Sem internet.'), findsOneWidget);
      expect(find.text('Subidas de carga desbloqueadas'), findsNothing);
    });
  });

  group('TrainingListScreen (Treino)', () {
    testWidgets('renders the editorial deck and switch sheet', (tester) async {
      await tester.pumpWidget(
        wrapApp(
          const TrainingListScreen(),
          overrides: [
            trainingPlansStateProvider.overrideWith(
              (ref) => _FakeTrainingPlansNotifier(ref, [tPlan]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Treino'), findsOneWidget);
      expect(find.text('Trocar programa'), findsOneWidget);
      expect(find.text('O baralho'), findsOneWidget);
      expect(find.textContaining('Próxima.'), findsOneWidget);
      expect(find.text('Lower A'), findsOneWidget);
      expect(find.text('Upper B'), findsOneWidget);
      expect(find.text('Volume semanal'), findsNothing);

      await tester.tap(find.text('Trocar programa'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Seu histórico de cargas e progressões é 100% preservado ao trocar de programa.',
        ),
        findsOneWidget,
      );
    });
  });

  group('HistoryScreen (Progresso)', () {
    testWidgets('switches between Exercícios, Peso EMA and Consistência', (
      tester,
    ) async {
      final completedSession = tActiveSession.copyWith(
        status: SessionStatus.completed,
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      final weights = [
        WeightEntry(
          id: 'w-1',
          weightKg: 77.8,
          measuredAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        WeightEntry(
          id: 'w-2',
          weightKg: 78.2,
          measuredAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        WeightEntry(id: 'w-3', weightKg: 78.4, measuredAt: DateTime.now()),
      ];

      await tester.pumpWidget(
        wrapApp(
          const HistoryScreen(),
          overrides: [
            historyListProvider.overrideWith((_) async => [completedSession]),
            trainingPlansStateProvider.overrideWith(
              (ref) => _FakeTrainingPlansNotifier(ref, [tPlan]),
            ),
            weightHistoryProvider.overrideWith((_) async => weights),
            weightStatsProvider.overrideWith(
              (_) async => const WeightStats(deltaVsPreviousWeekKg: 0.25),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Progresso'), findsOneWidget);
      expect(find.text('Exercícios'), findsOneWidget);
      expect(find.text('Peso'), findsOneWidget);
      expect(find.text('Consistência'), findsOneWidget);
      expect(find.text('Agachamento Livre'), findsOneWidget);
      expect(find.textContaining('Subindo,'), findsOneWidget);

      await tester.tap(find.text('Peso'));
      await tester.pumpAndSettle();
      expect(find.text('Seu peso ao longo do tempo'), findsOneWidget);
      expect(find.text('30 dias'), findsOneWidget);
      expect(find.text('90 dias'), findsOneWidget);

      await tester.tap(find.text('Consistência'));
      await tester.pumpAndSettle();
      expect(find.textContaining('esta semana,'), findsOneWidget);
      expect(
        find.textContaining('O baralho deu a volta completa'),
        findsOneWidget,
      );
    });
  });

  group('SettingsScreen & Reduced Motion', () {
    testWidgets(
      'renders 3 settings sections without unbacked WhatsApp section and toggles offline',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        late ProviderContainer container;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                return MaterialApp(
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  themeMode: ref.watch(themeModeProvider),
                  home: const SettingsScreen(),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Configurações'), findsOneWidget);
        expect(find.text('Treino e equipamentos'), findsOneWidget);
        expect(find.text('WhatsApp'), findsNothing);
        expect(find.text('Sincronização offline e dados'), findsOneWidget);
        expect(find.text('Conta'), findsOneWidget);
        expect(find.text('Online · Tudo sincronizado'), findsOneWidget);

        await tester.scrollUntilVisible(find.text('Simular modo offline'), 200);
        await tester.ensureVisible(find.byType(Switch).last);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Switch).last);
        await tester.pump();
        expect(container.read(simulatedOfflineProvider), isTrue);
        expect(find.text('Offline · Salvo localmente'), findsOneWidget);
      },
    );

    testWidgets(
      'ProfileScreen renders separated profile and body goal sections',
      (tester) async {
        await tester.pumpWidget(wrapApp(const ProfileScreen()));
        await tester.pumpAndSettle();
        expect(find.text('Perfil'), findsOneWidget);
        expect(find.text('Dados corporais e objetivo'), findsOneWidget);
      },
    );

    testWidgets('respects MediaQuery disableAnimations without errors', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapApp(
          const SessionSummaryScreen(sessionId: 'sess-1'),
          disableAnimations: true,
          overrides: [
            liveSessionDetailProvider(
              'sess-1',
            ).overrideWith((_) async => tActiveSession),
            trainingPlansStateProvider.overrideWith(
              (ref) => _FakeTrainingPlansNotifier(ref, [tPlan]),
            ),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('FEITO'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Sincronizado com o WhatsApp'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Sincronizado com o WhatsApp'), findsOneWidget);
    });
  });
}
