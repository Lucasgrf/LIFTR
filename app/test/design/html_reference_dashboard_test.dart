import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/app.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/day_adherence.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/weekly_stats.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_stats.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/progression/domain/repositories/progression_repository.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_comparison_data.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_snapshot.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/providers/weekly_comparison_providers.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/routing/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../goldens/golden_test_helpers.dart';

final _htmlNow = DateTime(2026, 11, 27, 12);

class _HtmlProgressionRepository implements ProgressionRepository {
  static const _sets = <String, (double, List<int>)>{
    'stiff': (50, [10, 9, 8]),
    'hip': (80, [10, 10, 9, 9]),
    'press': (120, [10, 10, 10]),
  };

  @override
  Future<Result<ExercisePerformanceHistory?, Failure>>
  getLastExercisePerformance(String exerciseId) async {
    final entry = _sets[exerciseId];
    if (entry == null) return const Success(null);
    return Success(
      ExercisePerformanceHistory(
        exerciseId: exerciseId,
        workoutSessionId: 'html-previous-session',
        workoutName: 'Lower B',
        date: _htmlNow.subtract(const Duration(days: 7)),
        loggedSets: [
          for (var index = 0; index < entry.$2.length; index++)
            LoggedSet(
              id: '$exerciseId-$index',
              sessionExerciseId: exerciseId,
              setNumber: index + 1,
              weightKg: entry.$1,
              repsCompleted: entry.$2[index],
            ),
        ],
      ),
    );
  }

  @override
  Future<Result<List<ExercisePerformanceHistory>, Failure>>
  getRecentExercisePerformances(String exerciseId, {int limit = 2}) async {
    final last = await getLastExercisePerformance(exerciseId);
    return last.fold(
      (value) => Success(value == null ? const [] : [value]),
      (failure) => Err(failure),
    );
  }
}

WorkoutExercise _exercise({
  required String id,
  required String name,
  required String muscle,
  required int sets,
  required int repsMin,
  required int repsMax,
  required double weight,
}) {
  final exercise = Exercise(
    id: id,
    name: name,
    primaryMuscleGroup: muscle,
    equipment: 'barbell',
  );
  return WorkoutExercise(
    id: 'we-$id',
    workoutId: 'w-lower-b',
    exerciseId: id,
    exercise: exercise,
    setTemplates: [
      for (var number = 1; number <= sets; number++)
        SetTemplate(
          id: 'st-$id-$number',
          workoutExerciseId: 'we-$id',
          setNumber: number,
          targetRepsMin: repsMin,
          targetRepsMax: repsMax,
          targetWeight: weight,
          targetRirMin: 2,
          targetRirMax: 2,
        ),
    ],
  );
}

Workout _queueWorkout(String id, String name, int index) => Workout(
  id: id,
  trainingPlanId: 'html-plan',
  name: name,
  sortOrder: index,
  estimatedDurationMinutes: 55,
);

WorkoutSession _completedSession(String id, String name, DateTime date) =>
    WorkoutSession(
      id: id,
      userId: 'html-user',
      workoutId: id,
      workoutName: name,
      startedAt: date,
      completedAt: date,
      durationSeconds: 3000,
      status: SessionStatus.completed,
    );

class _HtmlTrainingPlansNotifier extends TrainingPlansNotifier {
  _HtmlTrainingPlansNotifier(Ref ref, List<TrainingPlan> plans) : super(ref) {
    state = AsyncValue.data(plans);
  }

  @override
  Future<void> loadPlans() async {}
}

SetTemplate _detailSet(
  String exerciseId,
  int number, {
  required SetType type,
  required int? repsMin,
  required int? repsMax,
  required double? weight,
  int restSeconds = 180,
}) => SetTemplate(
  id: 'html-$exerciseId-$number',
  workoutExerciseId: 'we-$exerciseId',
  setNumber: number,
  setType: type,
  targetRepsMin: repsMin,
  targetRepsMax: repsMax,
  targetWeight: weight,
  targetRirMin: 2,
  targetRirMax: 2,
  restSeconds: restSeconds,
);

WorkoutExercise _detailExercise(
  String id,
  String name,
  List<SetTemplate> sets,
) => WorkoutExercise(
  id: 'we-$id',
  workoutId: 'html-workout',
  exerciseId: id,
  exercise: Exercise(
    id: id,
    name: name,
    primaryMuscleGroup: 'legs',
    equipment: 'barbell',
  ),
  setTemplates: sets,
);

TrainingPlan _htmlDetailPlan() {
  final stiffSets = [
    _detailSet(
      'stiff',
      1,
      type: SetType.warmup,
      repsMin: 10,
      repsMax: 10,
      weight: null,
    ),
    _detailSet(
      'stiff',
      2,
      type: SetType.rampUp,
      repsMin: 6,
      repsMax: 8,
      weight: 30,
    ),
    for (var number = 3; number <= 5; number++)
      _detailSet(
        'stiff',
        number,
        type: SetType.working,
        repsMin: 6,
        repsMax: 10,
        weight: 50,
      ),
  ];
  final hipSets = [
    _detailSet(
      'hip',
      1,
      type: SetType.warmup,
      repsMin: 10,
      repsMax: 10,
      weight: 40,
    ),
    for (var number = 2; number <= 5; number++)
      _detailSet(
        'hip',
        number,
        type: SetType.working,
        repsMin: 8,
        repsMax: 10,
        weight: 80,
      ),
  ];
  final workout = Workout(
    id: 'html-workout',
    trainingPlanId: 'html-plan',
    name: 'Lower B',
    sortOrder: 0,
    notes: 'Foco em posterior de coxa e glúteos.',
    estimatedDurationMinutes: 55,
    exercises: [
      _detailExercise('stiff', 'Stiff com barra', stiffSets),
      _detailExercise('hip', 'Elevação pélvica com barra', hipSets),
      _detailExercise('press', 'Leg press 45° unilateral', [
        for (var number = 1; number <= 3; number++)
          _detailSet(
            'press',
            number,
            type: SetType.working,
            repsMin: 8,
            repsMax: 10,
            weight: 120,
            restSeconds: 0,
          ),
      ]),
      for (final (id, name, weight) in const [
        ('flexora', 'Cadeira flexora', 30.0),
        ('extensora', 'Cadeira extensora', 50.0),
        ('panturrilha', 'Panturrilha no hack', 100.0),
      ])
        _detailExercise(id, name, [
          for (var number = 1; number <= (id == 'extensora' ? 2 : 3); number++)
            _detailSet(
              id,
              number,
              type: SetType.working,
              repsMin: 12,
              repsMax: 15,
              weight: weight,
              restSeconds: 0,
            ),
        ]),
    ],
  );
  return TrainingPlan(
    id: 'html-plan',
    userId: 'html-user',
    name: 'Upper/Lower + Especialização',
    isActive: true,
    workouts: [
      workout,
      _queueWorkout('w-special', 'Especialização', 1),
      _queueWorkout('w-upper-a', 'Upper A', 2),
      _queueWorkout('w-lower-a', 'Lower A', 3),
      _queueWorkout('w-upper-b', 'Upper B', 4),
    ],
  );
}

Workout _htmlCountedWorkout(
  String id,
  String name,
  int sortOrder,
  int exerciseCount,
  int workingSetCount,
) {
  final baseSets = workingSetCount ~/ exerciseCount;
  final extraSets = workingSetCount % exerciseCount;
  return Workout(
    id: id,
    trainingPlanId: 'html-plan',
    name: name,
    sortOrder: sortOrder,
    estimatedDurationMinutes: 55,
    exercises: [
      for (var index = 0; index < exerciseCount; index++)
        _exercise(
          id: '$id-ex-$index',
          name: 'Exercício ${index + 1}',
          muscle: 'legs',
          sets: baseSets + (index < extraSets ? 1 : 0),
          repsMin: 8,
          repsMax: 12,
          weight: 40,
        ),
    ],
  );
}

TrainingPlan _htmlProgramPlan() {
  final detail = _htmlDetailPlan();
  return detail.copyWith(
    workouts: [
      detail.workouts.first,
      _htmlCountedWorkout('special', 'Especialização', 1, 11, 27),
      _htmlCountedWorkout('upper-a', 'Upper A', 2, 10, 25),
      _htmlCountedWorkout('lower-a', 'Lower A', 3, 7, 20),
      _htmlCountedWorkout('upper-b', 'Upper B', 4, 11, 26),
    ],
  );
}

SessionExercise _progressExercise(
  String id,
  String name, {
  required int targetSets,
  required int repsMin,
  required int repsMax,
  required double weight,
  required List<int> reps,
}) {
  final exercise = Exercise(
    id: id,
    name: name,
    primaryMuscleGroup: 'legs',
    equipment: 'dumbbell',
  );
  return SessionExercise(
    id: 'session-$id',
    sessionId: 'html-progress-current',
    exerciseId: id,
    exercise: exercise,
    targetSetsCount: targetSets,
    targetRepsMin: repsMin,
    targetRepsMax: repsMax,
    sets: [
      for (var index = 0; index < reps.length; index++)
        LoggedSet(
          id: '$id-current-$index',
          sessionExerciseId: 'session-$id',
          setNumber: index + 1,
          weightKg: weight,
          repsCompleted: reps[index],
        ),
    ],
  );
}

WorkoutSession _htmlProgressSession(
  String id,
  DateTime date,
  List<SessionExercise> exercises,
) => WorkoutSession(
  id: id,
  userId: 'html-user',
  workoutId: 'html-progress-workout',
  workoutName: 'Upper B',
  startedAt: date,
  completedAt: date,
  durationSeconds: 3600,
  status: SessionStatus.completed,
  exercises: exercises,
);

List<WorkoutSession> _htmlProgressHistory() {
  final currentExercises = [
    _progressExercise(
      'leg-press',
      'Leg press 45°',
      targetSets: 3,
      repsMin: 8,
      repsMax: 10,
      weight: 120,
      reps: const [10, 10, 10],
    ),
    _progressExercise(
      'incline-curl',
      'Rosca inclinada com halteres',
      targetSets: 2,
      repsMin: 12,
      repsMax: 15,
      weight: 8,
      reps: const [11, 11],
    ),
    _progressExercise(
      'pulldown',
      'Puxada aberta pronada',
      targetSets: 3,
      repsMin: 8,
      repsMax: 10,
      weight: 60,
      reps: const [2, 2, 2],
    ),
    _progressExercise(
      'wrist-curl',
      'Rosca de punho',
      targetSets: 3,
      repsMin: 12,
      repsMax: 15,
      weight: 15,
      reps: const [10, 10, 10],
    ),
    for (var index = 0; index < 6; index++)
      _progressExercise(
        'rising-$index',
        'Exercício em progressão ${index + 1}',
        targetSets: 3,
        repsMin: 8,
        repsMax: 12,
        weight: 30 + index.toDouble(),
        reps: const [12, 12, 12],
      ),
  ];
  final previousChanges = [
    _progressExercise(
      'incline-curl',
      'Rosca inclinada com halteres',
      targetSets: 2,
      repsMin: 12,
      repsMax: 15,
      weight: 8,
      reps: const [10, 10],
    ),
    _progressExercise(
      'pulldown',
      'Puxada aberta pronada',
      targetSets: 3,
      repsMin: 8,
      repsMax: 10,
      weight: 60,
      reps: const [1, 1, 1],
    ),
    _progressExercise(
      'wrist-curl',
      'Rosca de punho',
      targetSets: 3,
      repsMin: 12,
      repsMax: 15,
      weight: 15,
      reps: const [10, 10, 10],
    ),
  ];
  final olderWrist = _progressExercise(
    'wrist-curl',
    'Rosca de punho',
    targetSets: 3,
    repsMin: 12,
    repsMax: 15,
    weight: 15,
    reps: const [10, 10, 10],
  );
  return [
    _htmlProgressSession(
      'html-progress-current',
      DateTime(2026, 11, 26, 18),
      currentExercises,
    ),
    _htmlProgressSession(
      'html-progress-previous',
      DateTime(2026, 11, 19, 18),
      previousChanges,
    ),
    _htmlProgressSession('html-progress-older-1', DateTime(2026, 11, 12, 18), [
      olderWrist,
    ]),
    _htmlProgressSession('html-progress-older-2', DateTime(2026, 11, 5, 18), [
      olderWrist,
    ]),
  ];
}

Future<void> _pumpHtmlAppAtRoute(
  WidgetTester tester, {
  required SharedPreferences prefs,
  required String route,
  required List<Override> overrides,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appClockProvider.overrideWithValue(() => _htmlNow),
      authStateProvider.overrideWith((_) => true),
      isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
      sessionLocalDataSourceProvider.overrideWithValue(null),
      sessionAutoSyncProvider.overrideWith((_) {}),
      pendingSyncCountProvider.overrideWith((_) => 0),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  final router = container.read(goRouterProvider);
  router.go(route);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

WorkoutSession _htmlSummarySession(TrainingPlan plan) {
  final workout = plan.workouts.last;
  var setId = 0;
  SessionExercise exercise({
    required String id,
    required String name,
    required int targetSets,
    required List<(double, int, bool)> sets,
  }) {
    final entity = Exercise(
      id: id,
      name: name,
      primaryMuscleGroup: name == 'Cardio' ? 'cardio' : 'back',
      equipment: 'machine',
    );
    return SessionExercise(
      id: 'session-$id',
      sessionId: 'html-summary',
      exerciseId: id,
      exercise: entity,
      targetSetsCount: targetSets,
      targetRepsMin: 8,
      targetRepsMax: 12,
      sets: [
        for (final (weight, reps, warmup) in sets)
          LoggedSet(
            id: 'html-summary-set-${setId++}',
            sessionExerciseId: 'session-$id',
            setNumber: setId,
            weightKg: weight,
            repsCompleted: reps,
            isWarmup: warmup,
            dropSets: id == 'pull' && !warmup && (reps == 7 || reps == 5)
                ? const [DropSetEntry(weightKg: 50, repsCompleted: 4)]
                : const [],
          ),
      ],
    );
  }

  final exercises = [
    exercise(
      id: 'pull',
      name: 'Puxada aberta pronada',
      targetSets: 5,
      sets: const [
        (20, 10, true),
        (20, 10, true),
        (60, 7, false),
        (60, 5, false),
        (60, 4, false),
      ],
    ),
    exercise(
      id: 'row',
      name: 'Remada na máquina articulada',
      targetSets: 5,
      sets: const [(50, 8, false), (50, 8, false), (50, 8, false)],
    ),
    exercise(
      id: 'incline',
      name: 'Supino inclinado com barra',
      targetSets: 5,
      sets: const [
        (0, 10, true),
        (0, 10, true),
        (30, 10, false),
        (30, 10, false),
        (30, 8, false),
      ],
    ),
    exercise(
      id: 'pulldown',
      name: 'Pulldown com corda',
      targetSets: 4,
      sets: const [(25, 15, false), (25, 13, false)],
    ),
    exercise(
      id: 'rear-delt',
      name: 'Crucifixo inverso no peck deck',
      targetSets: 6,
      sets: const [(30, 15, false), (30, 13, false), (30, 12, false)],
    ),
    for (final (id, name) in const [
      ('lateral', 'Elevação lateral'),
      ('curl', 'Rosca direta'),
    ])
      exercise(
        id: id,
        name: name,
        targetSets: 0,
        sets: const [
          (43, 3, false),
          (43, 3, false),
          (43, 3, false),
          (43, 3, false),
        ],
      ),
    exercise(id: 'abs', name: 'Abdominal', targetSets: 0, sets: const []),
    exercise(id: 'cardio', name: 'Cardio', targetSets: 0, sets: const []),
  ];
  return WorkoutSession(
    id: 'html-summary',
    userId: 'html-user',
    workoutId: workout.id,
    workoutName: workout.name,
    startedAt: DateTime(2026, 11, 26, 21, 39),
    completedAt: DateTime(2026, 11, 26, 23, 3),
    durationSeconds: 84 * 60,
    status: SessionStatus.completed,
    perceivedExertion: 7.5,
    executionScore: 85,
    exercises: exercises,
  );
}

({DashboardData dashboard, WeeklyComparisonData comparison})
_htmlDashboardFixture() {
  final exercises = [
    _exercise(
      id: 'stiff',
      name: 'Stiff com barra',
      muscle: 'legs',
      sets: 3,
      repsMin: 6,
      repsMax: 10,
      weight: 50,
    ),
    _exercise(
      id: 'hip',
      name: 'Elevação pélvica com barra',
      muscle: 'glutes',
      sets: 4,
      repsMin: 8,
      repsMax: 10,
      weight: 80,
    ),
    _exercise(
      id: 'press',
      name: 'Leg press 45° unilateral',
      muscle: 'legs',
      sets: 3,
      repsMin: 8,
      repsMax: 10,
      weight: 120,
    ),
    _exercise(
      id: 'flexora',
      name: 'Cadeira flexora',
      muscle: 'legs',
      sets: 3,
      repsMin: 12,
      repsMax: 15,
      weight: 30,
    ),
    _exercise(
      id: 'extensora',
      name: 'Cadeira extensora',
      muscle: 'legs',
      sets: 3,
      repsMin: 12,
      repsMax: 15,
      weight: 50,
    ),
    _exercise(
      id: 'panturrilha',
      name: 'Panturrilha no hack',
      muscle: 'legs',
      sets: 2,
      repsMin: 12,
      repsMax: 15,
      weight: 100,
    ),
  ];
  final lowerB = Workout(
    id: 'w-lower-b',
    trainingPlanId: 'html-plan',
    name: 'Lower B',
    sortOrder: 0,
    estimatedDurationMinutes: 55,
    exercises: exercises,
  );
  final plan = TrainingPlan(
    id: 'html-plan',
    userId: 'html-user',
    name: 'Upper/Lower + Especialização',
    isActive: true,
    workouts: [
      lowerB,
      _queueWorkout('w-special', 'Especialização', 1),
      _queueWorkout('w-upper-a', 'Upper A', 2),
      _queueWorkout('w-lower-a', 'Lower A', 3),
      _queueWorkout('w-upper-b', 'Upper B', 4),
    ],
  );
  final weeklySessions = [
    _completedSession('ua', 'Upper A', DateTime(2026, 11, 23, 18)),
    _completedSession('la', 'Lower A', DateTime(2026, 11, 24, 18)),
    _completedSession('ub', 'Upper B', DateTime(2026, 11, 26, 23, 3)),
  ];
  final completed = weeklySessions.last.copyWith(
    workoutId: 'w-upper-b',
    durationSeconds: 84 * 60,
  );
  final dashboard = DashboardData(
    activePlan: plan,
    todayWorkout: lowerB,
    lastCompletedSession: completed,
    weeklySessions: weeklySessions,
    weeklyStats: WeeklyStats(
      completedWorkoutsCount: 3,
      targetWorkoutsCount: 5,
      days: [
        for (var index = 0; index < 7; index++)
          DayAdherence(
            date: DateTime(2026, 11, 23 + index),
            dayOfWeek: index == 6 ? 0 : index + 1,
            hasCompletedWorkout: index == 0 || index == 1 || index == 3,
            isToday: index == 4,
          ),
      ],
    ),
  );
  final comparison = WeeklyComparisonData(
    currentWeek: WeeklySnapshot(
      weekStart: DateTime(2026, 11, 23),
      weekEnd: DateTime(2026, 11, 29),
      workoutsCompleted: 3,
      cardioDurationSeconds: 0,
    ),
    previousWeek: WeeklySnapshot(
      weekStart: DateTime(2026, 11, 16),
      weekEnd: DateTime(2026, 11, 22),
      workoutsCompleted: 3,
      cardioDurationSeconds: 600,
    ),
  );
  return (dashboard: dashboard, comparison: comparison);
}

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    prefs = await initializeGoldenTest();
    await prefs.setString('liftr_theme_mode_v1', 'light');
  });

  testWidgets('full Today route matches the HTML fixture at 390x844', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);

    final fixture = _htmlDashboardFixture();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appClockProvider.overrideWithValue(() => _htmlNow),
          authStateProvider.overrideWith((_) => true),
          dashboardDataProvider.overrideWith((_) async => fixture.dashboard),
          currentWeekSummaryProvider.overrideWith(
            (_) async => fixture.comparison,
          ),
          progressionRepositoryProvider.overrideWithValue(
            _HtmlProgressionRepository(),
          ),
          isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          sessionLocalDataSourceProvider.overrideWithValue(null),
          sessionAutoSyncProvider.overrideWith((_) {}),
          pendingSyncCountProvider.overrideWith((_) => 0),
        ],
        child: const App(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Lower B'), findsWidgets);
    expect(find.textContaining('Depois vem Especialização'), findsOneWidget);
    expect(find.text('Stiff com barra'), findsOneWidget);
    expect(find.text('Elevação pélvica com barra'), findsOneWidget);
    expect(find.text('Leg press 45° unilateral'), findsOneWidget);
    expect(find.text('Upper B'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('reference/html-01-today-light.png'),
    );
  });

  testWidgets('full workout detail route matches the HTML fixture at 390x844', (
    tester,
  ) async {
    final plan = _htmlDetailPlan();
    final workout = plan.workouts.first;
    await _pumpHtmlAppAtRoute(
      tester,
      prefs: prefs,
      route: '/training/${plan.id}/workout/${workout.id}',
      overrides: [
        trainingPlansStateProvider.overrideWith(
          (ref) => _HtmlTrainingPlansNotifier(ref, [plan]),
        ),
        workoutDetailProvider((
          planId: plan.id,
          workoutId: workout.id,
        )).overrideWith((_) async => workout),
      ],
    );

    expect(find.text('Foco em posterior de coxa e glúteos.'), findsOneWidget);
    expect(find.text('6. Panturrilha no hack'), findsOneWidget);
    expect(find.text('Começar Lower B'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('reference/html-02-workout-detail.png'),
    );
  });

  testWidgets(
    'full session summary route matches the HTML fixture at 390x844',
    (tester) async {
      final plan = _htmlDetailPlan();
      final session = _htmlSummarySession(plan);
      final previous = session.copyWith(
        id: 'html-previous-upper-b',
        startedAt: DateTime(2026, 11, 19, 21, 39),
        completedAt: DateTime(2026, 11, 19, 23, 3),
        exercises: [
          for (final exercise in session.exercises)
            exercise.copyWith(
              sets: [
                for (final set in exercise.sets)
                  set.copyWith(weightKg: set.weightKg + 5),
              ],
            ),
        ],
      );
      await _pumpHtmlAppAtRoute(
        tester,
        prefs: prefs,
        route: '/session/${session.id}/summary',
        overrides: [
          trainingPlansStateProvider.overrideWith(
            (ref) => _HtmlTrainingPlansNotifier(ref, [plan]),
          ),
          liveSessionDetailProvider(
            session.id,
          ).overrideWith((_) async => session),
          historyListProvider.overrideWith((_) async => [previous]),
        ],
      );

      expect(find.text('Quinta, 26 de novembro'), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('reference/html-03-session-summary.png'),
      );
    },
  );

  testWidgets('full training queue route matches the HTML fixture at 390x844', (
    tester,
  ) async {
    final plan = _htmlProgramPlan();
    await _pumpHtmlAppAtRoute(
      tester,
      prefs: prefs,
      route: '/training',
      overrides: [
        trainingPlansStateProvider.overrideWith(
          (ref) => _HtmlTrainingPlansNotifier(ref, [plan]),
        ),
      ],
    );

    expect(find.text('O baralho'), findsOneWidget);
    expect(find.text('11 exercícios, 27 séries'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('reference/html-04-training-queue.png'),
    );
  });

  testWidgets('full progress exercises route matches the HTML fixture', (
    tester,
  ) async {
    await _pumpHtmlAppAtRoute(
      tester,
      prefs: prefs,
      route: '/history',
      overrides: [
        historyListProvider.overrideWith((_) async => _htmlProgressHistory()),
      ],
    );

    expect(find.text('Leg press 45°'), findsOneWidget);
    expect(find.text('Travado, 1'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('reference/html-05-progress-exercises.png'),
    );
  });

  testWidgets('full consistency route matches the HTML fixture', (
    tester,
  ) async {
    final plan = TrainingPlan(
      id: 'html-cycle',
      userId: 'html-user',
      name: 'Ciclo de treino',
      isActive: true,
      workouts: [_queueWorkout('html-cycle-workout', 'Lower B', 0)],
    );
    final sessions = [
      _completedSession('ep', 'Especialização', DateTime(2026, 11, 21, 18)),
      _completedSession('ua', 'Upper A', DateTime(2026, 11, 23, 18)),
      _completedSession('la', 'Lower A', DateTime(2026, 11, 24, 18)),
      _completedSession('ub', 'Upper B', DateTime(2026, 11, 26, 18)),
    ];
    await _pumpHtmlAppAtRoute(
      tester,
      prefs: prefs,
      route: '/history',
      overrides: [
        historyListProvider.overrideWith((_) async => sessions),
        trainingPlansStateProvider.overrideWith(
          (ref) => _HtmlTrainingPlansNotifier(ref, [plan]),
        ),
      ],
    );
    await tester.tap(find.text('Consistência'));
    await tester.pumpAndSettle();

    expect(find.text('3 treinos esta semana, 4 em novembro.'), findsOneWidget);
    expect(find.text('Novembro'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('reference/html-06-progress-consistency.png'),
    );
  });

  testWidgets('full weight route matches the HTML fixture', (tester) async {
    final entry = WeightEntry(
      id: 'html-weight',
      weightKg: 66,
      measuredAt: _htmlNow,
    );
    await _pumpHtmlAppAtRoute(
      tester,
      prefs: prefs,
      route: '/history',
      overrides: [
        weightHistoryProvider.overrideWith((_) async => [entry]),
        weightStatsProvider.overrideWith(
          (_) async => WeightStats(
            latestEntry: entry,
            trend: WeightTrend.maintaining,
            deltaVsPreviousWeekKg: 0,
          ),
        ),
      ],
    );
    await tester.tap(find.text('Peso'));
    await tester.pumpAndSettle();

    expect(find.text('66,0 kg'), findsOneWidget);
    expect(
      find.text('Falta uma pesagem para desenhar a linha'),
      findsOneWidget,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('reference/html-07-progress-weight.png'),
    );
  });

  testWidgets('dark Today route matches the HTML fixture at 390x844', (
    tester,
  ) async {
    await prefs.setString('liftr_theme_mode_v1', 'dark');
    final fixture = _htmlDashboardFixture();
    await _pumpHtmlAppAtRoute(
      tester,
      prefs: prefs,
      route: '/',
      overrides: [
        dashboardDataProvider.overrideWith((_) async => fixture.dashboard),
        currentWeekSummaryProvider.overrideWith(
          (_) async => fixture.comparison,
        ),
        progressionRepositoryProvider.overrideWithValue(
          _HtmlProgressionRepository(),
        ),
      ],
    );

    expect(find.text('Lower B'), findsWidgets);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('reference/html-08-today-dark.png'),
    );
    await prefs.setString('liftr_theme_mode_v1', 'light');
  });

  testWidgets('first access route matches the HTML fixture at 390x844', (
    tester,
  ) async {
    await prefs.setString('liftr_theme_mode_v1', 'light');
    await _pumpHtmlAppAtRoute(
      tester,
      prefs: prefs,
      route: '/',
      overrides: [
        dashboardDataProvider.overrideWith((_) async => const DashboardData()),
        currentWeekSummaryProvider.overrideWith(
          (_) async => WeeklyComparisonData(
            currentWeek: WeeklySnapshot(
              weekStart: DateTime(2026, 11, 23),
              weekEnd: DateTime(2026, 11, 29),
            ),
          ),
        ),
      ],
    );

    expect(find.textContaining('ficha ainda'), findsOneWidget);
    expect(find.text('Colar código de programa'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('reference/html-09-first-access.png'),
    );
  });

  testWidgets('startup brand mark matches the HTML fixture at 390x844', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await prefs.setString('liftr_theme_mode_v1', 'light');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appClockProvider.overrideWithValue(() => _htmlNow),
          authStateProvider.overrideWith((_) => true),
          dashboardDataProvider.overrideWith(
            (_) async => const DashboardData(),
          ),
          currentWeekSummaryProvider.overrideWith(
            (_) async => WeeklyComparisonData(
              currentWeek: WeeklySnapshot(
                weekStart: DateTime(2026, 11, 23),
                weekEnd: DateTime(2026, 11, 29),
              ),
            ),
          ),
          isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          sessionLocalDataSourceProvider.overrideWithValue(null),
          sessionAutoSyncProvider.overrideWith((_) {}),
          pendingSyncCountProvider.overrideWith((_) => 0),
        ],
        child: const App(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 950));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('reference/html-10-brand-splash.png'),
    );
  });
}
