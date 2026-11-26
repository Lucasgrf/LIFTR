import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_stats.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/history_workout_card.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_weight_view.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/workout_mood_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final tSession = WorkoutSession(
    id: 's-1',
    userId: 'u-1',
    workoutName: 'Treino A - Peito e Tríceps',
    startedAt: DateTime(2026, 8, 22, 10, 0),
    completedAt: DateTime(2026, 8, 22, 11, 0),
    durationSeconds: 3600,
    status: SessionStatus.completed,
    perceivedExertion: 8.5,
    mood: Mood.excellent,
  );

  Widget createWidgetUnderTest(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('HistoryWorkoutCard Widget Test', () {
    testWidgets('should render workout name, duration, RPE and mood',
        (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          HistoryWorkoutCard(session: tSession),
        ),
      );

      expect(find.text('Treino A - Peito e Tríceps'), findsOneWidget);
      expect(find.text('60 min'), findsOneWidget);
      expect(find.text('RPE 8.5'), findsOneWidget);
      expect(find.byType(WorkoutMoodIcon), findsOneWidget);
      expect(find.text('Muito forte'), findsOneWidget);
    });
  });

  group('A11Y-01 ProgressWeightView period pills', () {
    for (final textScale in [1.0, 1.3, 2.0]) {
      testWidgets(
          'renders 48x48dp Material+Ink period pills without overflow at 320dp (${textScale}x)',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final now = DateTime.now();
        final entries = [
          WeightEntry(
            id: 'w-1',
            weightKg: 81.2,
            measuredAt: now.subtract(const Duration(days: 10)),
          ),
          WeightEntry(
            id: 'w-2',
            weightKg: 80.6,
            measuredAt: now.subtract(const Duration(days: 2)),
          ),
        ];

        final handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                weightHistoryProvider.overrideWith((_) async => entries),
                weightStatsProvider.overrideWith(
                  (_) async => const WeightStats(deltaVsPreviousWeekKg: -0.35),
                ),
              ],
              child: MediaQuery(
                data: MediaQueryData(
                  size: const Size(320, 900),
                  textScaler: TextScaler.linear(textScale),
                  disableAnimations: true,
                ),
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
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);

          for (final label in const ['30D', '90D', '6M', 'Tudo']) {
            final pillFinder = find.ancestor(
              of: find.text(label),
              matching: find.byType(InkWell),
            );
            expect(pillFinder, findsOneWidget);
            expect(
              tester.getSize(pillFinder).width,
              greaterThanOrEqualTo(48.0),
            );
            expect(
              tester.getSize(pillFinder).height,
              greaterThanOrEqualTo(48.0),
            );
            expect(
              find.descendant(of: pillFinder, matching: find.byType(Ink)),
              findsOneWidget,
            );
          }

          if (textScale == 1.0) {
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
          }
        } finally {
          handle.dispose();
        }
      });
    }
  });
}
