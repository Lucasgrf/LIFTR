import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/charts/chart_models.dart';
import 'package:personal_fitness_os/core/widgets/charts/exercise_load_progression_chart.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_progress_bar.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_stats.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/weight_repository.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/today_exercise_preview_card.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/history/domain/entities/exercise_history_record.dart';
import 'package:personal_fitness_os/features/history/presentation/mappers/exercise_chart_mapper.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_consistency_view.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_segmented_control.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_weight_view.dart';
import 'package:personal_fitness_os/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:personal_fitness_os/features/profile/presentation/screens/profile_screen.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/progression_recommendation.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/weekly_muscle_volume_card.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  final fixedNow = DateTime(2026, 5, 14, 18, 30);

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> useCompactViewport(
    WidgetTester tester, {
    double width = 320,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Widget scaled(Widget child, {double textScale = 1.0, double width = 320}) {
    return MediaQuery(
      data: MediaQueryData(
        size: Size(width, 900),
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  group('Phase 7 — static guards', () {
    test('every IconButton in app/lib declares a tooltip', () {
      final iconButtonPattern =
          RegExp(r'\bIconButton\s*(?:\.\w+)?\s*\(');
      final violations = <String>[];

      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        for (final match in iconButtonPattern.allMatches(source)) {
          var depth = 1;
          var i = match.end;
          while (i < source.length && depth > 0) {
            final char = source[i];
            if (char == '(') depth++;
            if (char == ')') depth--;
            i++;
          }
          final body = source.substring(match.end, i - 1);
          if (!body.contains('tooltip:')) {
            final line = '\n'.allMatches(source.substring(0, match.start))
                    .length +
                1;
            violations.add('${entity.path}:$line');
          }
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('app/lib/core/widgets never imports from features/', () {
      final violations = <String>[];
      for (final entity
          in Directory('lib/core/widgets').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        if (source.contains('package:personal_fitness_os/features/')) {
          violations.add(entity.path);
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });

  group('Phase 7 — A11Y-03 semantics & non-color indicators', () {
    testWidgets(
      'ProgressSegmentedControl exposes a single selected button label per tab',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark(),
              home: Scaffold(
                body: ProgressSegmentedControl(
                  selectedIndex: 1,
                  onChanged: (_) {},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final selectedFinder = find.bySemanticsLabel('Peso');
          expect(selectedFinder, findsOneWidget);
          expect(
            tester.getSemantics(selectedFinder),
            isSemantics(label: 'Peso', isButton: true, isSelected: true),
          );
          expect(find.bySemanticsLabel('Treinos'), findsOneWidget);
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets(
      'WeeklyMuscleVolumeCard shows target legend and check icon beyond color',
      (tester) async {
        const chestEx = Exercise(
          id: 'e1',
          name: 'Supino',
          primaryMuscleGroup: 'chest',
        );
        const backEx = Exercise(
          id: 'e2',
          name: 'Remada',
          primaryMuscleGroup: 'back',
        );

        TrainingPlan buildPlan({required int chestSets}) => TrainingPlan(
              id: 'p1',
              userId: 'u1',
              name: 'Push Pull',
              isActive: true,
              workouts: [
                Workout(
                  id: 'w1',
                  trainingPlanId: 'p1',
                  name: 'Day 1',
                  exercises: [
                    WorkoutExercise(
                      id: 'we1',
                      workoutId: 'w1',
                      exerciseId: 'e1',
                      exercise: chestEx,
                      setTemplates: List.generate(
                        chestSets,
                        (i) => SetTemplate(
                          id: 'st-$i',
                          workoutExerciseId: 'we1',
                          setNumber: i + 1,
                        ),
                      ),
                    ),
                    WorkoutExercise(
                      id: 'we2',
                      workoutId: 'w1',
                      exerciseId: 'e2',
                      exercise: backEx,
                      setTemplates: List.generate(
                        4,
                        (i) => SetTemplate(
                          id: 'sb-$i',
                          workoutExerciseId: 'we2',
                          setNumber: i + 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );

        final handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark(),
              home: Scaffold(
                body: WeeklyMuscleVolumeCard(plan: buildPlan(chestSets: 10)),
              ),
            ),
          );

          expect(find.text('Meta: 10+ séries/semana'), findsOneWidget);
          // Legend icon + one group (Peito) that reached the target.
          expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));
          expect(
            find.bySemanticsLabel(
              'Peito: 10 séries válidas na semana (meta atingida)',
            ),
            findsOneWidget,
          );
          expect(
            find.bySemanticsLabel('Costas: 4 séries válidas na semana'),
            findsOneWidget,
          );

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark(),
              home: Scaffold(
                body: WeeklyMuscleVolumeCard(plan: buildPlan(chestSets: 4)),
              ),
            ),
          );
          // Only the legend icon remains when no group reaches the target.
          expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets(
      'ProgressConsistencyView heatmap cell exposes selected state',
      (tester) async {
        final session = WorkoutSession(
          id: 's-1',
          userId: 'u-1',
          workoutName: 'Push A',
          startedAt: DateTime(2026, 5, 12, 9),
          completedAt: DateTime(2026, 5, 12, 10),
          durationSeconds: 3600,
          status: SessionStatus.completed,
        );

        final handle = tester.ensureSemantics();
        try {
          await useCompactViewport(tester);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                appClockProvider.overrideWithValue(() => fixedNow),
                historyListProvider.overrideWith((_) async => [session]),
              ],
              child: scaled(const ProgressConsistencyView()),
            ),
          );
          await tester.pumpAndSettle();

          final cellFinder = find.bySemanticsLabel(RegExp(r', 1 treinos$'));
          expect(cellFinder, findsOneWidget);
          expect(
            tester.getSemantics(cellFinder),
            isSemantics(isButton: true, isSelected: true),
          );
        } finally {
          handle.dispose();
        }
      },
    );
  });

  group('Phase 7 — DS-01 chart decoupling', () {
    test('mapExerciseHistoryToLoadSeries builds sorted load and dashed 1RM series',
        () {
      final records = [
        ExerciseHistoryRecord(
          sessionId: 's-2',
          sessionName: 'B',
          date: DateTime(2026, 5, 10),
          setsCount: 3,
          topWeightKg: 85,
          topReps: 8,
          bestEstimated1Rm: 107.6,
        ),
        ExerciseHistoryRecord(
          sessionId: 's-1',
          sessionName: 'A',
          date: DateTime(2026, 5, 3),
          setsCount: 3,
          topWeightKg: 80,
          topReps: 10,
          bestEstimated1Rm: 106.7,
        ),
      ];

      final series = mapExerciseHistoryToLoadSeries(
        records,
        loadColor: Colors.green,
        e1rmColor: Colors.blue,
      );

      expect(series.map((s) => s.label), ['Carga máx', '1RM est']);
      expect(series[0].isDashed, isFalse);
      expect(series[1].isDashed, isTrue);
      expect(series[1].color, Colors.blue);
      expect(series[0].points.map((p) => p.value), [80, 85]);
      expect(series[1].points.map((p) => p.value), [106.7, 107.6]);
      expect(mapExerciseHistoryToLoadSeries(const [],
          loadColor: Colors.green, e1rmColor: Colors.blue), isEmpty);
    });
  });

  group('Phase 7 — VIS-01 ExerciseLoadProgressionChart', () {
    List<ChartSeries> buildSeries(Color e1rmColor) {
      final start = DateTime(2026, 5, 1);
      return [
        ChartSeries(
          id: 'max_load',
          label: 'Carga máx',
          color: const Color(0xFF72A987),
          points: [
            ChartPoint(date: start, value: 80),
            ChartPoint(date: start.add(const Duration(days: 7)), value: 85),
          ],
        ),
        ChartSeries(
          id: 'e1rm',
          label: '1RM est',
          color: e1rmColor,
          isDashed: true,
          points: [
            ChartPoint(date: start, value: 106.7),
            ChartPoint(date: start.add(const Duration(days: 7)), value: 107.6),
          ],
        ),
      ];
    }

    testWidgets(
      'renders dashed 1RM in colors.info, kg axis unit, reference line and trend semantics',
      (tester) async {
        final theme = AppTheme.dark();
        final info = theme.extension<AppColors>()!.info;
        final handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: ExerciseLoadProgressionChart(
                    series: buildSeries(info),
                    referenceValue: 100,
                    referenceLabel: 'Meta 100 kg',
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final chart = tester.widget<LineChart>(find.byType(LineChart));
          final dashedBars = chart.data.lineBarsData
              .where((bar) => bar.dashArray != null)
              .toList();
          expect(dashedBars, hasLength(1));
          expect(dashedBars.single.color, info);
          expect(chart.data.extraLinesData.horizontalLines, hasLength(1));

          expect(find.textContaining(' kg'), findsWidgets);
          expect(
            find.bySemanticsLabel(RegExp('tendência de alta')),
            findsOneWidget,
          );
        } finally {
          handle.dispose();
        }
      },
    );

    test('colors.info meets WCAG >= 3:1 graphical contrast against card surfaces in dark and light themes',
        () {
      double contrastRatio(Color fg, Color bg) {
        final l1 = fg.computeLuminance();
        final l2 = bg.computeLuminance();
        final hi = math.max(l1, l2);
        final lo = math.min(l1, l2);
        return (hi + 0.05) / (lo + 0.05);
      }

      expect(
        contrastRatio(AppColors.dark.info, AppColors.dark.surface),
        greaterThanOrEqualTo(3.0),
      );
      expect(
        contrastRatio(AppColors.dark.info, AppColors.dark.background),
        greaterThanOrEqualTo(3.0),
      );
      expect(
        contrastRatio(AppColors.light.info, AppColors.light.surface),
        greaterThanOrEqualTo(3.0),
      );
      expect(
        contrastRatio(AppColors.light.info, AppColors.light.background),
        greaterThanOrEqualTo(3.0),
      );
    });

    testWidgets('renders without overflow at 320dp @ 1.3x', (tester) async {
      await useCompactViewport(tester);
      await tester.pumpWidget(
        scaled(
          ExerciseLoadProgressionChart(
            series: buildSeries(
              AppTheme.dark().extension<AppColors>()!.info,
            ),
          ),
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Phase 7 — VIS-01 ProgressWeightView', () {
    testWidgets(
      'shows EmptyStateWidget instead of the profile weight when there are no weigh-ins',
      (tester) async {
        await useCompactViewport(tester);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              weightHistoryProvider.overrideWith((_) async => const []),
              weightStatsProvider
                  .overrideWith((_) async => const WeightStats()),
            ],
            child: scaled(const ProgressWeightView()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EmptyStateWidget), findsOneWidget);
        expect(find.text('Nenhuma pesagem registrada'), findsOneWidget);
        expect(find.text('TENDÊNCIA EMA ATUAL'), findsNothing);
      },
    );

    testWidgets(
      'renders legend, kg axis, trend semantics and combined raw + EMA tooltip',
      (tester) async {
        final now = DateTime.now();
        final entries = [
          WeightEntry(
            id: 'w-1',
            weightKg: 82.0,
            measuredAt: now.subtract(const Duration(days: 10)),
          ),
          WeightEntry(
            id: 'w-2',
            weightKg: 80.0,
            measuredAt: now.subtract(const Duration(days: 2)),
          ),
        ];

        final handle = tester.ensureSemantics();
        try {
          await useCompactViewport(tester, width: 375);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                weightHistoryProvider.overrideWith((_) async => entries),
                weightStatsProvider.overrideWith(
                  (_) async => const WeightStats(deltaVsPreviousWeekKg: -0.4),
                ),
              ],
              child: scaled(const ProgressWeightView(), width: 375),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Peso'), findsOneWidget);
          expect(find.text('Média móvel (EMA)'), findsOneWidget);
          expect(find.textContaining(' kg'), findsWidgets);
          expect(
            find.bySemanticsLabel(RegExp('tendência de queda')),
            findsOneWidget,
          );

          final chart = tester.widget<LineChart>(find.byType(LineChart));
          final rawBar = chart.data.lineBarsData[0];
          final emaBar = chart.data.lineBarsData[1];
          final tooltipItems = chart.data.lineTouchData.touchTooltipData
              .getTooltipItems([
            LineBarSpot(rawBar, 0, rawBar.spots[1]),
            LineBarSpot(emaBar, 1, emaBar.spots[1]),
          ]);

          expect(tooltipItems.whereType<LineTooltipItem>(), hasLength(1));
          final text = tooltipItems.whereType<LineTooltipItem>().single.text;
          expect(text, contains('Peso bruto: 80,0 kg'));
          expect(text, contains('EMA:'));
        } finally {
          handle.dispose();
        }
      },
    );
  });

  group('Phase 7 — VIS-01 ProgressConsistencyView', () {
    testWidgets(
      'labels months and weekdays, lists every session of the selected day and fits 320dp @ 1.3x',
      (tester) async {
        final sessions = [
          WorkoutSession(
            id: 's-1',
            userId: 'u-1',
            workoutName: 'Push A',
            startedAt: DateTime(2026, 5, 12, 9),
            completedAt: DateTime(2026, 5, 12, 10),
            durationSeconds: 3600,
            status: SessionStatus.completed,
          ),
          WorkoutSession(
            id: 's-2',
            userId: 'u-1',
            workoutName: 'Pull B',
            startedAt: DateTime(2026, 5, 12, 18),
            completedAt: DateTime(2026, 5, 12, 18, 45),
            durationSeconds: 2700,
            status: SessionStatus.completed,
          ),
        ];

        await useCompactViewport(tester);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              appClockProvider.overrideWithValue(() => fixedNow),
              historyListProvider.overrideWith((_) async => sessions),
            ],
            child: scaled(const ProgressConsistencyView(), textScale: 1.3),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Month labels (grid spans Feb–May 2026).
        expect(find.text('Fev'), findsOneWidget);
        expect(find.text('Mai'), findsOneWidget);

        // Weekday initials S T Q Q S S D (Seg..Dom).
        expect(find.text('D'), findsOneWidget);
        expect(find.text('T'), findsOneWidget);
        expect(find.text('Q'), findsNWidgets(2));
        expect(find.text('S'), findsNWidgets(3));

        // Both sessions of the selected day are listed.
        expect(find.textContaining('Push A'), findsOneWidget);
        expect(find.textContaining('Pull B'), findsOneWidget);
        expect(find.text('2 sessões'), findsOneWidget);
      },
    );
  });

  group('Phase 7 — VIS-01 TodayExercisePreviewCard progress', () {
    LoggedSet buildSet(int n, int reps) => LoggedSet(
          id: 'ls-$n',
          sessionExerciseId: 'se-1',
          setNumber: n,
          weightKg: 60,
          repsCompleted: reps,
        );

    test('computeDoubleProgressionRatio handles empty, partial and full ceiling',
        () {
      expect(
        computeDoubleProgressionRatio(
          previousWorkingSets: const [],
          targetRepsMax: 12,
        ),
        isNull,
      );
      expect(
        computeDoubleProgressionRatio(
          previousWorkingSets: [buildSet(1, 12)],
          targetRepsMax: 0,
        ),
        isNull,
      );
      expect(
        computeDoubleProgressionRatio(
          previousWorkingSets: [buildSet(1, 12), buildSet(2, 12), buildSet(3, 10)],
          targetRepsMax: 12,
        ),
        closeTo(2 / 3, 0.0001),
      );
      expect(
        computeDoubleProgressionRatio(
          previousWorkingSets: [buildSet(1, 12), buildSet(2, 13)],
          targetRepsMax: 12,
        ),
        1.0,
      );
      expect(
        computeDoubleProgressionRatio(
          previousWorkingSets: [buildSet(1, 8), buildSet(2, 9)],
          targetRepsMax: 12,
        ),
        0.0,
      );
    });

    WorkoutExercise buildExercise(Exercise exercise) => WorkoutExercise(
          id: 'we-1',
          workoutId: 'w-1',
          exerciseId: exercise.id,
          exercise: exercise,
          setTemplates: const [
            SetTemplate(
              id: 'st-1',
              workoutExerciseId: 'we-1',
              setNumber: 1,
              targetRepsMin: 8,
              targetRepsMax: 12,
              restSeconds: 90,
            ),
          ],
        );

    Future<void> pumpCard(
      WidgetTester tester,
      WorkoutExercise exercise,
      ProgressionRecommendation recommendation,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            exerciseProgressionProvider
                .overrideWith((ref, params) async => recommendation),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: TodayExercisePreviewCard(
                index: 0,
                workoutExercise: exercise,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    const squat = Exercise(
      id: 'ex-squat',
      name: 'Agachamento Livre',
      primaryMuscleGroup: 'quadriceps',
    );

    testWidgets('renders real ceiling ratio when history exists', (tester) async {
      await pumpCard(
        tester,
        buildExercise(squat),
        ProgressionRecommendation(
          type: ProgressionType.maintain,
          suggestedWeightKg: 60,
          weightDeltaKg: 0,
          rationale: 'Manter',
          previousWorkingSets: [
            buildSet(1, 12),
            buildSet(2, 12),
            buildSet(3, 10),
          ],
        ),
      );

      final bar = tester.widget<LiftrProgressBar>(find.byType(LiftrProgressBar));
      expect(bar.progress, closeTo(2 / 3, 0.0001));
    });

    testWidgets('hides progress bar when there is no history', (tester) async {
      await pumpCard(
        tester,
        buildExercise(squat),
        const ProgressionRecommendation(
          type: ProgressionType.maintain,
          suggestedWeightKg: 60,
          weightDeltaKg: 0,
          rationale: 'Primeira sessão',
        ),
      );

      expect(find.byType(LiftrProgressBar), findsNothing);
    });

    testWidgets('hides progress bar for cardio exercises', (tester) async {
      const cardio = Exercise(
        id: 'ex-cardio',
        name: 'Esteira',
        primaryMuscleGroup: 'cardio',
      );
      await pumpCard(
        tester,
        buildExercise(cardio),
        ProgressionRecommendation(
          type: ProgressionType.maintain,
          suggestedWeightKg: 0,
          weightDeltaKg: 0,
          rationale: 'Cardio',
          previousWorkingSets: [buildSet(1, 12)],
        ),
      );

      expect(find.byType(LiftrProgressBar), findsNothing);
    });
  });

  group('Pre-Phase-8 — In-app daily weight logging', () {
    testWidgets(
      'ProgressWeightView empty CTA opens Dados corporais and upserts at most once per day',
      (tester) async {
        final fakeRepo = _InMemoryWeightRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              appClockProvider.overrideWithValue(() => fixedNow),
              weightRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: ProgressWeightView(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Atualize seu peso em Perfil → Dados corporais'),
          findsOneWidget,
        );
        await tester.tap(find.text('Atualizar peso'));
        await tester.pumpAndSettle();

        expect(find.text('Dados corporais'), findsOneWidget);
        final weightField = find.descendant(
          of: find.widgetWithText(AppInput, 'Peso (kg)'),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(weightField, '81,5');
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(fakeRepo.entries, hasLength(1));
        expect(fakeRepo.entries.single.weightKg, 81.5);
        expect(find.text('TENDÊNCIA EMA ATUAL'), findsOneWidget);
        expect(find.text('81,5 kg'), findsOneWidget);

        // Editing weight again on the same day updates the single entry instead of duplicating.
        unawaited(
          showProfileBodyDataSheet(
            tester.element(find.byType(ProgressWeightView)),
            const UserSettingsState(weightKg: 81.5),
          ),
        );
        await tester.pumpAndSettle();

        final updatedField = find.descendant(
          of: find.widgetWithText(AppInput, 'Peso (kg)'),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(updatedField, '80,8');
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(fakeRepo.entries, hasLength(1));
        expect(fakeRepo.entries.single.weightKg, 80.8);
        expect(find.text('80,8 kg'), findsOneWidget);
      },
    );

    testWidgets(
      'OnboardingScreen _finish persists initial daily weight entry',
      (tester) async {
        final fakeRepo = _InMemoryWeightRepository();
        final router = GoRouter(
          initialLocation: '/onboarding',
          routes: [
            GoRoute(
              path: '/onboarding',
              builder: (_, _) => const OnboardingScreen(),
            ),
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('Home')),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              appClockProvider.overrideWithValue(() => fixedNow),
              weightRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: MaterialApp.router(
              theme: AppTheme.dark(),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Step 0 fields: Idade (0), Altura (1), Peso atual (2), % gordura (3).
        expect(find.text('Peso atual'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField).at(2), '74,2');
        await tester.pump();

        for (var i = 0; i < 5; i++) {
          final nextLabel = i == 4 ? 'Confirmar plano' : 'Continuar';
          await tester.tap(find.text(nextLabel));
          await tester.pumpAndSettle();
        }

        final skipBtn = find.text('Pular e fazer depois');
        await tester.ensureVisible(skipBtn);
        await tester.tap(skipBtn);
        await tester.pumpAndSettle();

        expect(find.text('Home'), findsOneWidget);
        expect(fakeRepo.entries, hasLength(1));
        expect(fakeRepo.entries.single.weightKg, 74.2);
      },
    );
  });
}

class _InMemoryWeightRepository implements WeightRepository {
  final List<WeightEntry> entries = [];

  @override
  Future<Result<WeightEntry, Failure>> upsertDailyWeight({
    required double weightKg,
    required DateTime measuredAt,
    String? notes,
  }) async {
    final idx = entries.indexWhere(
      (e) =>
          e.measuredAt.year == measuredAt.year &&
          e.measuredAt.month == measuredAt.month &&
          e.measuredAt.day == measuredAt.day,
    );
    if (idx >= 0) {
      final updated = entries[idx].copyWith(
        weightKg: weightKg,
        measuredAt: measuredAt,
      );
      entries[idx] = updated;
      return Success(updated);
    }
    final created = WeightEntry(
      id: 'w-${entries.length + 1}',
      weightKg: weightKg,
      measuredAt: measuredAt,
      notes: notes,
    );
    entries.add(created);
    return Success(created);
  }

  @override
  Future<Result<WeightEntry, Failure>> logWeight({
    required double weightKg,
    required DateTime measuredAt,
    String? notes,
  }) =>
      upsertDailyWeight(weightKg: weightKg, measuredAt: measuredAt, notes: notes);

  @override
  Future<Result<List<WeightEntry>, Failure>> getWeightHistory({
    int limit = 100,
    int offset = 0,
  }) async =>
      Success([...entries]);

  @override
  Future<Result<List<WeightEntry>, Failure>> getWeightEntriesInRange({
    required DateTime start,
    required DateTime end,
  }) async =>
      Success(
        entries
            .where(
              (e) => !e.measuredAt.isBefore(start) && !e.measuredAt.isAfter(end),
            )
            .toList(),
      );

  @override
  Future<Result<void, Failure>> deleteWeightEntry(String entryId) async {
    entries.removeWhere((e) => e.id == entryId);
    return const Success(null);
  }
}
