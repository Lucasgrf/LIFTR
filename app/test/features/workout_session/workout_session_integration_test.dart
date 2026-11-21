import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_remote_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/logged_set_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/session_exercise_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/workout_session_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/repositories/session_repository_impl.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/add_exercise_to_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/delete_logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/finish_workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/get_active_workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/log_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/start_workout_session.dart';

class MockSessionRemoteDataSource extends Mock
    implements SessionRemoteDataSource {}

void main() {
  late MockSessionRemoteDataSource mockDataSource;
  late SessionRepositoryImpl repository;

  late StartWorkoutSessionUseCase startSessionUseCase;
  late GetActiveWorkoutSessionUseCase getActiveSessionUseCase;
  late AddExerciseToSessionUseCase addExerciseUseCase;
  late LogSetUseCase logSetUseCase;
  late DeleteLoggedSetUseCase deleteSetUseCase;
  late FinishWorkoutSessionUseCase finishSessionUseCase;

  setUp(() {
    mockDataSource = MockSessionRemoteDataSource();
    repository = SessionRepositoryImpl(mockDataSource);

    startSessionUseCase = StartWorkoutSessionUseCase(repository);
    getActiveSessionUseCase = GetActiveWorkoutSessionUseCase(repository);
    addExerciseUseCase = AddExerciseToSessionUseCase(repository);
    logSetUseCase = LogSetUseCase(repository);
    deleteSetUseCase = DeleteLoggedSetUseCase(repository);
    finishSessionUseCase = FinishWorkoutSessionUseCase(repository);
  });

  group('Workout Session End-to-End Integration Flow', () {
    test('should execute full live workout session lifecycle successfully', () async {
      final tStartedAt = DateTime(2026, 8, 22, 10, 0);

      final initialSessionModel = WorkoutSessionModel(
        id: 'session-100',
        userId: 'user-100',
        workoutId: 'workout-10',
        workoutName: 'Treino A - Peito e Tríceps',
        startedAt: tStartedAt,
        status: 'in_progress',
      );

      const addedExerciseModel = SessionExerciseModel(
        id: 'se-100',
        sessionId: 'session-100',
        exerciseId: 'ex-1',
      );

      const loggedSet1Model = LoggedSetModel(
        id: 'ls-1',
        sessionExerciseId: 'se-100',
        setNumber: 1,
        setType: 'working',
        weightKg: 80.0,
        repsCompleted: 10,
        rirActual: 2,
      );

      const loggedSet2Model = LoggedSetModel(
        id: 'ls-2',
        sessionExerciseId: 'se-100',
        setNumber: 2,
        setType: 'working',
        weightKg: 85.0,
        repsCompleted: 8,
        rirActual: 1,
      );

      final completedSessionModel = WorkoutSessionModel(
        id: 'session-100',
        userId: 'user-100',
        workoutId: 'workout-10',
        workoutName: 'Treino A - Peito e Tríceps',
        startedAt: tStartedAt,
        completedAt: tStartedAt.add(const Duration(minutes: 50)),
        durationSeconds: 3000,
        status: 'completed',
        perceivedExertion: 8.5,
        mood: 'good',
        exercises: [
          addedExerciseModel.copyWith(
            sets: [loggedSet1Model, loggedSet2Model],
          ),
        ],
      );

      // 1. Start Workout Session
      when(() => mockDataSource.insertSession(any()))
          .thenAnswer((_) async => initialSessionModel);

      final startResult = await startSessionUseCase.execute(
        workoutId: 'workout-10',
        workoutName: 'Treino A - Peito e Tríceps',
      );

      expect(startResult.isSuccess, isTrue);
      final session = (startResult as Success).value as WorkoutSession;
      expect(session.id, 'session-100');
      expect(session.isInProgress, isTrue);

      // 2. Fetch Active Session
      when(() => mockDataSource.fetchActiveSession())
          .thenAnswer((_) async => initialSessionModel);

      final activeResult = await getActiveSessionUseCase.execute();
      expect(activeResult.isSuccess, isTrue);
      expect((activeResult as Success).value?.id, 'session-100');

      // 3. Add Exercise to Session
      when(() => mockDataSource.insertSessionExercise(any()))
          .thenAnswer((_) async => addedExerciseModel);

      final addExResult = await addExerciseUseCase.execute(
        sessionId: session.id,
        exerciseId: 'ex-1',
      );
      expect(addExResult.isSuccess, isTrue);
      final sessionEx = (addExResult as Success).value as SessionExercise;
      expect(sessionEx.id, 'se-100');

      // 4. Log Set 1 (80kg x 10 = 800kg volume)
      when(() => mockDataSource.insertLoggedSet(any()))
          .thenAnswer((_) async => loggedSet1Model);

      final logSet1Result = await logSetUseCase.execute(
        sessionExerciseId: sessionEx.id,
        setNumber: 1,
        weightKg: 80.0,
        repsCompleted: 10,
        rirActual: 2,
      );
      expect(logSet1Result.isSuccess, isTrue);

      // 5. Log Set 2 (85kg x 8 = 680kg volume)
      when(() => mockDataSource.insertLoggedSet(any()))
          .thenAnswer((_) async => loggedSet2Model);

      final logSet2Result = await logSetUseCase.execute(
        sessionExerciseId: sessionEx.id,
        setNumber: 2,
        weightKg: 85.0,
        repsCompleted: 8,
        rirActual: 1,
      );
      expect(logSet2Result.isSuccess, isTrue);

      // 6. Delete a set
      when(() => mockDataSource.deleteLoggedSet('ls-1'))
          .thenAnswer((_) async => {});

      final deleteResult = await deleteSetUseCase.execute('ls-1');
      expect(deleteResult.isSuccess, isTrue);

      // 7. Finish Session
      when(() => mockDataSource.updateSession('session-100', any()))
          .thenAnswer((_) async => completedSessionModel);

      final finishResult = await finishSessionUseCase.execute(
        sessionId: 'session-100',
        durationSeconds: 3000,
        perceivedExertion: 8.5,
        mood: Mood.good,
      );

      expect(finishResult.isSuccess, isTrue);
      final completed = (finishResult as Success).value as WorkoutSession;
      expect(completed.isCompleted, isTrue);
      expect(completed.totalWorkingSetsCount, 2);
      expect(completed.totalVolumeKg, 1480.0); // 800 + 680
      expect(completed.perceivedExertion, 8.5);
      expect(completed.mood, Mood.good);
    });
  });
}
