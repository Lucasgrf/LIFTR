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
import 'package:personal_fitness_os/core/widgets/app_button.dart';
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
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/finish_workout_modal.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/swap_exercise_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoopProgressionRepository implements ProgressionRepository {
  @override
  Future<Result<ExercisePerformanceHistory?, Failure>>
      getLastExercisePerformance(String exerciseId) async =>
          const Success(null);

  @override
  Future<Result<List<ExercisePerformanceHistory>, Failure>>
      getRecentExercisePerformances(String exerciseId, {int limit = 2}) async =>
          const Success([]);
}

class _RecordingSessionRepository implements SessionRepository {
  final List<({String sessionId, String exerciseId, int sortOrder})>
      addedExercises = [];

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
  }) async {
    addedExercises.add((
      sessionId: sessionId,
      exerciseId: exerciseId,
      sortOrder: sortOrder,
    ));
    return Success(
      SessionExercise(
        id: 'se-added',
        sessionId: sessionId,
        exerciseId: exerciseId,
        sortOrder: sortOrder,
        targetRestSeconds: targetRestSeconds,
        targetSetsCount: targetSetsCount,
      ),
    );
  }

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
      throw UnimplementedError();

  @override
  Future<Result<WorkoutSession?, Failure>> getActiveSession() async =>
      const Success(null);

  @override
  Future<Result<WorkoutSession, Failure>> getSessionById(String id) async =>
      throw UnimplementedError();

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
      throw UnimplementedError();

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

class _FakeExerciseListNotifier extends ExerciseListNotifier {
  _FakeExerciseListNotifier(super.ref) {
    state = const AsyncValue.data([
      Exercise(
        id: 'ex-supino',
        name: 'Supino Reto',
        primaryMuscleGroup: 'Peito',
        equipment: 'barbell',
      ),
    ]);
  }

  @override
  Future<void> loadExercises() async {}
}

void main() {
  late SharedPreferences prefs;

  const benchPress = Exercise(
    id: 'ex-supino',
    name: 'Supino Reto',
    primaryMuscleGroup: 'Peito',
    equipment: 'barbell',
  );

  final fixedNow = DateTime(2026, 11, 20, 18, 30, 0);
  final startedAt = DateTime(2026, 11, 20, 18, 0, 0);

  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget wrapScreen({
    required WorkoutSession session,
    required _RecordingSessionRepository sessionRepo,
    double width = 375,
    double textScale = 1.0,
    EdgeInsets viewPadding = EdgeInsets.zero,
    Widget? home,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appClockProvider.overrideWithValue(() => fixedNow),
        isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
        liveSessionDetailProvider(session.id)
            .overrideWith((_) async => session),
        progressionRepositoryProvider
            .overrideWithValue(_NoopProgressionRepository()),
        sessionRepositoryProvider.overrideWithValue(sessionRepo),
        exerciseListStateProvider
            .overrideWith((ref) => _FakeExerciseListNotifier(ref)),
        historyListProvider.overrideWith((_) async => const []),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 812),
          padding: viewPadding,
          viewPadding: viewPadding,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: home ?? WorkoutSessionScreen(sessionId: session.id),
        ),
      ),
    );
  }

  group('UX-01 Empty session inline exercise picker', () {
    testWidgets(
        'tapping Adicionar Exercício opens SwapExerciseSheet and adds chosen exercise to session',
        (tester) async {
      final repo = _RecordingSessionRepository();
      final emptySession = WorkoutSession(
        id: 'sess-empty',
        userId: 'u-1',
        workoutId: 'w-1',
        workoutName: 'Treino Livre',
        startedAt: startedAt,
        exercises: const [],
      );

      await tester.pumpWidget(
        wrapScreen(session: emptySession, sessionRepo: repo),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final addButton = find.text('Adicionar Exercício');
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.byType(SwapExerciseSheet), findsOneWidget);
      expect(find.text('Adicionar exercício'), findsOneWidget);
      expect(find.text('Catálogo de exercícios'), findsOneWidget);
      expect(find.text('CATÁLOGO'), findsNothing);

      await tester.tap(find.text('Supino Reto'));
      await tester.pumpAndSettle();

      expect(repo.addedExercises, hasLength(1));
      expect(repo.addedExercises.single.sessionId, 'sess-empty');
      expect(repo.addedExercises.single.exerciseId, 'ex-supino');
      expect(repo.addedExercises.single.sortOrder, 0);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('UX-03 PopScope active session notice on back navigation', () {
    testWidgets(
        'popping back from WorkoutSessionScreen shows active-session SnackBar',
        (tester) async {
      final repo = _RecordingSessionRepository();
      final activeSession = WorkoutSession(
        id: 'sess-active',
        userId: 'u-1',
        workoutId: 'w-1',
        workoutName: 'Treino A',
        startedAt: startedAt,
        exercises: const [
          SessionExercise(
            id: 'se-1',
            sessionId: 'sess-active',
            exerciseId: 'ex-supino',
            exercise: benchPress,
            targetSetsCount: 1,
          ),
        ],
      );

      await tester.pumpWidget(
        wrapScreen(
          session: activeSession,
          sessionRepo: repo,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          WorkoutSessionScreen(sessionId: activeSession.id),
                    ),
                  );
                },
                child: const Text('Ir para sessão'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ir para sessão'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(WorkoutSessionScreen), findsOneWidget);

      final sessionElement = tester.element(find.byType(WorkoutSessionScreen));
      await Navigator.of(sessionElement).maybePop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Treino continua ativo. Você pode retomá-lo em "Hoje".'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('UX-06 Contextual bottom Finalizar treino CTA', () {
    testWidgets('hides bottom CTA when sets are still pending', (tester) async {
      final repo = _RecordingSessionRepository();
      final incompleteSession = WorkoutSession(
        id: 'sess-inc',
        userId: 'u-1',
        workoutId: 'w-1',
        workoutName: 'Treino A',
        startedAt: startedAt,
        exercises: const [
          SessionExercise(
            id: 'se-1',
            sessionId: 'sess-inc',
            exerciseId: 'ex-supino',
            exercise: benchPress,
            targetSetsCount: 2,
          ),
        ],
      );

      await tester.pumpWidget(
        wrapScreen(session: incompleteSession, sessionRepo: repo),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.widgetWithText(AppButton, 'Finalizar treino'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    for (final textScale in [1.0, 1.3, 2.0]) {
      testWidgets(
          'shows accessible bottom CTA when allCompleted == true at 320dp (${textScale}x) and opens FinishWorkoutModal',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 812));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final handle = tester.ensureSemantics();
        try {
          final repo = _RecordingSessionRepository();
          final completedSession = WorkoutSession(
            id: 'sess-done',
            userId: 'u-1',
            workoutId: 'w-1',
            workoutName: 'Treino A',
            startedAt: startedAt,
            exercises: const [
              SessionExercise(
                id: 'se-1',
                sessionId: 'sess-done',
                exerciseId: 'ex-supino',
                exercise: benchPress,
                targetSetsCount: 1,
                sets: [
                  LoggedSet(
                    id: 'ls-1',
                    sessionExerciseId: 'se-1',
                    setNumber: 1,
                    weightKg: 80,
                    repsCompleted: 10,
                  ),
                ],
              ),
            ],
          );

          await tester.pumpWidget(
            wrapScreen(
              session: completedSession,
              sessionRepo: repo,
              width: 320,
              textScale: textScale,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final ctaFinder = find.widgetWithText(AppButton, 'Finalizar treino');
          expect(ctaFinder, findsOneWidget);
          expect(find.text('Finalizar'), findsOneWidget);
          expect(tester.getSize(ctaFinder).height, greaterThanOrEqualTo(48.0));
          expect(tester.takeException(), isNull);

          if (textScale == 1.0) {
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );

            await tester.tap(ctaFinder);
            await tester.pumpAndSettle();

            expect(find.byType(FinishWorkoutModal), findsOneWidget);
          }
        } finally {
          handle.dispose();
        }

        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    testWidgets(
        'respects bottom viewPadding of 34dp via SafeArea on Finalizar treino bar',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _RecordingSessionRepository();
      final completedSession = WorkoutSession(
        id: 'sess-done-safe',
        userId: 'u-1',
        workoutId: 'w-1',
        workoutName: 'Treino A',
        startedAt: startedAt,
        exercises: const [
          SessionExercise(
            id: 'se-1',
            sessionId: 'sess-done-safe',
            exerciseId: 'ex-supino',
            exercise: benchPress,
            targetSetsCount: 1,
            sets: [
              LoggedSet(
                id: 'ls-1',
                sessionExerciseId: 'se-1',
                setNumber: 1,
                weightKg: 80,
                repsCompleted: 10,
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        wrapScreen(
          session: completedSession,
          sessionRepo: repo,
          width: 375,
          viewPadding: const EdgeInsets.only(bottom: 34),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final ctaFinder = find.widgetWithText(AppButton, 'Finalizar treino');
      expect(ctaFinder, findsOneWidget);
      final ctaRect = tester.getRect(ctaFinder);
      expect(ctaRect.bottom, lessThanOrEqualTo(812.0 - 34.0 - 12.0));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
