import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/widgets/offline_banner_widget.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/last_completed_workout_card.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/insights/presentation/providers/insight_providers.dart';
import 'package:personal_fitness_os/features/profile/presentation/screens/profile_screen.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/progression/domain/repositories/progression_repository.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/settings/presentation/screens/settings_screen.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/workout_queue_provider.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_local_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_remote_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/logged_set_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/session_exercise_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/workout_session_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/repositories/session_repository_impl.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/helpers/session_exercise_builder.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/screens/workout_session_screen.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/logged_set_row.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/session_exercise_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRemoteDataSource extends Mock implements SessionRemoteDataSource {}

class _StubProgressionRepo implements ProgressionRepository {
  @override
  Future<Result<ExercisePerformanceHistory?, Failure>>
      getLastExercisePerformance(String exerciseId) async =>
          const Success(null);

  @override
  Future<Result<List<ExercisePerformanceHistory>, Failure>>
      getRecentExercisePerformances(
    String exerciseId, {
    int limit = 2,
  }) async =>
          const Success([]);
}

class _StubExerciseListNotifier extends ExerciseListNotifier {
  _StubExerciseListNotifier(super.ref, List<Exercise> exercises) {
    state = AsyncValue.data(exercises);
  }

  @override
  Future<void> loadExercises() async {}
}

class _NoopSessionRepo implements SessionRepository {
  _NoopSessionRepo(this._session);
  final WorkoutSession _session;

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
      Success(SessionExercise(id: 'se-new', sessionId: sessionId, exerciseId: exerciseId));

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
  }) async =>
      Success(_session);

  @override
  Future<Result<WorkoutSession?, Failure>> getActiveSession() async =>
      const Success(null);

  @override
  Future<Result<WorkoutSession, Failure>> getSessionById(String id) async =>
      Success(_session);

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
      Success(
        LoggedSet(
          id: existingSetId ?? 'ls-$setNumber',
          sessionExerciseId: sessionExerciseId,
          setNumber: setNumber,
          setType: setType,
          weightKg: weightKg,
          repsCompleted: repsCompleted,
          durationSeconds: durationSeconds,
          dropSets: dropSets,
        ),
      );

  @override
  Future<Result<WorkoutSession, Failure>> startSession({
    String? workoutId,
    String? workoutName,
    List<SessionExercise>? initialExercises,
  }) async =>
      Success(_session);

  @override
  Future<Result<SessionExercise, Failure>> swapSessionExercise({
    required String sessionExerciseId,
    required String newExerciseId,
    String? replacedExerciseId,
  }) async =>
      Success(
        SessionExercise(
          id: sessionExerciseId,
          sessionId: _session.id,
          exerciseId: newExerciseId,
        ),
      );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  Widget wrap(
    Widget child, {
    List<Override> overrides = const [],
    Size viewport = const Size(390, 844),
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MediaQuery(
        data: MediaQueryData(size: viewport),
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: child,
        ),
      ),
    );
  }

  group('1. Two-digit reps visibility in LoggedSetRow', () {
    testWidgets(
        'renders 2-digit and 3-digit reps cleanly on compact 320px viewport without truncation',
        (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: LoggedSetRow(
              setNumber: 1,
              defaultWeight: 20.0,
              defaultReps: 9,
              showRir: false,
              onSave: ({
                required weightKg,
                required repsCompleted,
                durationSeconds,
                rirActual,
                required setType,
                dropSets = const [],
                existingSetId,
              }) async {},
            ),
          ),
          viewport: const Size(320, 720),
        ),
      );

      expect(find.text('9'), findsOneWidget);

      final incReps = find.bySemanticsLabel('Aumentar repetições');
      await tester.tap(incReps);
      await tester.pump();
      expect(find.text('10'), findsOneWidget);

      await tester.tap(incReps);
      await tester.pump();
      await tester.tap(incReps);
      await tester.pump();
      expect(find.text('12'), findsOneWidget);

      final repsBox = tester.getSize(find.text('12'));
      expect(repsBox.width, greaterThan(0));
      expect(repsBox.height, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  });

  group('2. Default rest duration of 3 minutes (180s)', () {
    test('defaults are 180s across constants, SetTemplate, SessionExercise and UserSettingsState',
        () {
      expect(AppConstants.defaultRestSeconds, 180);
      expect(
        const SetTemplate(id: 'st-1', workoutExerciseId: 'we-1', setNumber: 1)
            .restSeconds,
        180,
      );
      expect(
        const SessionExercise(id: 'se-1', sessionId: 's-1', exerciseId: 'ex-1')
            .targetRestSeconds,
        180,
      );
      expect(const UserSettingsState().defaultRestSeconds, 180);
    });

    testWidgets('starts 02:00 rest timer for lighter 10-15 rep exercises and 03:00 for heavy 6-10 rep exercises',
        (tester) async {
      const exLight = Exercise(
        id: 'ex-1',
        name: 'Tríceps Acima da Cabeça',
        primaryMuscleGroup: 'triceps',
        equipment: 'dumbbell',
        movementPattern: 'isolation',
      );
      const exHeavy = Exercise(
        id: 'ex-2',
        name: 'Supino Reto com Barra',
        primaryMuscleGroup: 'chest',
        equipment: 'barbell',
        movementPattern: 'horizontal_push',
      );
      final session = WorkoutSession(
        id: 's-1',
        userId: 'u-1',
        workoutName: 'Especialização Braços',
        startedAt: DateTime(2026, 11, 21, 10, 0),
        exercises: const [
          SessionExercise(
            id: 'se-1',
            sessionId: 's-1',
            exerciseId: 'ex-1',
            exercise: exLight,
            targetSetsCount: 2,
            targetRepsMin: 10,
            targetRepsMax: 15,
          ),
          SessionExercise(
            id: 'se-2',
            sessionId: 's-1',
            exerciseId: 'ex-2',
            exercise: exHeavy,
            targetSetsCount: 3,
            targetRepsMin: 6,
            targetRepsMax: 10,
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(
          const WorkoutSessionScreen(sessionId: 's-1'),
          overrides: [
            sessionRepositoryProvider
                .overrideWithValue(_NoopSessionRepo(session)),
            progressionRepositoryProvider
                .overrideWithValue(_StubProgressionRepo()),
            exerciseListStateProvider.overrideWith(
              (ref) => _StubExerciseListNotifier(ref, const [exLight, exHeavy]),
            ),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check_rounded).first);
      await tester.pump();
      expect(find.text('02:00'), findsOneWidget);

      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();

      // Expand heavy compound exercise and verify 3-min rest timer
      await tester.scrollUntilVisible(
        find.text('Supino Reto com Barra'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Supino Reto com Barra'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check_rounded).first);
      await tester.pump();
      expect(find.text('03:00'), findsOneWidget);

      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();
    });
  });

  group('3. Offline fallback mid-workout & outbox sync', () {
    test('queues logSet & finishSession when network drops mid-session and syncs on reconnect',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final local = SessionLocalDataSource(prefs);
      final remote = _MockRemoteDataSource();

      final sessionModel = WorkoutSessionModel(
        id: 'sess-offline-1',
        userId: 'u-1',
        workoutId: 'w-1',
        workoutName: 'Upper A',
        startedAt: DateTime(2026, 11, 21, 10, 0),
        exercises: const [
          SessionExerciseModel(
            id: 'se-1',
            sessionId: 'sess-offline-1',
            exerciseId: 'ex-1',
            targetSetsCount: 2,
            targetRestSeconds: 180,
          ),
        ],
      );

      var offline = false;
      final fallbackEvents = <bool>[];
      final pendingCounts = <int>[];

      final repo = SessionRepositoryImpl(
        remote,
        localDataSource: local,
        isOfflineMode: () => offline,
        onConnectivityFallback: fallbackEvents.add,
        onPendingCountChanged: pendingCounts.add,
      );

      // Online initial load caches session locally
      when(() => remote.fetchSessionById('sess-offline-1'))
          .thenAnswer((_) async => sessionModel);
      final fetched = await repo.getSessionById('sess-offline-1');
      expect(fetched.isSuccess, isTrue);

      // Network drops mid-workout while connectivity flag hasn't even flipped yet
      when(() => remote.insertLoggedSet(any()))
          .thenThrow(const SocketException('Failed host lookup'));

      final setRes = await repo.logSet(
        sessionExerciseId: 'se-1',
        setNumber: 1,
        weightKg: 20,
        repsCompleted: 12,
      );
      expect(setRes.isSuccess, isTrue);
      expect(fallbackEvents, contains(true));
      expect(local.pendingCount, 1);

      // Now explicitly offline when finishing workout
      offline = true;
      final finishRes = await repo.finishSession(
        sessionId: 'sess-offline-1',
        durationSeconds: 1800,
      );
      expect(finishRes.isSuccess, isTrue);
      expect((finishRes as Success<WorkoutSession, Failure>).value.isCompleted,
          isTrue);
      expect(local.pendingCount, 2);

      // Cached session preserves the logged set & completed status
      final cachedSession = await repo.getSessionById('sess-offline-1');
      expect(cachedSession.isSuccess, isTrue);
      final cachedValue = (cachedSession as Success<WorkoutSession, Failure>).value;
      expect(cachedValue.isCompleted, isTrue);
      expect(cachedValue.exercises.first.sets.length, 1);
      expect(cachedValue.exercises.first.sets.first.repsCompleted, 12);

      // Reconnect and sync FIFO outbox
      offline = false;
      when(() => remote.insertLoggedSet(any())).thenAnswer(
        (_) async => const LoggedSetModel(
          id: 'synced-set-1',
          sessionExerciseId: 'se-1',
          setNumber: 1,
          weightKg: 20,
          repsCompleted: 12,
        ),
      );
      when(() => remote.updateSession('sess-offline-1', any())).thenAnswer(
        (_) async => sessionModel.copyWith(status: 'completed'),
      );

      final synced = await repo.syncPendingOperations();
      expect(synced, isTrue);
      expect(local.pendingCount, 0);
      expect(fallbackEvents.last, isFalse);
      // 1st call threw SocketException mid-workout; 2nd call succeeded on sync.
      verify(() => remote.insertLoggedSet(any())).called(2);
      verify(() => remote.updateSession('sess-offline-1', any())).called(1);
    });

    testWidgets('WorkoutSessionScreen displays OfflineBannerWidget immediately when connectivity drops',
        (tester) async {
      final onlineController = StreamController<bool>.broadcast();
      addTearDown(onlineController.close);

      const ex = Exercise(
        id: 'ex-1',
        name: 'Supino',
        primaryMuscleGroup: 'chest',
      );
      final session = WorkoutSession(
        id: 's-1',
        userId: 'u-1',
        workoutName: 'Upper A',
        startedAt: DateTime(2026, 11, 21, 10, 0),
        exercises: const [
          SessionExercise(
            id: 'se-1',
            sessionId: 's-1',
            exerciseId: 'ex-1',
            exercise: ex,
            targetSetsCount: 2,
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(
          const WorkoutSessionScreen(sessionId: 's-1'),
          overrides: [
            sessionRepositoryProvider
                .overrideWithValue(_NoopSessionRepo(session)),
            progressionRepositoryProvider
                .overrideWithValue(_StubProgressionRepo()),
            exerciseListStateProvider.overrideWith(
              (ref) => _StubExerciseListNotifier(ref, const [ex]),
            ),
            isOnlineStreamProvider.overrideWith((_) => onlineController.stream),
          ],
        ),
      );

      onlineController.add(true);
      await tester.pumpAndSettle();
      expect(find.byType(OfflineBannerWidget), findsNothing);

      // Turn off internet mid-workout
      onlineController.add(false);
      await tester.pumpAndSettle();
      expect(find.byType(OfflineBannerWidget), findsOneWidget);
      expect(find.textContaining('Modo Offline'), findsOneWidget);
    });
  });

  group('4. Drop-set tracking & serialization', () {
    test('calculates total volume and serializes drop_sets + notes fallback', () {
      const logged = LoggedSet(
        id: 'ls-1',
        sessionExerciseId: 'se-1',
        setNumber: 1,
        setType: SetType.dropSet,
        weightKg: 20,
        repsCompleted: 12,
        dropSets: [DropSetEntry(weightKg: 15, repsCompleted: 3)],
      );

      expect(logged.volumeKg, 285.0); // (20 * 12) + (15 * 3)
      expect(logged.formattedDropSummary, '+3×15kg');

      final model = LoggedSetModel.fromDomain(logged);
      final json = model.toJson();
      expect(json['set_type'], 'drop_set');
      expect(json['drop_sets'], [
        {'weight_kg': 15.0, 'reps_completed': 3}
      ]);

      final encodedNotes = LoggedSetModel.attachDropsMarkerToNotes(
        'Boa execução',
        logged.dropSets,
      );
      final fromLegacyNotes = LoggedSetModel.fromJson({
        'id': 'ls-1',
        'session_exercise_id': 'se-1',
        'set_number': 1,
        'set_type': 'drop_set',
        'weight_kg': 20,
        'reps_completed': 12,
        'notes': encodedNotes,
      }).toDomain();

      expect(fromLegacyNotes.notes, 'Boa execução');
      expect(fromLegacyNotes.dropSets.length, 1);
      expect(fromLegacyNotes.dropSets.first.weightKg, 15.0);
      expect(fromLegacyNotes.dropSets.first.repsCompleted, 3);
    });

    testWidgets('LoggedSetRow supports cycling to DROP (20kg x 12 + 15kg x 3) and saving',
        (tester) async {
      SetType? savedType;
      double? savedWeight;
      int? savedReps;
      List<DropSetEntry>? savedDrops;

      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: LoggedSetRow(
              setNumber: 1,
              defaultWeight: 20.0,
              defaultReps: 12,
              weightIncrement: 2.5,
              showRir: false,
              onSave: ({
                required weightKg,
                required repsCompleted,
                durationSeconds,
                rirActual,
                required setType,
                dropSets = const [],
                existingSetId,
              }) async {
                savedType = setType;
                savedWeight = weightKg;
                savedReps = repsCompleted;
                savedDrops = dropSets;
              },
            ),
          ),
        ),
      );

      // 1st tap: 1 -> AQ; 2nd tap: AQ -> DROP
      await tester.tap(find.text('1'));
      await tester.pump();
      expect(find.text('AQ'), findsOneWidget);

      await tester.tap(find.text('AQ'));
      await tester.pump();
      expect(find.text('DROP'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('+3'), findsOneWidget);
      expect(find.text('Outro drop'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pump();

      expect(savedType, SetType.dropSet);
      expect(savedWeight, 20.0);
      expect(savedReps, 12);
      expect(savedDrops, const [DropSetEntry(weightKg: 15.0, repsCompleted: 3)]);
    });
  });

  group('5. Faithful prescribed set counts (e.g. 2 sets in specialization)', () {
    test('WorkoutSessionModel hydrates 2 working sets from workout templates', () {
      final sessionJson = {
        'id': 's-spec',
        'user_id': 'u-1',
        'workout_id': 'w-spec',
        'started_at': '2026-11-21T10:00:00Z',
        'status': 'in_progress',
        'workouts': {
          'name': 'Especialização Braços',
          'workout_exercises': [
            {
              'id': 'we-1',
              'exercise_id': 'ex-tri',
              'sort_order': 0,
              'set_templates': [
                {
                  'id': 'st-1',
                  'workout_exercise_id': 'we-1',
                  'set_number': 1,
                  'set_type': 'working',
                  'target_reps_min': 10,
                  'target_reps_max': 15,
                  'rest_seconds': 180,
                },
                {
                  'id': 'st-2',
                  'workout_exercise_id': 'we-1',
                  'set_number': 2,
                  'set_type': 'working',
                  'target_reps_min': 10,
                  'target_reps_max': 15,
                  'rest_seconds': 180,
                },
              ],
            },
          ],
        },
        'workout_session_exercises': [
          {
            'id': 'se-1',
            'session_id': 's-spec',
            'exercise_id': 'ex-tri',
            'sort_order': 0,
            'logged_sets': [],
          },
        ],
      };

      final domain = WorkoutSessionModel.fromJson(sessionJson).toDomain();
      expect(domain.exercises.first.targetSetsCount, 2);
      expect(domain.exercises.first.targetRepsMin, 10);
      expect(domain.exercises.first.targetRepsMax, 15);
      expect(domain.exercises.first.targetRestSeconds, 120);
      expect(domain.exercises.first.prescribedSetTypes,
          [SetType.working, SetType.working]);
    });

    test('buildInitialSessionExercises preserves 2 sets and working rest time', () {
      const workout = Workout(
        id: 'w-spec',
        trainingPlanId: 'p-1',
        name: 'Especialização',
        exercises: [
          WorkoutExercise(
            id: 'we-1',
            workoutId: 'w-spec',
            exerciseId: 'ex-tri',
            setTemplates: [
              SetTemplate(
                id: 'st-0',
                workoutExerciseId: 'we-1',
                setNumber: 1,
                setType: SetType.warmup,
                restSeconds: 60,
              ),
              SetTemplate(
                id: 'st-1',
                workoutExerciseId: 'we-1',
                setNumber: 2,
                setType: SetType.working,
                targetRepsMin: 10,
                targetRepsMax: 12,
                restSeconds: 180,
              ),
              SetTemplate(
                id: 'st-2',
                workoutExerciseId: 'we-1',
                setNumber: 3,
                setType: SetType.working,
                targetRepsMin: 10,
                targetRepsMax: 12,
                restSeconds: 180,
              ),
            ],
          ),
        ],
      );

      final built = buildInitialSessionExercises(workout);
      expect(built.first.targetSetsCount, 2);
      expect(built.first.targetRestSeconds, 180);
      expect(built.first.prescribedSetTypes,
          [SetType.warmup, SetType.working, SetType.working]);
    });

    testWidgets('SessionExerciseCard renders exactly 2 set rows when prescribed 2 sets',
        (tester) async {
      const se = SessionExercise(
        id: 'se-2sets',
        sessionId: 's-1',
        exerciseId: 'ex-tri',
        exercise: Exercise(
          id: 'ex-tri',
          name: 'Tríceps Acima da Cabeça',
          primaryMuscleGroup: 'triceps',
        ),
        targetSetsCount: 2,
        targetRepsMin: 10,
        targetRepsMax: 15,
        targetRestSeconds: 180,
      );

      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: SingleChildScrollView(
              child: SessionExerciseCard(
                sessionExercise: se,
                showRir: false,
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
            ),
          ),
          overrides: [
            progressionRepositoryProvider
                .overrideWithValue(_StubProgressionRepo()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0/2 séries'), findsOneWidget);
      expect(find.byType(LoggedSetRow), findsNWidgets(2));
    });
  });

  group('6. Post-workout Dashboard: next workout + last completed workout', () {
    test('WorkoutQueueNotifier.advanceAfterCompleted moves finished workout to end',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const w1 = Workout(id: 'w1', trainingPlanId: 'p1', name: 'Upper A', sortOrder: 0);
      const w2 = Workout(id: 'w2', trainingPlanId: 'p1', name: 'Lower A', sortOrder: 1);
      const w3 = Workout(id: 'w3', trainingPlanId: 'p1', name: 'Especialização', sortOrder: 2);
      final notifier = WorkoutQueueNotifier(prefs: prefs);

      notifier.advanceAfterCompleted('p1', const [w1, w2, w3], 'w1');
      expect(
        notifier.orderedWorkouts('p1', const [w1, w2, w3]).map((w) => w.id),
        ['w2', 'w3', 'w1'],
      );

      notifier.advanceAfterCompleted('p1', const [w1, w2, w3], 'w3');
      expect(
        notifier.orderedWorkouts('p1', const [w1, w2, w3]).map((w) => w.id),
        ['w1', 'w2', 'w3'],
      );
    });

    test(
        'WorkoutQueueNotifier.orderedWorkouts advances past lastCompletedWorkoutId when no custom order is saved',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const w1 = Workout(id: 'w1', trainingPlanId: 'p1', name: 'Especialização', sortOrder: 0);
      const w2 = Workout(id: 'w2', trainingPlanId: 'p1', name: 'Upper A', sortOrder: 1);
      const w3 = Workout(id: 'w3', trainingPlanId: 'p1', name: 'Lower A', sortOrder: 2);
      final notifier = WorkoutQueueNotifier(prefs: prefs);

      expect(
        notifier
            .orderedWorkouts(
              'p1',
              const [w1, w2, w3],
              lastCompletedWorkoutId: w1.id,
            )
            .map((w) => w.id),
        ['w2', 'w3', 'w1'],
      );

      // Explicit user selection overrides fallback even if it picks lastCompletedWorkoutId
      notifier.selectNext('p1', const [w1, w2, w3], w1.id);
      // Note: selectNext is no-op when idx <= 0 unless custom order has shifted first
      notifier.selectNext('p1', const [w2, w3, w1], w1.id);
      expect(
        notifier
            .orderedWorkouts(
              'p1',
              const [w1, w2, w3],
              lastCompletedWorkoutId: w1.id,
            )
            .map((w) => w.id),
        ['w1', 'w2', 'w3'],
      );
    });

    testWidgets('DashboardScreen displays next workout hero and LastCompletedWorkoutCard below it',
        (tester) async {
      const nextWorkout = Workout(
        id: 'w-next',
        trainingPlanId: 'p-1',
        name: 'Lower A',
        sortOrder: 1,
      );
      final completedSession = WorkoutSession(
        id: 's-prev',
        userId: 'u-1',
        workoutId: 'w-prev',
        workoutName: 'Especialização Braços',
        startedAt: DateTime.now().subtract(const Duration(hours: 2)),
        completedAt: DateTime.now().subtract(const Duration(hours: 1)),
        durationSeconds: 2700,
        status: SessionStatus.completed,
        perceivedExertion: 8.5,
        mood: Mood.good,
        exercises: const [
          SessionExercise(
            id: 'se-1',
            sessionId: 's-prev',
            exerciseId: 'ex-1',
            sets: [
              LoggedSet(
                id: 'ls-1',
                sessionExerciseId: 'se-1',
                setNumber: 1,
                weightKg: 20,
                repsCompleted: 12,
                dropSets: [DropSetEntry(weightKg: 15, repsCompleted: 3)],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(
          const DashboardScreen(),
          overrides: [
            dashboardDataProvider.overrideWith(
              (_) async => DashboardData(
                activePlan: const TrainingPlan(
                  id: 'p-1',
                  userId: 'u-1',
                  name: 'Upper / Lower',
                  isActive: true,
                  workouts: [nextWorkout],
                ),
                todayWorkout: nextWorkout,
                lastCompletedSession: completedSession,
              ),
            ),
            fitnessInsightsProvider.overrideWith((_) async => const []),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lower A'), findsOneWidget);
      expect(find.byType(LastCompletedWorkoutCard), findsOneWidget);
      expect(find.text('Último treino realizado'), findsOneWidget);
      expect(find.text('Especialização Braços'), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
      expect(find.text('285 kg'), findsOneWidget);

      // Separated Profile and Settings buttons in header
      expect(find.bySemanticsLabel('Abrir perfil'), findsOneWidget);
      expect(find.bySemanticsLabel('Abrir configurações'), findsOneWidget);
    });
  });

  group('7. Separated Profile & Settings screens', () {
    testWidgets('SettingsScreen excludes profile/body sections and links to Meu Perfil',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const SettingsScreen(),
          overrides: [
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Treino e equipamentos'), findsOneWidget);
      expect(find.text('Descanso padrão'), findsOneWidget);
      expect(find.text('3:00 (180s)'), findsOneWidget);
      expect(find.text('PERFIL & OBJETIVO'), findsNothing);

      await tester.scrollUntilVisible(find.text('Meu Perfil'), 200);
      expect(find.text('Conta'), findsOneWidget);
      expect(find.text('Meu Perfil'), findsOneWidget);
    });

    testWidgets('ProfileScreen exposes avatar picker, body data and goals',
        (tester) async {
      await tester.pumpWidget(wrap(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Dados corporais e objetivo'), findsOneWidget);
      expect(find.text('Dados corporais'), findsOneWidget);
      expect(find.text('Objetivo atual'), findsOneWidget);
      expect(find.text('Metas calculadas'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Alterar foto de perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Tirar foto'), findsOneWidget);
      expect(find.text('Escolher da galeria'), findsOneWidget);
    });
  });
}
