import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_stats.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/screens/create_custom_exercise_screen.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/screens/exercise_detail_screen.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/screens/exercise_list_screen.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/screens/history_screen.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/history_workout_card.dart';
import 'package:personal_fitness_os/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:personal_fitness_os/features/profile/presentation/screens/profile_screen.dart';
import 'package:personal_fitness_os/features/settings/presentation/screens/settings_screen.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/configure_sets_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/training_list_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/training_plan_detail_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/import_plan_sheet.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/switch_program_sheet.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/workout_card.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/cardio_log.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_comparison_data.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_snapshot.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/providers/weekly_comparison_providers.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/screens/weekly_comparison_screen.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/widgets/log_cardio_modal.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/finish_workout_modal.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/swap_exercise_sheet.dart';
import 'package:personal_fitness_os/routing/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestTrainingPlansNotifier extends TrainingPlansNotifier {
  _TestTrainingPlansNotifier(super.ref, List<TrainingPlan> plans) {
    state = AsyncValue.data(plans);
  }

  @override
  Future<void> loadPlans() async {}
}

class _TestExerciseListNotifier extends ExerciseListNotifier {
  _TestExerciseListNotifier(super.ref, List<Exercise> items) {
    state = AsyncValue.data(items);
  }

  @override
  Future<void> loadExercises() async {}
}

void main() {
  final fixedNow = DateTime(2026, 5, 14, 18, 30);

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  const sampleExercise = Exercise(
    id: 'ex-1',
    name: 'Supino Inclinado com Halteres',
    primaryMuscleGroup: 'chest',
    equipment: 'dumbbell',
  );
  const sampleExerciseAlt = Exercise(
    id: 'ex-2',
    name: 'Remada Curvada Pronada',
    primaryMuscleGroup: 'back',
    equipment: 'barbell',
  );
  const sampleWorkoutExercise = WorkoutExercise(
    id: 'we-1',
    workoutId: 'w-1',
    exerciseId: 'ex-1',
    exercise: sampleExercise,
    setTemplates: [
      SetTemplate(
        id: 'st-1',
        workoutExerciseId: 'we-1',
        setNumber: 1,
        targetRepsMin: 8,
        targetRepsMax: 12,
        restSeconds: 120,
      ),
    ],
  );
  const sampleWorkoutA = Workout(
    id: 'w-1',
    trainingPlanId: 'plan-1',
    name: 'Upper A · Peito & Costas',
    dayOfWeek: 1,
    sortOrder: 0,
    exercises: [sampleWorkoutExercise],
  );
  const sampleWorkoutB = Workout(
    id: 'w-2',
    trainingPlanId: 'plan-1',
    name: 'Lower A · Quadríceps',
    dayOfWeek: 3,
    sortOrder: 1,
    exercises: [sampleWorkoutExercise],
  );
  const samplePlan = TrainingPlan(
    id: 'plan-1',
    userId: 'u-1',
    name: 'Upper / Lower',
    isActive: true,
    workouts: [sampleWorkoutA, sampleWorkoutB],
  );

  final sampleSession = WorkoutSession(
    id: 'sess-1',
    userId: 'u-1',
    workoutId: 'w-1',
    workoutName: 'Upper A · Peito & Costas',
    startedAt: fixedNow.subtract(const Duration(minutes: 45)),
    completedAt: fixedNow,
    durationSeconds: 2700,
    status: SessionStatus.completed,
    perceivedExertion: 8.5,
    executionScore: 92,
    mood: Mood.good,
    exercises: const [
      SessionExercise(
        id: 'se-1',
        sessionId: 'sess-1',
        exerciseId: 'ex-1',
        exercise: sampleExercise,
        targetSetsCount: 2,
        sets: [
          LoggedSet(
            id: 'ls-1',
            sessionExerciseId: 'se-1',
            setNumber: 1,
            weightKg: 32,
            repsCompleted: 10,
          ),
        ],
      ),
    ],
  );

  final sampleWeekData = WeeklyComparisonData(
    currentWeek: WeeklySnapshot(
      weekStart: DateTime(2026, 5, 11),
      weekEnd: DateTime(2026, 5, 17),
      workoutsCompleted: 3,
      workingSetsCount: 42,
      totalVolumeKg: 12450,
      cardioDurationSeconds: 2700,
      avgRpe: 8.2,
      avgExecutionScore: 90,
    ),
    previousWeek: WeeklySnapshot(
      weekStart: DateTime(2026, 5, 4),
      weekEnd: DateTime(2026, 5, 10),
      workoutsCompleted: 2,
      workingSetsCount: 36,
      totalVolumeKg: 11200,
      cardioDurationSeconds: 1800,
    ),
    currentWeekDailyCardio: [
      DailyCardioBreakdown(
        day: DateTime(2026, 5, 11),
        standaloneSeconds: 900,
      ),
      DailyCardioBreakdown(
        day: DateTime(2026, 5, 12),
        inSessionSeconds: 600,
      ),
      DailyCardioBreakdown(day: DateTime(2026, 5, 13)),
      DailyCardioBreakdown(
        day: DateTime(2026, 5, 14),
        standaloneSeconds: 1200,
      ),
      DailyCardioBreakdown(day: DateTime(2026, 5, 15)),
      DailyCardioBreakdown(day: DateTime(2026, 5, 16)),
      DailyCardioBreakdown(day: DateTime(2026, 5, 17)),
    ],
    currentWeekStandaloneCardio: [
      CardioLog(
        id: 'c-1',
        userId: 'u-1',
        modality: 'Esteira inclinada',
        durationSeconds: 1200,
        performedAt: fixedNow,
      ),
    ],
  );

  Future<SharedPreferences> pumpAt320_2x(
    WidgetTester tester, {
    required Widget child,
    List<Override> overrides = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appClockProvider.overrideWithValue(() => fixedNow),
          isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          ...overrides,
        ],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2.0),
          ),
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return prefs;
  }

  group('Phase 5 — RESP-01', () {
    test('ResponsiveContainer enforces 16dp <= 375dp and 20dp > 375dp', () {
      expect(ResponsiveContainer.horizontalPaddingForWidth(320), 16);
      expect(ResponsiveContainer.horizontalPaddingForWidth(375), 16);
      expect(ResponsiveContainer.horizontalPaddingForWidth(376), 20);
      expect(ResponsiveContainer.horizontalPaddingForWidth(412), 20);
    });

    testWidgets(
      'Main screens, AppShell and cards render at 320dp @ textScaler 2.0 with zero overflow',
      (tester) async {
        // 1. AppShell
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final router = GoRouter(
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (_, _, shell) => AppShell(navigationShell: shell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/',
                      builder: (_, _) => const Center(child: Text('HojeTab')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/training',
                      builder: (_, _) => const Center(child: Text('TreinoTab')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/history',
                      builder: (_, _) =>
                          const Center(child: Text('ProgressoTab')),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
              sessionLocalDataSourceProvider.overrideWithValue(null),
              sessionAutoSyncProvider.overrideWith((_) {}),
              pendingSyncCountProvider.overrideWith((_) => 0),
            ],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(2.0),
              ),
              child: MaterialApp.router(
                theme: AppTheme.dark(),
                routerConfig: router,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'AppShell');

        // 2. DashboardScreen
        await pumpAt320_2x(
          tester,
          child: const DashboardScreen(),
          overrides: [
            dashboardDataProvider.overrideWith(
              (_) async => DashboardData(
                activePlan: samplePlan,
                todayWorkout: sampleWorkoutA,
                lastCompletedSession: sampleSession,
              ),
            ),
            currentWeekSummaryProvider.overrideWith((_) async => sampleWeekData),
          ],
        );
        expect(tester.takeException(), isNull, reason: 'DashboardScreen');

        // 3. TrainingListScreen
        await pumpAt320_2x(
          tester,
          child: const TrainingListScreen(),
          overrides: [
            trainingPlansStateProvider.overrideWith(
              (ref) => _TestTrainingPlansNotifier(ref, [samplePlan]),
            ),
          ],
        );
        expect(tester.takeException(), isNull, reason: 'TrainingListScreen');

        // 4. HistoryScreen & HistoryWorkoutCard
        await pumpAt320_2x(
          tester,
          child: const HistoryScreen(),
          overrides: [
            historyListProvider.overrideWith((_) async => [sampleSession]),
            currentWeekSummaryProvider.overrideWith((_) async => sampleWeekData),
            weightHistoryProvider.overrideWith(
              (_) async => [
                WeightEntry(id: 'w-1', weightKg: 78.4, measuredAt: fixedNow),
              ],
            ),
            weightStatsProvider.overrideWith(
              (_) async => const WeightStats(deltaVsPreviousWeekKg: 0.2),
            ),
          ],
        );
        expect(tester.takeException(), isNull, reason: 'HistoryScreen');

        await pumpAt320_2x(
          tester,
          child: Scaffold(
            body: ListView(
              children: [
                HistoryWorkoutCard(session: sampleSession, onTap: () {}),
                WorkoutCard(workout: sampleWorkoutA, onTap: () {}),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: 'HistoryWorkoutCard & WorkoutCard');

        // 5. ProfileScreen + BodyDataSheet
        await pumpAt320_2x(tester, child: const ProfileScreen());
        expect(tester.takeException(), isNull, reason: 'ProfileScreen');
        await tester.ensureVisible(find.text('Dados corporais'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dados corporais'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'ProfileScreen._BodyDataSheet');

        // 6. SettingsScreen
        await pumpAt320_2x(tester, child: const SettingsScreen());
        expect(tester.takeException(), isNull, reason: 'SettingsScreen');

        // 7. WeeklyComparisonScreen (7-day cardio chart)
        await pumpAt320_2x(
          tester,
          child: const WeeklyComparisonScreen(),
          overrides: [
            weeklyComparisonProvider.overrideWith((_) async => sampleWeekData),
          ],
        );
        expect(tester.takeException(), isNull, reason: 'WeeklyComparisonScreen');
        expect(
          find.descendant(
            of: find.byType(WeeklyComparisonScreen),
            matching: find.byType(FittedBox),
          ),
          findsNothing,
        );
        expect(
          find.bySemanticsLabel('Segunda-feira: 15 minutos de cardio'),
          findsOneWidget,
        );

        // 8. ExerciseListScreen (with MuscleFilterChips)
        await pumpAt320_2x(
          tester,
          child: const ExerciseListScreen(),
          overrides: [
            exerciseListStateProvider.overrideWith(
              (ref) => _TestExerciseListNotifier(
                ref,
                const [sampleExercise, sampleExerciseAlt],
              ),
            ),
          ],
        );
        expect(tester.takeException(), isNull, reason: 'ExerciseListScreen');

        // 9. OnboardingScreen (step 0)
        await pumpAt320_2x(tester, child: const OnboardingScreen());
        expect(tester.takeException(), isNull, reason: 'OnboardingScreen step 0');

        // 10. ConfigureSetsScreen
        await pumpAt320_2x(
          tester,
          child: const ConfigureSetsScreen(
            planId: 'plan-1',
            workoutId: 'w-1',
            workoutExerciseId: 'we-1',
          ),
          overrides: [
            workoutDetailProvider((planId: 'plan-1', workoutId: 'w-1'))
                .overrideWith((_) async => sampleWorkoutA),
          ],
        );
        expect(tester.takeException(), isNull, reason: 'ConfigureSetsScreen');
      },
    );

    testWidgets(
      'Migrated sheets render at 320dp @ textScaler 2.0 with zero overflow',
      (tester) async {
        Future<void> openSheetAt320_2x({
          required void Function(BuildContext ctx) onOpen,
          List<Override> overrides = const [],
          required String label,
        }) async {
          await pumpAt320_2x(
            tester,
            overrides: overrides,
            child: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => onOpen(ctx),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Abrir'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: label);
        }

        await openSheetAt320_2x(
          label: 'SwapExerciseSheet',
          overrides: [
            exerciseListStateProvider.overrideWith(
              (ref) => _TestExerciseListNotifier(
                ref,
                const [sampleExercise, sampleExerciseAlt],
              ),
            ),
            historyListProvider.overrideWith((_) async => [sampleSession]),
          ],
          onOpen: (ctx) => SwapExerciseSheet.show(
            ctx,
            currentExercise: sampleExercise,
            onSelect: (_) {},
          ),
        );

        await openSheetAt320_2x(
          label: 'FinishWorkoutModal',
          overrides: [
            sessionPreviousWeightsProvider(sampleSession.id)
                .overrideWith((_) async => const {'ex-1': 30.0}),
          ],
          onOpen: (ctx) => showLiftrSheet<void>(
            context: ctx,
            builder: (_) => FinishWorkoutModal(
              session: sampleSession,
              elapsedSeconds: 2700,
              embedded: true,
              onFinished: () {},
            ),
          ),
        );

        await openSheetAt320_2x(
          label: 'LogCardioModal',
          onOpen: (ctx) => LogCardioModal.show(ctx),
        );

        await openSheetAt320_2x(
          label: 'SwitchProgramSheet',
          onOpen: (ctx) => SwitchProgramSheet.show(
            ctx,
            plans: const [samplePlan],
          ),
        );

        await openSheetAt320_2x(
          label: 'ImportPlanSheet',
          onOpen: (ctx) => ImportPlanSheet.show(ctx),
        );
      },
    );

    testWidgets(
      'OnboardingScreen (steps 0-1) and ConfigureSetsScreen render cleanly at 375dp @ textScaler 2.0',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              appClockProvider.overrideWithValue(() => fixedNow),
              isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
            ],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(375, 812),
                textScaler: TextScaler.linear(2.0),
              ),
              child: MaterialApp(
                theme: AppTheme.dark(),
                home: const OnboardingScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Onboarding step 0 @ 375');

        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Onboarding step 1 @ 375');

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              appClockProvider.overrideWithValue(() => fixedNow),
              workoutDetailProvider((planId: 'plan-1', workoutId: 'w-1'))
                  .overrideWith((_) async => sampleWorkoutA),
            ],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(375, 812),
                textScaler: TextScaler.linear(2.0),
              ),
              child: MaterialApp(
                theme: AppTheme.dark(),
                home: const ConfigureSetsScreen(
                  planId: 'plan-1',
                  workoutId: 'w-1',
                  workoutExerciseId: 'we-1',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'ConfigureSetsScreen @ 375');
      },
    );
  });

  group('Phase 5 — PLAT-01', () {
    testWidgets(
      'SettingsScreen hides app updates item on iOS and shows it on Android',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        Future<void> pumpPlatform(TargetPlatform platform) async {
          await tester.pumpWidget(
            ProviderScope(
              key: UniqueKey(),
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
              ],
              child: MaterialApp(
                theme: AppTheme.dark().copyWith(platform: platform),
                home: const SettingsScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        await pumpPlatform(TargetPlatform.iOS);
        expect(find.text('Atualizações do app'), findsNothing);

        await pumpPlatform(TargetPlatform.android);
        expect(find.text('Atualizações do app'), findsOneWidget);
      },
    );

    testWidgets(
      'Share actions use Icons.adaptive.share instead of Icons.ios_share_rounded',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              trainingPlansStateProvider.overrideWith(
                (ref) => _TestTrainingPlansNotifier(ref, [samplePlan]),
              ),
              trainingPlanDetailProvider('plan-1')
                  .overrideWith((_) async => samplePlan),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const TrainingListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Compartilhar programa'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.adaptive.share), findsOneWidget);
        expect(find.byIcon(Icons.ios_share_rounded), findsNothing);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              trainingPlanDetailProvider('plan-1')
                  .overrideWith((_) async => samplePlan),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const TrainingPlanDetailScreen(planId: 'plan-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.adaptive.share), findsOneWidget);
        expect(find.byIcon(Icons.ios_share_rounded), findsNothing);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const Scaffold(
                body: SwitchProgramSheet(plans: [samplePlan]),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byIcon(Icons.adaptive.share).first);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.adaptive.share), findsOneWidget);
        expect(find.byIcon(Icons.ios_share_rounded), findsNothing);
      },
    );

    testWidgets(
      'Top-level and detail screens outside AppShell wrap bodies with SafeArea',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              exerciseListStateProvider.overrideWith(
                (ref) => _TestExerciseListNotifier(ref, const [sampleExercise]),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const ExerciseListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(ExerciseListScreen),
            matching: find.byWidgetPredicate((w) => w is SafeArea && !w.top),
          ),
          findsOneWidget,
        );

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              exerciseDetailProvider('ex-1')
                  .overrideWith((_) async => sampleExercise),
              exerciseHistoryProvider('ex-1').overrideWith((_) async => const []),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const ExerciseDetailScreen(exerciseId: 'ex-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(ExerciseDetailScreen),
            matching: find.byWidgetPredicate((w) => w is SafeArea && !w.top),
          ),
          findsOneWidget,
        );

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const CreateCustomExerciseScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(CreateCustomExerciseScreen),
            matching: find.byWidgetPredicate((w) => w is SafeArea && !w.top),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
