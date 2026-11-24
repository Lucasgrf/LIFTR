import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/insights/presentation/providers/insight_providers.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/progression/domain/repositories/progression_repository.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/screens/session_summary_screen.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/rest_timer_widget.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/session_exercise_card.dart';

class _StubProgressionRepository implements ProgressionRepository {
  @override
  Future<Result<ExercisePerformanceHistory?, Failure>>
      getLastExercisePerformance(String exerciseId) async {
    return Success(
      ExercisePerformanceHistory(
        exerciseId: exerciseId,
        workoutSessionId: 'prev-1',
        workoutName: 'Push A',
        date: DateTime(2026, 11, 18),
        loggedSets: const [
          LoggedSet(
            id: 'ls-prev',
            sessionExerciseId: 'se-prev',
            setNumber: 1,
            weightKg: 82.5,
            repsCompleted: 10,
            rirActual: 2,
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<List<ExercisePerformanceHistory>, Failure>>
      getRecentExercisePerformances(
    String exerciseId, {
    int limit = 2,
  }) async {
    return Success([
      ExercisePerformanceHistory(
        exerciseId: exerciseId,
        workoutSessionId: 'prev-1',
        workoutName: 'Push A',
        date: DateTime(2026, 11, 18),
        loggedSets: const [
          LoggedSet(
            id: 'ls-prev',
            sessionExerciseId: 'se-prev',
            setNumber: 1,
            weightKg: 82.5,
            repsCompleted: 10,
            rirActual: 2,
          ),
        ],
      ),
    ]);
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  const exBench = Exercise(
    id: 'ex-bench',
    name: 'Supino Inclinado com Halteres no Banco Regulável',
    primaryMuscleGroup: 'chest',
    equipment: 'dumbbell',
  );

  const seBench = SessionExercise(
    id: 'se-bench',
    sessionId: 'sess-1',
    exerciseId: 'ex-bench',
    exercise: exBench,
    targetRestSeconds: 180,
    targetSetsCount: 3,
    targetRepsMin: 8,
    targetRepsMax: 12,
    targetRir: 2,
    sets: [
      LoggedSet(
        id: 'ls-1',
        sessionExerciseId: 'se-bench',
        setNumber: 1,
        setType: SetType.working,
        weightKg: 82.5,
        repsCompleted: 12,
        rirActual: 1,
      ),
    ],
  );

  const sampleWorkout = Workout(
    id: 'wk-1',
    trainingPlanId: 'plan-1',
    name: 'Upper Push A',
    exercises: [
      WorkoutExercise(
        id: 'we-1',
        workoutId: 'wk-1',
        exerciseId: 'ex-bench',
        sortOrder: 0,
        exercise: exBench,
        setTemplates: [
          SetTemplate(
            id: 'st-1',
            workoutExerciseId: 'we-1',
            setNumber: 1,
            targetWeight: 82.5,
            targetRepsMin: 8,
            targetRepsMax: 12,
            restSeconds: 180,
          ),
        ],
      ),
    ],
  );

  final samplePlan = TrainingPlan(
    id: 'plan-1',
    userId: 'user-1',
    name: 'Full Body ABC',
    isActive: true,
    workouts: [
      sampleWorkout,
      const Workout(
        id: 'wk-2',
        trainingPlanId: 'plan-1',
        name: 'Lower A',
      ),
    ],
  );

  final sampleSession = WorkoutSession(
    id: 'sess-1',
    userId: 'user-1',
    workoutName: 'Upper Push A',
    startedAt: DateTime(2026, 11, 20, 10, 0),
    completedAt: DateTime(2026, 11, 20, 10, 52),
    durationSeconds: 3120,
    exercises: const [seBench],
  );

  Widget wrapResponsive({
    required Widget child,
    Size size = const Size(375, 812),
    double textScale = 1.0,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child,
        ),
      ),
    );
  }

  group('Fase 3 — 5-State RestTimer lifecycle & widget', () {
    testWidgets('supports idle -> running -> paused -> resumed -> completed -> dismissed',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: RestTimerWidget(stepSeconds: 15),
              ),
            ),
          ),
        ),
      );

      // 1. Idle -> hidden
      final semantics = tester.ensureSemantics();
      try {
        expect(container.read(restTimerNotifierProvider).status,
            RestTimerStatus.idle);
        expect(find.text('DESCANSO'), findsNothing);

        // 2. Running
        container.read(restTimerNotifierProvider.notifier).start(
              3,
              exerciseName: 'Supino Reto',
              setNumber: 1,
            );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(container.read(restTimerNotifierProvider).status,
            RestTimerStatus.running);
        expect(find.text('DESCANSO'), findsOneWidget);
        expect(find.text('00:03'), findsOneWidget);
        expect(find.text('-15s'), findsOneWidget);
        expect(find.text('+15s'), findsOneWidget);
        expect(find.text('Pular'), findsOneWidget);

        // 3. Paused & adjustment while paused
        await tester.tap(find.bySemanticsLabel('Pausar descanso'));
        await tester.pump();
        expect(container.read(restTimerNotifierProvider).status,
            RestTimerStatus.paused);
        expect(find.text('PAUSADO'), findsOneWidget);

        await tester.tap(find.text('+15s'));
        await tester.pump();
        expect(find.text('00:18'), findsOneWidget);

        // Advance 2s while paused -> stays frozen at 00:18
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('00:18'), findsOneWidget);

        // 4. Resume -> counts down
        await tester.tap(find.bySemanticsLabel('Retomar descanso'));
        await tester.pump();
        expect(container.read(restTimerNotifierProvider).status,
            RestTimerStatus.running);

        // Restart cleanly at 2s to test completed transition quickly
        container.read(restTimerNotifierProvider.notifier).start(
              2,
              exerciseName: 'Supino Reto',
              setNumber: 2,
            );
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        // 5. Completed -> shows feedback and OK button
        expect(container.read(restTimerNotifierProvider).status,
            RestTimerStatus.completed);
        expect(find.text('DESCANSO CONCLUÍDO'), findsOneWidget);
        expect(find.text('00:00'), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);

        // 6. Dismissed on OK tap
        await tester.tap(find.text('OK'));
        await tester.pump();
        expect(container.read(restTimerNotifierProvider).status,
            RestTimerStatus.dismissed);
        expect(find.text('DESCANSO CONCLUÍDO'), findsNothing);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('Fase 3 — Multi-viewport & 1.3x scale overflow checks', () {
    for (final viewport in const [
      (name: '320x640', size: Size(320, 640), scale: 1.3),
      (name: '375x812', size: Size(375, 812), scale: 1.0),
      (name: '430x932', size: Size(430, 932), scale: 1.0),
      (name: '768x1024', size: Size(768, 1024), scale: 1.0),
    ]) {
      testWidgets(
          'Dashboard + SessionExerciseCard + RestTimer render without overflow at ${viewport.name} (scale ${viewport.scale})',
          (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.binding.setSurfaceSize(viewport.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        try {
          await tester.pumpWidget(
            wrapResponsive(
              size: viewport.size,
              textScale: viewport.scale,
              overrides: [
                dashboardDataProvider.overrideWith(
                  (_) async => DashboardData(
                    activePlan: samplePlan,
                    todayWorkout: sampleWorkout,
                    lastCompletedSession: sampleSession,
                  ),
                ),
                fitnessInsightsProvider.overrideWith((_) async => const []),
                progressionRepositoryProvider
                    .overrideWithValue(_StubProgressionRepository()),
              ],
              child: const DashboardScreen(),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('LIFTR · HOJE'), findsOneWidget);
          expect(find.text('Upper Push A'), findsWidgets);
          expect(tester.takeException(), isNull);

          // Now verify SessionExerciseCard + RestTimer together
          final container = ProviderContainer(
            overrides: [
              progressionRepositoryProvider
                  .overrideWithValue(_StubProgressionRepository()),
            ],
          );
          addTearDown(container.dispose);
          container.read(restTimerNotifierProvider.notifier).start(
                180,
                exerciseName: exBench.name,
                setNumber: 1,
              );

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: AppTheme.dark(),
                home: MediaQuery(
                  data: MediaQueryData(
                    size: viewport.size,
                    textScaler: TextScaler.linear(viewport.scale),
                  ),
                  child: Scaffold(
                    body: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            children: [
                              SessionExerciseCard(
                                sessionExercise: seBench,
                                exerciseIndex: 0,
                                totalExercises: 1,
                                onSwapExercise: () {},
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
                                }) async {},
                              ),
                            ],
                          ),
                        ),
                        const RestTimerWidget(stepSeconds: 15),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('03:00'), findsOneWidget);
          expect(find.textContaining('Última:'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Verify 48dp touch target on Trocar, Adicionar série and Drop-set
          expect(
            tester.getSize(find.bySemanticsLabel('Trocar exercício')).height,
            greaterThanOrEqualTo(48),
          );
          expect(
            tester.getSize(find.text('Adicionar série').first).height,
            greaterThan(0),
          );
          final dropButton = find.ancestor(
            of: find.text('Drop-set'),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          );
          expect(
            tester.getSize(dropButton).height,
            greaterThanOrEqualTo(48),
          );

          container.read(restTimerNotifierProvider.notifier).stop();
        } finally {
          semantics.dispose();
        }
      });
    }

    testWidgets('SessionSummaryScreen renders matte header at 320x640 1.3x',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapResponsive(
          size: const Size(320, 640),
          textScale: 1.3,
          overrides: [
            liveSessionDetailProvider('sess-1')
                .overrideWith((_) async => sampleSession),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
            pendingSyncCountProvider.overrideWith((_) => 0),
          ],
          child: const SessionSummaryScreen(sessionId: 'sess-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Treino concluído'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
