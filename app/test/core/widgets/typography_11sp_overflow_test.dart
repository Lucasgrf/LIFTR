import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/history_workout_card.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_consistency_view.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/workout_card.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_comparison_data.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_snapshot.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/providers/weekly_comparison_providers.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/screens/weekly_comparison_screen.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/session_exercise_card.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/workout_mood_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  const viewports = [
    (width: 320.0, scale: 1.0),
    (width: 320.0, scale: 1.3),
    (width: 360.0, scale: 1.0),
    (width: 360.0, scale: 1.3),
  ];

  Widget wrapForViewport(
    Widget child, {
    required double width,
    required double scale,
    List<Override> overrides = const [],
    bool scrollable = true,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...overrides,
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: scrollable
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: child,
                  )
                : child,
          ),
        ),
      ),
    );
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 18, 0);

  const benchExercise = Exercise(
    id: 'ex-bench',
    name: 'Supino reto com barra olímpica',
    primaryMuscleGroup: 'chest',
    equipment: 'barbell',
  );

  final sampleSession = WorkoutSession(
    id: 'sess-1',
    userId: 'u-1',
    workoutName: 'Treino A — Peito, Ombro e Tríceps',
    startedAt: today.subtract(const Duration(hours: 1)),
    completedAt: today,
    durationSeconds: 3720,
    status: SessionStatus.completed,
    perceivedExertion: 8.5,
    mood: Mood.excellent,
    exercises: const [
      SessionExercise(
        id: 'se-1',
        sessionId: 'sess-1',
        exerciseId: 'ex-bench',
        exercise: benchExercise,
        targetSetsCount: 3,
        targetRepsMin: 8,
        targetRepsMax: 12,
        sets: [
          LoggedSet(
            id: 'ls-1',
            sessionExerciseId: 'se-1',
            setNumber: 1,
            setType: SetType.working,
            weightKg: 100,
            repsCompleted: 10,
          ),
          LoggedSet(
            id: 'ls-2',
            sessionExerciseId: 'se-1',
            setNumber: 2,
            setType: SetType.dropSet,
            weightKg: 80,
            repsCompleted: 12,
            dropSets: [
              DropSetEntry(weightKg: 60, repsCompleted: 10),
            ],
          ),
        ],
      ),
    ],
  );

  const sampleWorkout = Workout(
    id: 'w-1',
    trainingPlanId: 'p-1',
    name: 'Treino A — Peito e Tríceps Completo',
    dayOfWeek: 1,
    exercises: [
      WorkoutExercise(
        id: 'we-1',
        workoutId: 'w-1',
        exerciseId: 'ex-bench',
        exercise: benchExercise,
        setTemplates: [
          SetTemplate(
            id: 'st-1',
            workoutExerciseId: 'we-1',
            setNumber: 1,
            targetRepsMin: 8,
            targetRepsMax: 12,
          ),
        ],
      ),
    ],
  );

  final weekStart = DateTime(2026, 11, 16);
  final sampleComparisonData = WeeklyComparisonData(
    currentWeek: WeeklySnapshot(
      weekStart: weekStart,
      weekEnd: weekStart.add(const Duration(days: 6)),
      workoutsCompleted: 4,
      cardioDurationSeconds: 12600,
      trainingDurationSeconds: 14400,
      workingSetsCount: 48,
      totalVolumeKg: 14250,
      avgRpe: 8.2,
      avgExecutionScore: 92,
    ),
    previousWeek: WeeklySnapshot(
      weekStart: weekStart.subtract(const Duration(days: 7)),
      weekEnd: weekStart.subtract(const Duration(days: 1)),
      workoutsCompleted: 3,
      cardioDurationSeconds: 9000,
      trainingDurationSeconds: 10800,
      workingSetsCount: 36,
      totalVolumeKg: 11200,
      avgRpe: 8.0,
      avgExecutionScore: 88,
    ),
    currentWeekDailyCardio: List.generate(
      7,
      (i) => DailyCardioBreakdown(
        day: weekStart.add(Duration(days: i)),
        inSessionSeconds: (25 + i * 5) * 60,
      ),
    ),
  );

  group('DS-03 11sp floor overflow matrix (320dp & 360dp @ 1.0x/1.3x)', () {
    for (final v in viewports) {
      testWidgets(
        'ProgressConsistencyView does not overflow at ${v.width}dp@${v.scale}x',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(v.width, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            wrapForViewport(
              const ProgressConsistencyView(),
              width: v.width,
              scale: v.scale,
              overrides: [
                historyListProvider.overrideWith((ref) async => [sampleSession]),
              ],
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Menos'), findsOneWidget);
          expect(find.text('Mais'), findsOneWidget);
          final err = tester.takeException();
          expect(err, isNull, reason: err is FlutterError ? err.toStringDeep() : '$err');
        },
      );

      testWidgets(
        'WorkoutCard does not overflow at ${v.width}dp@${v.scale}x',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(v.width, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            wrapForViewport(
              WorkoutCard(workout: sampleWorkout, onTap: () {}),
              width: v.width,
              scale: v.scale,
            ),
          );
          await tester.pumpAndSettle();

          final err = tester.takeException();
          expect(err, isNull, reason: err is FlutterError ? err.toStringDeep() : '$err');
        },
      );

      testWidgets(
        'WorkoutMoodChip compact does not overflow at ${v.width}dp@${v.scale}x',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(v.width, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            wrapForViewport(
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mood in Mood.values)
                    WorkoutMoodChip(mood: mood, compact: true),
                ],
              ),
              width: v.width,
              scale: v.scale,
            ),
          );
          await tester.pumpAndSettle();

          final err = tester.takeException();
          expect(err, isNull, reason: err is FlutterError ? err.toStringDeep() : '$err');
        },
      );

      testWidgets(
        'HistoryWorkoutCard does not overflow at ${v.width}dp@${v.scale}x',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(v.width, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            wrapForViewport(
              HistoryWorkoutCard(session: sampleSession, onTap: () {}),
              width: v.width,
              scale: v.scale,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('RPE 8.5'), findsOneWidget);
          final err = tester.takeException();
          expect(err, isNull, reason: err is FlutterError ? err.toStringDeep() : '$err');
        },
      );

      testWidgets(
        'SessionExerciseCard headers + LoggedSetRow (drop-set) do not overflow at ${v.width}dp@${v.scale}x',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(v.width, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            wrapForViewport(
              SessionExerciseCard(
                sessionExercise: sampleSession.exercises.first,
                isExpanded: true,
                showRir: false,
                exerciseIndex: 0,
                totalExercises: 1,
                onLogSet: ({
                  required sessionExerciseId,
                  required setNumber,
                  required setType,
                  required weightKg,
                  required repsCompleted,
                  durationSeconds,
                  rirActual,
                  restSeconds = 90,
                  dropSets = const [],
                  existingSetId,
                }) async {},
              ),
              width: v.width,
              scale: v.scale,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('DROP-SET'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'WeeklyComparisonScreen cardio card does not overflow at ${v.width}dp@${v.scale}x',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(v.width, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            wrapForViewport(
              const WeeklyComparisonScreen(),
              width: v.width,
              scale: v.scale,
              scrollable: false,
              overrides: [
                weeklyComparisonProvider.overrideWith(
                  (ref) async => sampleComparisonData,
                ),
              ],
            ),
          );
          await tester.pumpAndSettle();

          await tester.scrollUntilVisible(
            find.text('CARDIO NA SEMANA'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();

          expect(find.text('CARDIO NA SEMANA'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
