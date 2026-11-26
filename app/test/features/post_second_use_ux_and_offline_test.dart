import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/history/data/datasources/history_remote_datasource.dart';
import 'package:personal_fitness_os/features/history/data/repositories/history_repository_impl.dart';
import 'package:personal_fitness_os/features/history/domain/entities/exercise_history_record.dart';
import 'package:personal_fitness_os/features/history/domain/entities/history_event_type.dart';
import 'package:personal_fitness_os/features/history/domain/entities/timeline_event.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/screens/history_screen.dart';
import 'package:personal_fitness_os/features/progression/data/datasources/progression_remote_datasource.dart';
import 'package:personal_fitness_os/features/progression/data/repositories/progression_repository_impl.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/progression/domain/repositories/progression_repository.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/training/data/datasources/training_local_datasource.dart';
import 'package:personal_fitness_os/features/training/data/datasources/training_remote_datasource.dart';
import 'package:personal_fitness_os/features/training/data/models/set_template_model.dart';
import 'package:personal_fitness_os/features/training/data/models/training_plan_model.dart';
import 'package:personal_fitness_os/features/training/data/models/workout_exercise_model.dart';
import 'package:personal_fitness_os/features/training/data/models/workout_model.dart';
import 'package:personal_fitness_os/features/training/data/repositories/training_repository_impl.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_local_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/logged_set_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/session_exercise_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/workout_session_model.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';
import 'package:personal_fitness_os/features/workout_session/domain/services/initial_weight_estimator.dart';
import 'package:personal_fitness_os/features/workout_session/domain/services/rest_duration_resolver.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/screens/session_summary_screen.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/screens/workout_session_screen.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/finish_workout_modal.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/logged_set_row.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/session_exercise_card.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/workout_mood_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ToggleableTrainingRemote implements TrainingRemoteDataSource {
  _ToggleableTrainingRemote(this.planModel);

  final TrainingPlanModel planModel;
  bool shouldFailNetwork = false;

  @override
  Future<TrainingPlanModel?> fetchActiveTrainingPlan() async {
    if (shouldFailNetwork) throw const SocketException('Offline');
    return planModel;
  }

  @override
  Future<List<TrainingPlanModel>> fetchTrainingPlans() async {
    if (shouldFailNetwork) throw const SocketException('Offline');
    return [planModel];
  }

  @override
  Future<TrainingPlanModel> fetchTrainingPlanById(String id) async {
    if (shouldFailNetwork) throw const SocketException('Offline');
    return planModel;
  }

  @override
  Future<void> deleteWorkout(String workoutId) async {}
  @override
  Future<void> deleteWorkoutExercise(String workoutExerciseId) async {}
  @override
  Future<TrainingPlanModel> insertTrainingPlan(Map<String, dynamic> data) =>
      throw UnimplementedError();
  @override
  Future<WorkoutModel> insertWorkout(Map<String, dynamic> data) =>
      throw UnimplementedError();
  @override
  Future<WorkoutExerciseModel> insertWorkoutExercise(
          Map<String, dynamic> data) =>
      throw UnimplementedError();
  @override
  Future<void> reorderPlanWorkouts(String trainingPlanId, List<String> ids) async {}
  @override
  Future<void> reorderWorkoutExercises(String workoutId, List<String> ids) async {}
  @override
  Future<TrainingPlanModel> setActivePlan(String planId) =>
      throw UnimplementedError();
  @override
  Future<List<SetTemplateModel>> setExerciseTemplates(
          String weId, List<Map<String, dynamic>> templates) =>
      throw UnimplementedError();
  @override
  Future<void> softDeleteTrainingPlan(String planId) async {}
}

class _FailingHistoryRemote implements HistoryRemoteDataSource {
  @override
  Future<List<WorkoutSessionModel>> fetchCompletedSessions({
    int limit = 50,
    int offset = 0,
  }) async {
    throw const SocketException('Offline');
  }

  @override
  Future<List<ExerciseHistoryRecord>> fetchExerciseHistory(
    String exerciseId, {
    int limit = 30,
  }) async {
    throw const SocketException('Offline');
  }

  @override
  Future<List<WorkoutSessionModel>> fetchSessionsInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    throw const SocketException('Offline');
  }

  @override
  Future<List<TimelineEvent>> fetchUnifiedTimeline({
    HistoryEventType? type,
    DateTime? start,
    DateTime? end,
    int limit = 50,
  }) async {
    throw const SocketException('Offline');
  }
}

class _FailingProgressionRemote implements ProgressionRemoteDataSource {
  @override
  Future<ExercisePerformanceHistory?> fetchLastExercisePerformance(
    String exerciseId,
  ) async {
    throw const SocketException('Offline');
  }

  @override
  Future<List<ExercisePerformanceHistory>> fetchRecentExercisePerformances(
    String exerciseId, {
    int limit = 2,
  }) async {
    throw const SocketException('Offline');
  }
}

class _StubEmptyProgressionRepo implements ProgressionRepository {
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

class _StubRecentProgressionRepo implements ProgressionRepository {
  _StubRecentProgressionRepo(this.histories);

  final List<ExercisePerformanceHistory> histories;

  @override
  Future<Result<ExercisePerformanceHistory?, Failure>>
      getLastExercisePerformance(String exerciseId) async =>
          Success(histories.isEmpty ? null : histories.first);

  @override
  Future<Result<List<ExercisePerformanceHistory>, Failure>>
      getRecentExercisePerformances(
    String exerciseId, {
    int limit = 2,
  }) async =>
          Success(histories.take(limit).toList());
}

class _MutableSessionRepo implements SessionRepository {
  _MutableSessionRepo(this._session);

  WorkoutSession _session;
  int _nextId = 1;

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
  }) async {
    final logged = LoggedSet(
      id: existingSetId ?? 'ls-${_nextId++}',
      sessionExerciseId: sessionExerciseId,
      setNumber: setNumber,
      setType: setType,
      weightKg: weightKg,
      repsCompleted: repsCompleted,
      durationSeconds: durationSeconds,
      rirActual: rirActual,
      isWarmup: isWarmup,
      dropSets: dropSets,
    );
    _session = _session.copyWith(
      exercises: _session.exercises.map((se) {
        if (se.id != sessionExerciseId) return se;
        final updated = [...se.sets.where((s) => s.id != logged.id), logged]
          ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
        return se.copyWith(sets: updated);
      }).toList(),
    );
    return Success(logged);
  }

  @override
  Future<Result<void, Failure>> deleteLoggedSet(String setId) async {
    _session = _session.copyWith(
      exercises: _session.exercises.map((se) {
        return se.copyWith(
          sets: se.sets.where((s) => s.id != setId).toList(),
        );
      }).toList(),
    );
    return const Success(null);
  }

  @override
  Future<Result<LoggedSet, Failure>> restoreLoggedSet(LoggedSet set) async {
    _session = _session.copyWith(
      exercises: _session.exercises.map((se) {
        if (se.id != set.sessionExerciseId) return se;
        final updatedSets = [...se.sets.where((s) => s.id != set.id), set]
          ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
        return se.copyWith(sets: updatedSets);
      }).toList(),
    );
    return Success(set);
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
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<WorkoutSession, Failure>> finishSession({
    required String sessionId,
    required int durationSeconds,
    double? perceivedExertion,
    int? executionScore,
    Mood? mood,
    String? notes,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<WorkoutSession?, Failure>> getActiveSession() async =>
      Success(_session);

  @override
  Future<Result<WorkoutSession, Failure>> startSession({
    String? workoutId,
    String? workoutName,
    List<SessionExercise>? initialExercises,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<SessionExercise, Failure>> swapSessionExercise({
    required String sessionExerciseId,
    required String newExerciseId,
    String? replacedExerciseId,
  }) =>
      throw UnimplementedError();
}

class _FakeExerciseListNotifier extends ExerciseListNotifier {
  _FakeExerciseListNotifier(super.ref, List<Exercise> items) {
    state = AsyncValue.data(items);
  }

  @override
  Future<void> loadExercises() async {}
}

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget wrap(
    Widget child, {
    List<Override> overrides = const [],
    Key? scopeKey,
  }) {
    return ProviderScope(
      key: scopeKey,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: child,
      ),
    );
  }

  group('1. Offline-first caches for Training, History & Progression', () {
    test('TrainingRepositoryImpl serves cached active plan and list when offline',
        () async {
      final local = TrainingLocalDataSource(prefs, userId: 'u-1');
      final remote = _ToggleableTrainingRemote(
        const TrainingPlanModel(
          id: 'plan-1',
          userId: 'u-1',
          name: 'ABC Hiper',
          isActive: true,
          workouts: [
            WorkoutModel(
              id: 'w-1',
              trainingPlanId: 'plan-1',
              name: 'Treino A',
            ),
          ],
        ),
      );
      var offlineFlag = false;
      final repo = TrainingRepositoryImpl(
        remote,
        localDataSource: local,
        isOfflineMode: () => offlineFlag,
        onConnectivityFallback: (v) => offlineFlag = v,
      );

      // Online fetch caches plan
      final onlineRes = await repo.getActiveTrainingPlan();
      expect(onlineRes.isSuccess, isTrue);
      expect(onlineRes.fold((p) => p?.name, (_) => null), 'ABC Hiper');

      // Disconnect and return to Home/Training
      remote.shouldFailNetwork = true;
      offlineFlag = true;
      final offlineActive = await repo.getActiveTrainingPlan();
      final offlineAll = await repo.getTrainingPlans();

      expect(offlineActive.isSuccess, isTrue);
      final activePlan = offlineActive.fold((p) => p, (_) => null);
      expect(activePlan?.name, 'ABC Hiper');
      expect(activePlan?.workouts.first.name, 'Treino A');
      expect(offlineAll.fold((l) => l, (_) => null), hasLength(1));
    });

    test('HistoryRepositoryImpl & ProgressionRepositoryImpl serve local completed sessions offline',
        () async {
      final sessionLocal = SessionLocalDataSource(prefs, userId: 'u-1');
      await sessionLocal.saveSession(
        WorkoutSessionModel(
          id: 'sess-done',
          userId: 'u-1',
          workoutName: 'Peito e Tríceps',
          startedAt: DateTime(2026, 11, 22, 10, 0),
          completedAt: DateTime(2026, 11, 22, 10, 50),
          durationSeconds: 3000,
          status: 'completed',
          exercises: const [
            SessionExerciseModel(
              id: 'se-1',
              sessionId: 'sess-done',
              exerciseId: 'ex-bench',
              sets: [
                LoggedSetModel(
                  id: 'ls-1',
                  sessionExerciseId: 'se-bench',
                  setNumber: 1,
                  weightKg: 32,
                  repsCompleted: 8,
                ),
              ],
            ),
          ],
        ),
      );

      final historyRepo = HistoryRepositoryImpl(
        _FailingHistoryRemote(),
        localSessionDataSource: sessionLocal,
        isOfflineMode: () => true,
      );
      final progRepo = ProgressionRepositoryImpl(
        _FailingProgressionRemote(),
        localSessionDataSource: sessionLocal,
        isOfflineMode: () => true,
      );

      final historyRes = await historyRepo.getCompletedSessions();
      expect(historyRes.isSuccess, isTrue);
      final historyList = historyRes.fold((l) => l, (_) => const []);
      expect(historyList, hasLength(1));
      expect(historyList.first.workoutName, 'Peito e Tríceps');

      final exHistoryRes = await historyRepo.getExerciseHistory('ex-bench');
      expect(exHistoryRes.isSuccess, isTrue);
      expect(
        exHistoryRes.fold((l) => l.first.topWeightKg, (_) => null),
        32,
      );

      final progRes = await progRepo.getLastExercisePerformance('ex-bench');
      expect(progRes.isSuccess, isTrue);
      expect(progRes.fold((h) => h?.maxWeightKg, (_) => null), 32);

      // Warmup-only completed session must be skipped so it never breaks 2x streak
      await sessionLocal.saveSession(
        WorkoutSessionModel(
          id: 'sess-warmup-only',
          userId: 'u-1',
          workoutName: 'Warmup Check',
          startedAt: DateTime(2026, 11, 23, 10, 0),
          completedAt: DateTime(2026, 11, 23, 10, 20),
          durationSeconds: 1200,
          status: 'completed',
          exercises: const [
            SessionExerciseModel(
              id: 'se-wu',
              sessionId: 'sess-warmup-only',
              exerciseId: 'ex-bench',
              sets: [
                LoggedSetModel(
                  id: 'ls-wu',
                  sessionExerciseId: 'se-wu',
                  setNumber: 1,
                  setType: 'warmup',
                  isWarmup: true,
                  weightKg: 20,
                  repsCompleted: 12,
                ),
              ],
            ),
          ],
        ),
      );
      final recentRes =
          await progRepo.getRecentExercisePerformances('ex-bench', limit: 2);
      expect(recentRes.isSuccess, isTrue);
      final recent = recentRes.fold((l) => l, (_) => const []);
      expect(recent, hasLength(1));
      expect(recent.first.workoutSessionId, 'sess-done');
    });
  });

  group('2. Drop-set without white-screen crash + Undo set', () {
    testWidgets(
        'tapping Drop-set on SessionExerciseCard adds DROP-SET sub-widget without crashing, and completed sets allow + Drop-set and Desfazer',
        (tester) async {
      const bench = Exercise(
        id: 'ex-bench',
        name: 'Supino com Halteres',
        primaryMuscleGroup: 'chest',
        equipment: 'dumbbell',
        movementPattern: 'horizontal_push',
      );
      const se = SessionExercise(
        id: 'se-1',
        sessionId: 's-1',
        exerciseId: 'ex-bench',
        exercise: bench,
        targetSetsCount: 1,
        targetRepsMin: 8,
        targetRepsMax: 10,
        sets: [
          LoggedSet(
            id: 'ls-1',
            sessionExerciseId: 'se-1',
            setNumber: 1,
            weightKg: 20,
            repsCompleted: 10,
          ),
        ],
      );

      String? deletedId;
      SetType? savedType;
      List<DropSetEntry>? savedDrops;

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
                }) async {
                  savedType = setType;
                  savedDrops = dropSets;
                },
                onDeleteSet: (id) async {
                  deletedId = id;
                },
              ),
            ),
          ),
          overrides: [
            progressionRepositoryProvider
                .overrideWithValue(_StubEmptyProgressionRepo()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Completed set starts compact without inline action strip; expand to expose Desfazer and + Drop-set
      expect(find.text('Desfazer'), findsNothing);
      expect(find.text('+ Drop-set'), findsNothing);
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Série 1,')));
      await tester.pumpAndSettle();

      expect(find.text('Desfazer'), findsOneWidget);
      expect(find.text('+ Drop-set'), findsOneWidget);

      // Attach drop-set directly below the completed set
      await tester.tap(find.text('+ Drop-set'));
      await tester.pumpAndSettle();
      expect(find.text('DROP-SET'), findsOneWidget);
      expect(find.text('Salvar alteração'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Salvar alteração'));
      await tester.pumpAndSettle();
      expect(savedType, SetType.dropSet);
      expect(savedDrops, isNotEmpty);

      // Tapping footer Drop-set button adds and expands Set 2, collapsing Set 1
      await tester.tap(find.text('Drop-set'));
      await tester.pumpAndSettle();
      expect(find.byType(LoggedSetRow), findsNWidgets(2));
      expect(tester.takeException(), isNull);

      // Re-expand Set 1 to tap Desfazer and remove the completed set
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Série 1,')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desfazer'));
      await tester.pumpAndSettle();
      expect(deletedId, 'ls-1');
    });
  });

  group('3. Collapsible Rest Timer (manual & scroll-to-footer)', () {
    testWidgets(
        'minimizes to compact footer on scroll down and restores only on expand tap',
        (tester) async {
      const bench = Exercise(
        id: 'ex-1',
        name: 'Supino Reto',
        primaryMuscleGroup: 'chest',
        equipment: 'barbell',
        movementPattern: 'horizontal_push',
      );
      const squat = Exercise(
        id: 'ex-2',
        name: 'Agachamento Livre',
        primaryMuscleGroup: 'legs',
        equipment: 'barbell',
        movementPattern: 'squat',
      );
      final session = WorkoutSession(
        id: 's-timer',
        userId: 'u-1',
        workoutName: 'Full Body',
        startedAt: DateTime(2026, 11, 23, 10, 0),
        exercises: List.generate(
          6,
          (i) => SessionExercise(
            id: 'se-$i',
            sessionId: 's-timer',
            exerciseId: i.isEven ? 'ex-1' : 'ex-2',
            exercise: i.isEven ? bench : squat,
            targetSetsCount: 3,
            targetRepsMin: 6,
            targetRepsMax: 10,
          ),
        ),
      );

      final repo = _MutableSessionRepo(session);

      await tester.pumpWidget(
        wrap(
          const WorkoutSessionScreen(sessionId: 's-timer'),
          overrides: [
            sessionRepositoryProvider.overrideWithValue(repo),
            progressionRepositoryProvider
                .overrideWithValue(_StubEmptyProgressionRepo()),
            exerciseListStateProvider.overrideWith(
              (ref) => _FakeExerciseListNotifier(ref, const [bench, squat]),
            ),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Log set 1 -> starts expanded timer
      await tester.tap(find.byIcon(Icons.check_rounded).first);
      await tester.pump();
      expect(find.text('DESCANSO'), findsOneWidget);
      expect(find.bySemanticsLabel('Minimizar cronômetro para o rodapé'),
          findsOneWidget);

      // Scroll down -> timer auto-minimizes to footer
      await tester.dragFrom(const Offset(400, 180), const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(find.text('DESCANSO'), findsNothing);
      expect(find.bySemanticsLabel('Expandir cronômetro de descanso'),
          findsOneWidget);

      // Scroll back up -> stays minimized until user taps expand
      await tester.dragFrom(const Offset(400, 180), const Offset(0, 250));
      await tester.pumpAndSettle();
      expect(find.text('DESCANSO'), findsNothing);
      expect(find.bySemanticsLabel('Expandir cronômetro de descanso'),
          findsOneWidget);

      // Tap expand -> returns to full timer view
      await tester.tap(find.bySemanticsLabel('Expandir cronômetro de descanso'));
      await tester.pumpAndSettle();
      expect(find.text('DESCANSO'), findsOneWidget);

      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();
    });
  });

  group('4. Smart Rest Duration & Initial Weight Estimator & Propagation', () {
    test('RestDurationResolver gives 180s for heavy 6-10 and 120s for light 12-15',
        () {
      expect(
        RestDurationResolver.resolve(
          targetRepsMin: 6,
          targetRepsMax: 10,
          movementPattern: 'horizontal_push',
        ),
        180,
      );
      expect(
        RestDurationResolver.resolve(
          targetRepsMin: 12,
          targetRepsMax: 15,
          movementPattern: 'isolation',
          explicitTemplateRestSeconds: 180,
        ),
        120,
      );
      expect(
        RestDurationResolver.resolve(
          targetRepsMin: 8,
          targetRepsMax: 12,
          setType: SetType.warmup,
        ),
        60,
      );
      expect(
        RestDurationResolver.resolve(
          targetRepsMin: 20,
          targetRepsMax: 20,
          isCardio: true,
        ),
        0,
      );
    });

    test('InitialWeightEstimator scales realistically by experience level', () {
      const dbBench = Exercise(
        id: 'ex-db-bench',
        name: 'Supino reto com halteres',
        primaryMuscleGroup: 'chest',
        equipment: 'dumbbell',
        movementPattern: 'horizontal_push',
      );
      final beg = InitialWeightEstimator.estimate(
        exercise: dbBench,
        experience: UserExperience.beginner,
        bodyWeightKg: 78,
        biologicalSex: 'M',
      );
      final inter = InitialWeightEstimator.estimate(
        exercise: dbBench,
        experience: UserExperience.intermediate,
        bodyWeightKg: 78,
        biologicalSex: 'M',
      );
      final adv = InitialWeightEstimator.estimate(
        exercise: dbBench,
        experience: UserExperience.advanced,
        bodyWeightKg: 78,
        biologicalSex: 'M',
      );

      expect(beg.weightKg, lessThan(inter.weightKg));
      expect(inter.weightKg, lessThan(adv.weightKg));
      expect(beg.weightKg, inInclusiveRange(4.0, 10.0));
      expect(inter.weightKg, inInclusiveRange(14.0, 20.0));
      expect(adv.weightKg, inInclusiveRange(22.0, 28.0));
    });

    testWidgets(
        'SessionExerciseCard propagates logged weight and reps from Set 1 to Set 2 automatically',
        (tester) async {
      const bench = Exercise(
        id: 'ex-bench',
        name: 'Supino reto com halteres',
        primaryMuscleGroup: 'chest',
        equipment: 'dumbbell',
        movementPattern: 'horizontal_push',
      );
      final repo = _MutableSessionRepo(
        WorkoutSession(
          id: 's-prop',
          userId: 'u-1',
          workoutName: 'Peito',
          startedAt: DateTime(2026, 11, 23, 10, 0),
          exercises: const [
            SessionExercise(
              id: 'se-1',
              sessionId: 's-prop',
              exerciseId: 'ex-bench',
              exercise: bench,
              targetSetsCount: 2,
              targetRepsMin: 6,
              targetRepsMax: 10,
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        wrap(
          const WorkoutSessionScreen(sessionId: 's-prop'),
          overrides: [
            sessionRepositoryProvider.overrideWithValue(repo),
            progressionRepositoryProvider
                .overrideWithValue(_StubEmptyProgressionRepo()),
            exerciseListStateProvider.overrideWith(
              (ref) => _FakeExerciseListNotifier(ref, const [bench]),
            ),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Increase Set 1 weight once (+2.0 kg from estimated 16 -> 18) and log Set 1
      await tester.tap(find.bySemanticsLabel('Aumentar carga').first);
      await tester.pump();
      expect(find.text('18'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.check_rounded).first);
      await tester.pumpAndSettle();

      // Set 2 should now also reflect 18 kg automatically!
      expect(find.text('18'), findsNWidgets(2));

      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();
    });
  });

  group('5. Completed Workout History & Gym Mood Icons (Zero Emojis)', () {
    testWidgets(
        'HistoryScreen Treinos tab lists finished sessions and SessionSummaryScreen shows all exercises, sets and drops',
        (tester) async {
      final completedSession = WorkoutSession(
        id: 'sess-hist-1',
        userId: 'u-1',
        workoutName: 'Upper A',
        startedAt: DateTime(2026, 11, 22, 9, 0),
        completedAt: DateTime(2026, 11, 22, 9, 55),
        durationSeconds: 3300,
        status: SessionStatus.completed,
        mood: Mood.excellent,
        notes: 'Ótima técnica no supino.',
        exercises: const [
          SessionExercise(
            id: 'se-h1',
            sessionId: 'sess-hist-1',
            exerciseId: 'ex-1',
            exercise: Exercise(
              id: 'ex-1',
              name: 'Supino Reto',
              primaryMuscleGroup: 'chest',
            ),
            sets: [
              LoggedSet(
                id: 'ls-h1',
                sessionExerciseId: 'se-h1',
                setNumber: 1,
                setType: SetType.dropSet,
                weightKg: 60,
                repsCompleted: 8,
                dropSets: [DropSetEntry(weightKg: 45, repsCompleted: 5)],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(
          const HistoryScreen(),
          scopeKey: const ValueKey('history-screen'),
          overrides: [
            historyListProvider.overrideWith((_) async => [completedSession]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Treinos'));
      await tester.pumpAndSettle();
      expect(find.text('TREINOS FINALIZADOS'), findsOneWidget);
      expect(find.text('Upper A'), findsOneWidget);

      // Now verify SessionSummaryScreen details
      await tester.pumpWidget(
        wrap(
          const SessionSummaryScreen(sessionId: 'sess-hist-1'),
          scopeKey: const ValueKey('summary-screen'),
          overrides: [
            liveSessionDetailProvider('sess-hist-1')
                .overrideWith((_) async => completedSession),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EXERCÍCIOS REALIZADOS'), findsOneWidget);
      expect(find.text('Supino Reto'), findsOneWidget);
      expect(find.text('60 kg × 8 reps'), findsOneWidget);
      expect(find.text('Drop 1: 45 kg × 5 reps'), findsOneWidget);
      expect(find.text('Ótima técnica no supino.'), findsOneWidget);
      expect(find.byType(WorkoutMoodChip), findsOneWidget);
    });

    testWidgets(
        'FinishWorkoutModal displays 5 gym mood icons with color feedback and no overflow at 320x640@1.3x',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final session = WorkoutSession(
        id: 's-finish',
        userId: 'u-1',
        workoutName: 'Treino A',
        startedAt: DateTime(2026, 11, 23, 10, 0),
      );

      for (final theme in [AppTheme.dark(), AppTheme.light()]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: theme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.3),
                ),
                child: child!,
              ),
              home: Scaffold(
                body: FinishWorkoutModal(
                  session: session,
                  elapsedSeconds: 2400,
                  onFinished: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(WorkoutMoodIcon), findsNWidgets(5));
        expect(find.text('Fraco'), findsOneWidget);
        expect(find.text('Cansado'), findsOneWidget);
        expect(find.text('Normal'), findsOneWidget);
        expect(find.text('Forte'), findsOneWidget);
        expect(find.text('Muito forte'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('6. Fast Set Logging UX & 2x Ceiling Rule Summary', () {
    testWidgets(
        'SessionExerciseCard exposes Repetir última, Concluir restantes and Aplicar às restantes without overflow at 320px@1.3x',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 680));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const bench = Exercise(
        id: 'ex-bench-fast',
        name: 'Supino reto com barra',
        primaryMuscleGroup: 'chest',
        equipment: 'barbell',
        movementPattern: 'horizontal_push',
      );
      const se = SessionExercise(
        id: 'se-fast',
        sessionId: 's-fast',
        exerciseId: 'ex-bench-fast',
        exercise: bench,
        targetSetsCount: 3,
        targetRepsMin: 8,
        targetRepsMax: 10,
      );
      final loggedCalls = <({int setNumber, double weightKg, int reps})>[];

      final prevHistory = ExercisePerformanceHistory(
        exerciseId: 'ex-bench-fast',
        workoutSessionId: 'prev-1',
        date: DateTime(2026, 11, 20),
        loggedSets: const [
          LoggedSet(
            id: 'p-1',
            sessionExerciseId: 'se-p',
            setNumber: 1,
            weightKg: 60,
            repsCompleted: 10,
            rirActual: 2,
          ),
          LoggedSet(
            id: 'p-2',
            sessionExerciseId: 'se-p',
            setNumber: 2,
            weightKg: 60,
            repsCompleted: 10,
            rirActual: 2,
          ),
          LoggedSet(
            id: 'p-3',
            sessionExerciseId: 'se-p',
            setNumber: 3,
            weightKg: 60,
            repsCompleted: 10,
            rirActual: 2,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('fast-log-scope'),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            progressionRepositoryProvider.overrideWithValue(
              _StubRecentProgressionRepo([prevHistory]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: SessionExerciseCard(
                  sessionExercise: se,
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
                    restSeconds = 180,
                    dropSets = const [],
                    existingSetId,
                  }) async {
                    loggedCalls.add((
                      setNumber: setNumber,
                      weightKg: weightKg,
                      reps: repsCompleted,
                    ));
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1/2 ceiling consolidation message (since only 1 previous session hit 10 reps)
      expect(find.textContaining('Teto 1/2'), findsOneWidget);
      expect(find.text('Repetir última'), findsOneWidget);
      expect(find.text('Concluir restantes'), findsOneWidget);

      // Step weight up on set 1 -> reveals 'Aplicar às restantes'
      await tester.ensureVisible(find.bySemanticsLabel('Aumentar carga').first);
      await tester.tap(find.bySemanticsLabel('Aumentar carga').first);
      await tester.pumpAndSettle();
      expect(find.text('Aplicar às restantes'), findsOneWidget);

      await tester.ensureVisible(find.text('Aplicar às restantes'));
      await tester.tap(find.text('Aplicar às restantes'));
      await tester.pump();
      expect(find.text('62.5'), findsNWidgets(3));

      // Tap 'Repetir última' -> restores 60kg x 10 reps on all pending sets
      await tester.ensureVisible(find.text('Repetir última'));
      await tester.tap(find.text('Repetir última'));
      await tester.pump();
      expect(find.text('60'), findsNWidgets(3));

      // Expand compact Set 2 and edit inline before bulk complete -> draft must be respected
      await tester.ensureVisible(find.bySemanticsLabel(RegExp(r'^Série 2,')));
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Série 2,')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.bySemanticsLabel('Aumentar carga'));
      await tester.tap(find.bySemanticsLabel('Aumentar carga'));
      await tester.pump();
      expect(find.text('62.5'), findsOneWidget);

      // Tap 'Concluir restantes' -> logs all 3 sets preserving Set 2 draft
      await tester.ensureVisible(find.text('Concluir restantes'));
      await tester.tap(find.text('Concluir restantes'));
      await tester.pumpAndSettle();
      expect(loggedCalls.length, 3);
      expect(loggedCalls[0].weightKg, 60);
      expect(loggedCalls[1].weightKg, 62.5);
      expect(loggedCalls[2].weightKg, 60);
      expect(loggedCalls.every((c) => c.reps == 10), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'SessionSummaryScreen shows CONSOLIDAÇÃO 1/2 on first ceiling hit and SUBIR CARGA on 2nd consecutive ceiling hit',
        (tester) async {
      const bench = Exercise(
        id: 'ex-summary-prog',
        name: 'Supino Reto',
        primaryMuscleGroup: 'chest',
        equipment: 'barbell',
      );
      final currentSession = WorkoutSession(
        id: 'sess-current',
        userId: 'u-1',
        workoutName: 'Upper A',
        status: SessionStatus.completed,
        startedAt: DateTime(2026, 11, 24, 10, 0),
        completedAt: DateTime(2026, 11, 24, 10, 50),
        exercises: const [
          SessionExercise(
            id: 'se-c1',
            sessionId: 'sess-current',
            exerciseId: 'ex-summary-prog',
            exercise: bench,
            targetSetsCount: 2,
            targetRepsMin: 8,
            targetRepsMax: 10,
            sets: [
              LoggedSet(
                id: 'ls-1',
                sessionExerciseId: 'se-c1',
                setNumber: 1,
                weightKg: 70,
                repsCompleted: 10,
                rirActual: 2,
              ),
              LoggedSet(
                id: 'ls-2',
                sessionExerciseId: 'se-c1',
                setNumber: 2,
                weightKg: 70,
                repsCompleted: 10,
                rirActual: 2,
              ),
            ],
          ),
        ],
      );

      // 1/2: No previous session -> Consolidation block, NOT SUBIR CARGA
      await tester.pumpWidget(
        wrap(
          const SessionSummaryScreen(sessionId: 'sess-current'),
          scopeKey: const ValueKey('summary-1of2'),
          overrides: [
            liveSessionDetailProvider('sess-current')
                .overrideWith((_) async => currentSession),
            progressionRepositoryProvider
                .overrideWithValue(_StubRecentProgressionRepo(const [])),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONSOLIDAÇÃO 1/2'), findsOneWidget);
      expect(find.text('SUBIR CARGA'), findsNothing);

      // 2/2: Previous session also hit ceiling at 70 kg -> Unlocks SUBIR CARGA
      final prevHit = ExercisePerformanceHistory(
        exerciseId: 'ex-summary-prog',
        workoutSessionId: 'sess-prev-hit',
        date: DateTime(2026, 11, 20, 10, 0),
        loggedSets: const [
          LoggedSet(
            id: 'p-1',
            sessionExerciseId: 'se-p',
            setNumber: 1,
            weightKg: 70,
            repsCompleted: 10,
            rirActual: 2,
          ),
          LoggedSet(
            id: 'p-2',
            sessionExerciseId: 'se-p',
            setNumber: 2,
            weightKg: 70,
            repsCompleted: 10,
            rirActual: 2,
          ),
        ],
      );

      await tester.pumpWidget(
        wrap(
          const SessionSummaryScreen(sessionId: 'sess-current'),
          scopeKey: const ValueKey('summary-2of2'),
          overrides: [
            liveSessionDetailProvider('sess-current')
                .overrideWith((_) async => currentSession),
            progressionRepositoryProvider
                .overrideWithValue(_StubRecentProgressionRepo([prevHit])),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SUBIR CARGA'), findsOneWidget);
      expect(find.text('Subidas de carga desbloqueadas'), findsOneWidget);
      expect(find.text('+2,5 kg'), findsOneWidget);
    });
  });
}
