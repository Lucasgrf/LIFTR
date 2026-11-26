import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/providers/exercise_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/progression/domain/repositories/progression_repository.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/screens/workout_session_screen.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/logged_set_row.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/session_exercise_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EmptyProgressionRepo implements ProgressionRepository {
  @override
  Future<Result<ExercisePerformanceHistory?, Failure>>
      getLastExercisePerformance(String exerciseId) async =>
          const Success(null);

  @override
  Future<Result<List<ExercisePerformanceHistory>, Failure>>
      getRecentExercisePerformances(String exerciseId, {int limit = 2}) async =>
          const Success([]);
}

class _FakeSessionRepo implements SessionRepository {
  _FakeSessionRepo(this.session);

  WorkoutSession session;
  final List<({String? existingSetId, int setNumber, double weightKg, int reps})>
      loggedCalls = [];
  final List<String> deletedIds = [];
  final List<LoggedSet> restoredSets = [];

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
      throw UnimplementedError();

  @override
  Future<Result<void, Failure>> deleteLoggedSet(String setId) async {
    deletedIds.add(setId);
    final updatedExercises = session.exercises.map((se) {
      return se.copyWith(
        sets: se.sets.where((s) => s.id != setId).toList(),
      );
    }).toList();
    session = session.copyWith(exercises: updatedExercises);
    return const Success(null);
  }

  @override
  Future<Result<LoggedSet, Failure>> restoreLoggedSet(LoggedSet set) async {
    restoredSets.add(set);
    final updatedExercises = session.exercises.map((se) {
      if (se.id != set.sessionExerciseId) return se;
      final nextSets = [...se.sets.where((s) => s.id != set.id), set]
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
      return se.copyWith(sets: nextSets);
    }).toList();
    session = session.copyWith(exercises: updatedExercises);
    return Success(set);
  }

  @override
  Future<Result<WorkoutSession, Failure>> finishSession({
    required String sessionId,
    required int durationSeconds,
    double? perceivedExertion,
    int? executionScore,
    Mood? mood,
    String? notes,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<WorkoutSession?, Failure>> getActiveSession() async =>
      Success(session);

  @override
  Future<Result<WorkoutSession, Failure>> getSessionById(String id) async =>
      Success(session);

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
    loggedCalls.add((
      existingSetId: existingSetId,
      setNumber: setNumber,
      weightKg: weightKg,
      reps: repsCompleted,
    ));
    final newSet = LoggedSet(
      id: existingSetId ?? 'ls-$setNumber-new',
      sessionExerciseId: sessionExerciseId,
      setNumber: setNumber,
      setType: setType,
      weightKg: weightKg,
      repsCompleted: repsCompleted,
      durationSeconds: durationSeconds,
      rirActual: rirActual,
      dropSets: dropSets,
    );
    final updatedExercises = session.exercises.map((se) {
      if (se.id != sessionExerciseId) return se;
      final remaining = se.sets.where((s) => s.setNumber != setNumber).toList()
        ..add(newSet)
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
      return se.copyWith(sets: remaining);
    }).toList();
    session = session.copyWith(exercises: updatedExercises);
    return Success(newSet);
  }

  @override
  Future<Result<WorkoutSession, Failure>> startSession({
    String? workoutId,
    String? workoutName,
    List<SessionExercise>? initialExercises,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<SessionExercise, Failure>> swapSessionExercise({
    required String sessionExerciseId,
    required String newExerciseId,
    String? replacedExerciseId,
  }) async =>
      throw UnimplementedError();
}

class _FakeExercisesNotifier extends ExerciseListNotifier {
  _FakeExercisesNotifier(super.ref) {
    state = const AsyncValue.data([
      Exercise(
        id: 'ex-squat',
        name: 'Agachamento Livre',
        primaryMuscleGroup: 'quads',
        equipment: 'barbell',
      ),
    ]);
  }

  @override
  Future<void> loadExercises() async {}
}

void main() {
  late SharedPreferences prefs;

  const tSquat = Exercise(
    id: 'ex-squat',
    name: 'Agachamento Livre',
    primaryMuscleGroup: 'quads',
    equipment: 'barbell',
  );

  const tCardio = Exercise(
    id: 'ex-cardio',
    name: 'Esteira',
    primaryMuscleGroup: 'cardio',
    equipment: 'machine',
  );

  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget wrapCard({
    required SessionExercise se,
    required Future<void> Function({
      required String sessionExerciseId,
      required int setNumber,
      required SetType setType,
      required double weightKg,
      required int repsCompleted,
      int? durationSeconds,
      int? rirActual,
      int restSeconds,
      List<DropSetEntry> dropSets,
      String? existingSetId,
    }) onLogSet,
    double viewportHeight = 900,
    double width = 375,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        progressionRepositoryProvider.overrideWithValue(_EmptyProgressionRepo()),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, viewportHeight),
          disableAnimations: true,
        ),
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SessionExerciseCard(
                sessionExercise: se,
                showRir: false,
                onLogSet: onLogSet,
                onDeleteSet: (_) async {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Session set density-by-state & transitions', () {
    testWidgets(
        'actions strip is hidden on compact completed row, shows on expand, hides on collapse and auto-saves unsaved edits',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final logCalls =
          <({int setNumber, double weightKg, String? existingSetId})>[];
      const se = SessionExercise(
        id: 'se-1',
        sessionId: 'sess-1',
        exerciseId: 'ex-squat',
        exercise: tSquat,
        targetSetsCount: 3,
        sets: [
          LoggedSet(
            id: 'ls-1',
            sessionExerciseId: 'se-1',
            setNumber: 1,
            weightKg: 80.0,
            repsCompleted: 10,
          ),
        ],
      );

      await tester.pumpWidget(
        wrapCard(
          se: se,
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
            logCalls.add((
              setNumber: setNumber,
              weightKg: weightKg,
              existingSetId: existingSetId,
            ));
          },
        ),
      );
      await tester.pumpAndSettle();

      // Column headers stay visible even on 375dp when compact rows are present
      expect(find.text('SÉR.'), findsOneWidget);
      expect(find.text('KG'), findsOneWidget);
      expect(find.text('REPS'), findsOneWidget);

      // Set 1 completed is compact: actions strip is hidden, Set 2 (first pending) is active
      expect(find.text('+ Drop-set'), findsNothing);
      expect(find.text('Desfazer'), findsNothing);
      expect(find.bySemanticsLabel('Aumentar carga'), findsOneWidget);

      // Expand Set 1
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Série 1,')));
      await tester.pumpAndSettle();
      expect(find.text('+ Drop-set'), findsOneWidget);
      expect(find.text('Desfazer'), findsOneWidget);

      // Edit Set 1 weight (80 -> 82.5) without tapping Salvar alteração
      await tester.tap(find.bySemanticsLabel('Aumentar carga'));
      await tester.pump();
      expect(find.text('Salvar alteração'), findsOneWidget);
      expect(logCalls, isEmpty);

      // Expanding Set 3 collapses Set 1 and must auto-save Set 1's edit
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Série 3,')));
      await tester.pumpAndSettle();
      expect(logCalls, hasLength(1));
      expect(logCalls.single.setNumber, 1);
      expect(logCalls.single.weightKg, 82.5);
      expect(logCalls.single.existingSetId, 'ls-1');
      expect(find.text('+ Drop-set'), findsNothing);

      // Tapping outside (exercise title) collapses Set 3 back to first pending (Set 2)
      await tester.tap(find.text('Agachamento Livre'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp(r'^Série 2,')), findsNothing);
      expect(find.bySemanticsLabel(RegExp(r'^Série 3,')), findsOneWidget);

      // Re-expand Set 1, edit again, tap outside -> auto-saves again
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Série 1,')));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Aumentar carga'));
      await tester.pump();
      await tester.tap(find.text('Agachamento Livre'));
      await tester.pumpAndSettle();
      expect(logCalls, hasLength(2));
      expect(logCalls.last.weightKg, 85.0);
    });

    testWidgets(
        'completing active set expands next pending set, moves Focus and keeps tapped row visible inside constrained scroll',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 420));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var currentSe = const SessionExercise(
        id: 'se-2',
        sessionId: 'sess-1',
        exerciseId: 'ex-squat',
        exercise: tSquat,
        targetSetsCount: 4,
        sets: [],
      );

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setHostState) {
            return wrapCard(
              viewportHeight: 420,
              se: currentSe,
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
                setHostState(() {
                  currentSe = currentSe.copyWith(
                    sets: [
                      ...currentSe.sets,
                      LoggedSet(
                        id: 'ls-$setNumber',
                        sessionExerciseId: sessionExerciseId,
                        setNumber: setNumber,
                        setType: setType,
                        weightKg: weightKg,
                        repsCompleted: repsCompleted,
                      ),
                    ],
                  );
                });
              },
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Complete Set 1 (active)
      await tester.tap(
        find.bySemanticsLabel('Marcar série 1 como concluída'),
      );
      await tester.pumpAndSettle();

      // Set 2 should now be expanded and hold primaryFocus
      final set2Finder = find.byType(LoggedSetRow).at(1);
      final set2Widget = tester.widget<LoggedSetRow>(set2Finder);
      expect(set2Widget.isExpanded, isTrue);
      expect(set2Widget.focusNode?.hasFocus, isTrue);

      // Scroll-safety: manually expand Set 4 near bottom edge and ensure it stays within viewport [0, 420]
      await tester.ensureVisible(find.bySemanticsLabel(RegExp(r'^Série 4,')));
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Série 4,')));
      await tester.pumpAndSettle();

      final set4Rect = tester.getRect(find.byType(LoggedSetRow).at(3));
      expect(set4Rect.top, greaterThanOrEqualTo(0.0));
      expect(set4Rect.bottom, lessThanOrEqualTo(420.0));
    });

    testWidgets('cardio keeps existing expanded layout untouched',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const seCardio = SessionExercise(
        id: 'se-cardio',
        sessionId: 'sess-1',
        exerciseId: 'ex-cardio',
        exercise: tCardio,
        targetSetsCount: 2,
        targetRepsMin: 20,
        targetRepsMax: 20,
      );

      await tester.pumpWidget(
        wrapCard(
          se: seCardio,
          onLogSet: ({
            required sessionExerciseId,
            required setNumber,
            required setType,
            required weightKg,
            required repsCompleted,
            durationSeconds,
            rirActual,
            restSeconds = 0,
            dropSets = const [],
            existingSetId,
          }) async {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BL.'), findsOneWidget);
      expect(find.bySemanticsLabel('Aumentar tempo de cardio'), findsNWidgets(2));
    });

    testWidgets(
        'unmarking completed drop-set via compact check shows SnackBar and Undo restores exact LoggedSet without timer or logSet call',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final originalCompletedAt = DateTime(2026, 11, 20, 18, 12, 45);
      final initialSession = WorkoutSession(
        id: 'sess-undo',
        userId: 'u-1',
        workoutId: 'w-1',
        workoutName: 'Treino A',
        startedAt: DateTime(2026, 11, 20, 18, 0),
        exercises: [
          SessionExercise(
            id: 'se-1',
            sessionId: 'sess-undo',
            exerciseId: 'ex-squat',
            exercise: tSquat,
            targetSetsCount: 2,
            sets: [
              LoggedSet(
                id: 'ls-1',
                sessionExerciseId: 'se-1',
                setNumber: 1,
                setType: SetType.dropSet,
                weightKg: 90.0,
                repsCompleted: 8,
                rirActual: 1,
                rpeActual: 8.5,
                dropSets: const [
                  DropSetEntry(weightKg: 60.0, repsCompleted: 10),
                ],
                completedAt: originalCompletedAt,
              ),
            ],
          ),
        ],
      );
      final fakeRepo = _FakeSessionRepo(initialSession);
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appClockProvider.overrideWithValue(
              () => DateTime(2026, 11, 20, 18, 30),
            ),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
            liveSessionDetailProvider('sess-undo')
                .overrideWith((_) => fakeRepo.session),
            progressionRepositoryProvider
                .overrideWithValue(_EmptyProgressionRepo()),
            sessionRepositoryProvider.overrideWithValue(fakeRepo),
            exerciseListStateProvider
                .overrideWith((ref) => _FakeExercisesNotifier(ref)),
            historyListProvider.overrideWith((_) async => const []),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return MaterialApp(
                theme: AppTheme.dark(),
                home: const WorkoutSessionScreen(sessionId: 'sess-undo'),
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Tap compact check button of Set 1
      await tester.tap(find.bySemanticsLabel('Desmarcar série 1'));
      await tester.pumpAndSettle();

      expect(fakeRepo.deletedIds, ['ls-1']);
      expect(find.text('Série 1 desmarcada'), findsOneWidget);
      expect(find.text('Desfazer'), findsOneWidget);

      // Tap Desfazer action on SnackBar -> restores exact original set without logSet or timer
      await tester.tap(find.text('Desfazer'));
      await tester.pumpAndSettle();

      expect(fakeRepo.loggedCalls, isEmpty);
      expect(fakeRepo.restoredSets, hasLength(1));
      final restored = fakeRepo.restoredSets.single;
      expect(restored.id, 'ls-1');
      expect(restored.completedAt, originalCompletedAt);
      expect(restored.rpeActual, 8.5);
      expect(restored.rirActual, 1);
      expect(restored.setType, SetType.dropSet);
      expect(
        restored.dropSets,
        const [DropSetEntry(weightKg: 60.0, repsCompleted: 10)],
      );
      final timerState = container.read(restTimerNotifierProvider);
      expect(timerState.isVisible, isFalse);
      expect(timerState.status, RestTimerStatus.idle);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
