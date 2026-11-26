import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/liftr_confirm_dialog.dart';
import 'package:personal_fitness_os/core/widgets/liftr_list_group.dart';
import 'package:personal_fitness_os/core/widgets/liftr_progress_bar.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet_header.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/last_completed_workout_card.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_segmented_control.dart';
import 'package:personal_fitness_os/features/insights/presentation/providers/insight_providers.dart';
import 'package:personal_fitness_os/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/settings/presentation/screens/settings_screen.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/screens/workout_detail_screen.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/switch_program_sheet.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_comparison_data.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_snapshot.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/providers/weekly_comparison_providers.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/widgets/log_cardio_modal.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/widgets/weekly_summary_card.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/swap_exercise_sheet.dart';
import 'package:personal_fitness_os/routing/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _assertInkWellsHaveMaterialAncestor(WidgetTester tester) {
  final inkWells = tester.widgetList<InkWell>(find.byType(InkWell)).toList();
  expect(inkWells, isNotEmpty);
  for (final inkWell in inkWells) {
    final element = tester.element(find.byWidget(inkWell));
    final materialAncestor = element.findAncestorWidgetOfExactType<Material>();
    expect(
      materialAncestor,
      isNotNull,
      reason: 'Every InkWell must have a Material ancestor so ripples paint visibly',
    );
  }
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

  group('Phase 4 — Shared Components', () {
    test('showModalBottomSheet is only called inside core/widgets/liftr_sheet.dart',
        () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      expect(dartFiles, isNotEmpty);

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        if (file.path.endsWith('core/widgets/liftr_sheet.dart')) {
          expect(content.contains('showModalBottomSheet'), isTrue);
        } else {
          expect(
            content.contains('showModalBottomSheet'),
            isFalse,
            reason:
                '${file.path} must use showLiftrSheet() instead of showModalBottomSheet',
          );
        }
      }
    });

    testWidgets(
      'showLiftrSheet renders LiftrSheetHeader (36x4 xs handle), tablet maxWidth, keyboard bottom padding, and returns typed value',
      (tester) async {
        // 1. Tablet maxWidth & return value check
        tester.view.physicalSize = const Size(800, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        String? chosenValue;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    chosenValue = await showLiftrSheet<String>(
                      context: context,
                      eyebrow: 'TESTE',
                      title: 'Sheet compartilhado',
                      builder: (ctx) => AppButton.primary(
                        label: 'Selecionar',
                        onPressed: () => Navigator.of(ctx).pop('ok'),
                      ),
                    );
                  },
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        expect(find.byType(LiftrSheetHeader), findsOneWidget);
        expect(find.byType(ResponsiveContainer), findsOneWidget);

        // Handle geometry: 36x4 with AppRadius.defaults.xs (4.0)
        final handleBox = find.byWidgetPredicate((widget) {
          if (widget is! Container) return false;
          final constraints = widget.constraints;
          final dec = widget.decoration;
          return constraints != null &&
              constraints.maxWidth == 36 &&
              constraints.maxHeight == 4 &&
              dec is BoxDecoration &&
              dec.borderRadius == BorderRadius.circular(AppRadius.defaults.xs);
        });
        expect(handleBox, findsOneWidget);

        final sheetWidth = tester.getSize(
          find.byType(SingleChildScrollView),
        ).width;
        expect(sheetWidth, lessThanOrEqualTo(560.0));

        await tester.tap(find.text('Selecionar'));
        await tester.pumpAndSettle();
        expect(chosenValue, 'ok');

        // 2. Small phone (320x568 @ 1.3x) with keyboard + bottom system inset
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              viewInsets: EdgeInsets.only(bottom: 280),
              viewPadding: EdgeInsets.only(bottom: 34),
              textScaler: TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      showLiftrSheet<void>(
                        context: context,
                        title: 'Sheet teclado 320dp',
                        builder: (_) => const SizedBox(height: 120),
                      );
                    },
                    child: const Text('Abrir pequeno'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir pequeno'));
        await tester.pumpAndSettle();

        final scrollView = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );
        final padding = scrollView.padding! as EdgeInsets;
        expect(
          padding.bottom,
          greaterThanOrEqualTo(280 + AppSpacing.defaults.xxl),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'RESP-01: Dashboard skip/swap sheet scrolls cleanly with 6 workouts at 320x568 @ 1.3x and skips workout',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final workouts = List.generate(
          6,
          (i) => Workout(
            id: 'w-$i',
            trainingPlanId: 'plan-1',
            name: 'Treino Rotativo Número ${i + 1}',
            sortOrder: i,
          ),
        );
        final plan = TrainingPlan(
          id: 'plan-1',
          userId: 'u-1',
          name: 'PPL 6x',
          isActive: true,
          workouts: workouts,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              appClockProvider.overrideWithValue(() => fixedNow),
              isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
              fitnessInsightsProvider.overrideWith((_) async => const []),
              currentWeekSummaryProvider.overrideWith(
                (_) async => WeeklyComparisonData(
                  currentWeek: WeeklySnapshot(
                    weekStart: DateTime(2026, 5, 11),
                    weekEnd: DateTime(2026, 5, 17),
                    workoutsCompleted: 2,
                  ),
                ),
              ),
              dashboardDataProvider.overrideWith(
                (_) async => DashboardData(
                  activePlan: plan,
                  todayWorkout: workouts.first,
                ),
              ),
            ],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 568),
                textScaler: TextScaler.linear(1.3),
              ),
              child: MaterialApp(
                theme: AppTheme.dark(),
                home: const DashboardScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Pular / Trocar'));
        await tester.pumpAndSettle();

        expect(find.text('Escolher treino de hoje'), findsOneWidget);
        expect(find.text('Pular treino atual'), findsOneWidget);
        expect(find.byType(LiftrSheetHeader), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Pular treino atual'));
        await tester.pumpAndSettle();

        // First workout rotated to end -> Workout 2 is now displayed as today's workout
        expect(find.text('Treino Rotativo Número 2'), findsOneWidget);
      },
    );

    testWidgets(
      'showLiftrConfirmDialog renders cleanly at 320x568 @ 1.3x and returns true/false/barrier false',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        bool? lastResult;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () async {
                      lastResult = await showLiftrConfirmDialog(
                        context,
                        title: 'Descartar registro?',
                        message:
                            'Esta ação não pode ser desfeita e removerá os dados desta sessão.',
                        confirmLabel: 'Descartar agora',
                        icon: Icons.delete_outline_rounded,
                      );
                    },
                    child: const Text('Abrir diálogo'),
                  ),
                ),
              ),
            ),
          ),
        );

        // 1. Cancel button returns false
        await tester.tap(find.text('Abrir diálogo'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(lastResult, isFalse);

        // 2. Confirm button returns true
        await tester.tap(find.text('Abrir diálogo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Descartar agora'));
        await tester.pumpAndSettle();
        expect(lastResult, isTrue);

        // 3. Tapping outside barrier returns false
        await tester.tap(find.text('Abrir diálogo'));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        expect(lastResult, isFalse);

        // 4. System back / pop route returns false
        lastResult = null;
        await tester.tap(find.text('Abrir diálogo'));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(lastResult, isFalse);

        // 5. Destructive button does NOT receive default focus; Cancel does
        lastResult = null;
        await tester.tap(find.text('Abrir diálogo'));
        await tester.pumpAndSettle();
        final destructiveBtn = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton).last,
        );
        final cancelBtn = tester.widget<TextButton>(
          find.byType(TextButton).last,
        );
        expect(destructiveBtn.autofocus, isFalse);
        expect(cancelBtn.autofocus, isTrue);
        expect(
          Focus.of(
            tester.element(
              find.descendant(
                of: find.byType(ElevatedButton).last,
                matching: find.text('Descartar agora'),
              ),
            ),
          ).hasPrimaryFocus,
          isFalse,
        );
        expect(
          Focus.of(
            tester.element(
              find.descendant(
                of: find.byType(TextButton).last,
                matching: find.text('Cancelar'),
              ),
            ),
          ).hasPrimaryFocus,
          isTrue,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(lastResult, isFalse);
      },
    );

    testWidgets(
      'LiftrProgressBar exposes Semantics with percentage value and optional label',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(
              body: Column(
                children: [
                  LiftrProgressBar(
                    progress: 0.65,
                    semanticLabel: 'Progresso da atualização',
                  ),
                  LiftrProgressBar(progress: -0.2),
                  LiftrProgressBar(progress: 1.4),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final bars = find.byType(LiftrProgressBar);
        expect(tester.getSemantics(bars.at(0)).value, '65%');
        expect(tester.getSemantics(bars.at(0)).label, 'Progresso da atualização');
        expect(tester.getSemantics(bars.at(1)).value, '0%');
        expect(tester.getSemantics(bars.at(2)).value, '100%');
        handle.dispose();
      },
    );

    testWidgets(
      'SwapExerciseSheet via showLiftrSheet handles viewPadding.bottom: 34 without duplicated padding and scrolls cleanly with keyboard open (viewInsets.bottom: 300)',
      (tester) async {
        final sampleExercises = List.generate(
          15,
          (i) => Exercise(
            id: 'ex-$i',
            name: 'Exercício Composto ${i + 1}',
            primaryMuscleGroup: i.isEven ? 'chest' : 'back',
            equipment: 'barbell',
          ),
        );
        const currentExercise = Exercise(
          id: 'ex-current',
          name: 'Supino Reto',
          primaryMuscleGroup: 'chest',
          equipment: 'barbell',
        );

        Future<void> pumpSheetHost({
          required EdgeInsets viewPadding,
          required EdgeInsets viewInsets,
        }) async {
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
                exerciseListStateProvider.overrideWith(
                  (ref) => _TestExerciseListNotifier(ref, sampleExercises),
                ),
                historyListProvider.overrideWith((_) async => const []),
              ],
              child: MediaQuery(
                data: MediaQueryData(
                  size: const Size(375, 812),
                  viewPadding: viewPadding,
                  viewInsets: viewInsets,
                ),
                child: MaterialApp(
                  theme: AppTheme.dark(),
                  home: Scaffold(
                    body: Builder(
                      builder: (context) => ElevatedButton(
                        onPressed: () {
                          SwapExerciseSheet.show(
                            context,
                            currentExercise: currentExercise,
                            onSelect: (_) {},
                          );
                        },
                        child: const Text('Abrir troca'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Abrir troca'));
          await tester.pumpAndSettle();
        }

        // 1. Safe-area bottom inset (viewPadding.bottom: 34, no keyboard)
        await pumpSheetHost(
          viewPadding: const EdgeInsets.only(bottom: 34),
          viewInsets: EdgeInsets.zero,
        );
        expect(find.byType(SwapExerciseSheet), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(SwapExerciseSheet),
            matching: find.byType(SafeArea),
          ),
          findsNothing,
        );
        final listView = tester.widget<ListView>(find.byType(ListView));
        expect((listView.padding! as EdgeInsets).bottom, 0);

        final listBottom = tester.getRect(find.byType(ListView)).bottom;
        final expectedSingleBottomInset = 34.0 + AppSpacing.defaults.xxl;
        expect(
          812.0 - listBottom,
          moreOrLessEquals(expectedSingleBottomInset, epsilon: 0.5),
        );
        expect(tester.takeException(), isNull);

        // 2. Keyboard open (viewInsets.bottom: 300) + bottom viewPadding: 34
        await pumpSheetHost(
          viewPadding: const EdgeInsets.only(bottom: 34),
          viewInsets: const EdgeInsets.only(bottom: 300),
        );
        expect(find.byType(SwapExerciseSheet), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Search field remains fully visible above the 300dp keyboard
        final searchRect = tester.getRect(find.byType(TextField));
        expect(searchRect.top, greaterThanOrEqualTo(0));
        expect(searchRect.bottom, lessThanOrEqualTo(812.0 - 300.0));

        // Dragging UP scrolls the ListView down and keeps the sheet open
        final listFinder = find.byType(ListView);
        final scrollable = tester.state<ScrollableState>(
          find.descendant(of: listFinder, matching: find.byType(Scrollable)),
        );
        expect(scrollable.position.pixels, 0);

        await tester.drag(listFinder, const Offset(0, -180));
        await tester.pumpAndSettle();
        final scrolledPixels = scrollable.position.pixels;
        expect(scrolledPixels, greaterThan(0));
        expect(find.byType(SwapExerciseSheet), findsOneWidget);

        // Dragging DOWN scrolls the ListView back toward top without dismissing sheet
        await tester.drag(listFinder, const Offset(0, 120));
        await tester.pumpAndSettle();
        expect(find.byType(SwapExerciseSheet), findsOneWidget);
        expect(scrollable.position.pixels, lessThan(scrolledPixels));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'SettingsScreen and WorkoutDetailScreen use showLiftrConfirmDialog cleanly',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        // SettingsScreen logout confirmation
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final logoutText = find.text('Sair da conta');
        await tester.ensureVisible(logoutText);
        await tester.pumpAndSettle();
        await tester.tap(logoutText);
        await tester.pumpAndSettle();

        expect(find.text('Sair da conta?'), findsOneWidget);
        expect(
          find.text('Seus treinos locais continuam salvos no aparelho.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        // WorkoutDetailScreen delete exercise confirmation
        const tWorkout = Workout(
          id: 'w-1',
          trainingPlanId: 'plan-1',
          name: 'Upper A',
          exercises: [
            WorkoutExercise(
              id: 'we-1',
              workoutId: 'w-1',
              exerciseId: 'ex-1',
              exercise: Exercise(
                id: 'ex-1',
                name: 'Supino Reto',
                primaryMuscleGroup: 'chest',
              ),
              setTemplates: [
                SetTemplate(
                  id: 'st-1',
                  workoutExerciseId: 'we-1',
                  setNumber: 1,
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              workoutDetailProvider((planId: 'plan-1', workoutId: 'w-1'))
                  .overrideWith((_) async => tWorkout),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const WorkoutDetailScreen(
                planId: 'plan-1',
                workoutId: 'w-1',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pumpAndSettle();
        expect(find.text('Remover Exercício'), findsOneWidget);
        expect(
          find.text('Deseja remover "Supino Reto" deste treino?'),
          findsOneWidget,
        );
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'A11Y-03: LiftrListRow.toggle uses Switch.adaptive, MergeSemantics, full-row tap without double-fire, and works in SettingsScreen',
      (tester) async {
        var value = false;
        var calls = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (_, setState) => LiftrListGroup(
                  header: 'PREFERÊNCIAS',
                  children: [
                    LiftrListRow.toggle(
                      label: 'Modo silencioso',
                      subtitle: '22:00 – 07:00',
                      value: value,
                      onChanged: (next) {
                        calls++;
                        setState(() => value = next);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(Switch), findsOneWidget);

        // Verify MergeSemantics combines label + subtitle + toggled state
        final semanticsHandle = tester.ensureSemantics();
        final rowSemantics = tester.getSemantics(find.byType(MergeSemantics));
        expect(rowSemantics.label, contains('Modo silencioso'));
        expect(rowSemantics.label, contains('22:00 – 07:00'));
        semanticsHandle.dispose();

        // Tapping label toggles once
        await tester.tap(find.text('Modo silencioso'));
        await tester.pumpAndSettle();
        expect(value, isTrue);
        expect(calls, 1);

        // Tapping Switch directly toggles once (no double trigger)
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(value, isFalse);
        expect(calls, 2);

        // SettingsScreen integration: tapping label 'Horário silencioso' toggles provider state
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        late ProviderContainer container;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
            ],
            child: Builder(
              builder: (ctx) {
                container = ProviderScope.containerOf(ctx);
                return MaterialApp(
                  theme: AppTheme.dark(),
                  home: const SettingsScreen(),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final initialQuietHours =
            container.read(userSettingsProvider).quietHoursEnabled;
        await tester.tap(find.text('Horário silencioso'));
        await tester.pumpAndSettle();
        expect(
          container.read(userSettingsProvider).quietHoursEnabled,
          !initialQuietHours,
        );
      },
    );

    testWidgets(
      'A11Y-02: InkWells in LastCompletedWorkoutCard, WeeklySummaryCard, ProgressSegmentedControl, LogCardioModal, SwitchProgramSheet, OnboardingScreen (step 5) and AppShell satisfy Material ancestor, tap targets, and 320dp @ 1.3x',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final session = WorkoutSession(
          id: 'sess-1',
          userId: 'u-1',
          workoutName: 'Upper A',
          startedAt: fixedNow.subtract(const Duration(minutes: 45)),
          completedAt: fixedNow,
          durationSeconds: 2700,
          perceivedExertion: 8.5,
          executionScore: 92,
          mood: Mood.good,
        );
        final weekData = WeeklyComparisonData(
          currentWeek: WeeklySnapshot(
            weekStart: DateTime(2026, 5, 11),
            weekEnd: DateTime(2026, 5, 17),
            workoutsCompleted: 3,
            cardioDurationSeconds: 1800,
          ),
        );

        // 1a. LastCompletedWorkoutCard
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LastCompletedWorkoutCard(
                    session: session,
                    referenceNow: fixedNow,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        _assertInkWellsHaveMaterialAncestor(tester);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        expect(tester.takeException(), isNull, reason: 'LastCompletedWorkoutCard');

        // 1b. WeeklySummaryCard
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: WeeklySummaryCard(
                    data: weekData,
                    onOpenComparison: () {},
                    onLogCardio: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        _assertInkWellsHaveMaterialAncestor(tester);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        expect(tester.takeException(), isNull, reason: 'WeeklySummaryCard');

        // 1c. ProgressSegmentedControl
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ProgressSegmentedControl(
                    selectedIndex: 0,
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        _assertInkWellsHaveMaterialAncestor(tester);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        expect(tester.takeException(), isNull, reason: 'ProgressSegmentedControl');

        // 2. LogCardioModal
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(1.3),
              ),
              child: MaterialApp(
                theme: AppTheme.dark(),
                home: const Scaffold(body: LogCardioModal()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        _assertInkWellsHaveMaterialAncestor(tester);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        expect(tester.takeException(), isNull);

        // 3. SwitchProgramSheet
        const tPlan = TrainingPlan(
          id: 'plan-1',
          userId: 'u-1',
          name: 'Upper / Lower',
          isActive: true,
        );
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(1.3),
              ),
              child: MaterialApp(
                theme: AppTheme.dark(),
                home: const Scaffold(
                  body: SwitchProgramSheet(plans: [tPlan]),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        _assertInkWellsHaveMaterialAncestor(tester);
        expect(tester.takeException(), isNull);

        // 4. OnboardingScreen up to step 4 (schedule options)
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(1.3),
              ),
              child: MaterialApp(
                theme: AppTheme.dark(),
                home: const OnboardingScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (var i = 0; i < 4; i++) {
          await tester.tap(find.text('Continuar'));
          await tester.pumpAndSettle();
        }
        _assertInkWellsHaveMaterialAncestor(tester);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        expect(tester.takeException(), isNull);

        // 5. AppShell navigation bar
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
            key: UniqueKey(),
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
                textScaler: TextScaler.linear(1.3),
              ),
              child: MaterialApp.router(
                theme: AppTheme.dark(),
                routerConfig: router,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        _assertInkWellsHaveMaterialAncestor(tester);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
