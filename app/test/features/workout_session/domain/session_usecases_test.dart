import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/abandon_workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/add_exercise_to_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/delete_logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/finish_workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/get_active_workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/get_workout_session_by_id.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/log_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/start_workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/swap_session_exercise.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late MockSessionRepository mockRepository;

  final tStartedAt = DateTime(2026, 8, 22, 10, 0);

  final tSession = WorkoutSession(
    id: 'session-1',
    userId: 'user-1',
    workoutId: 'workout-1',
    workoutName: 'Upper A',
    startedAt: tStartedAt,
    status: SessionStatus.inProgress,
  );

  const tSessionExercise = SessionExercise(
    id: 'se-1',
    sessionId: 'session-1',
    exerciseId: 'ex-1',
  );

  const tLoggedSet = LoggedSet(
    id: 'ls-1',
    sessionExerciseId: 'se-1',
    setNumber: 1,
    setType: SetType.working,
    weightKg: 80.0,
    repsCompleted: 10,
    rirActual: 1,
  );

  setUp(() {
    mockRepository = MockSessionRepository();
  });

  group('StartWorkoutSessionUseCase', () {
    test('should start a session successfully', () async {
      when(() => mockRepository.startSession(
            workoutId: any(named: 'workoutId'),
            workoutName: any(named: 'workoutName'),
            initialExercises: any(named: 'initialExercises'),
          )).thenAnswer((_) async => Success(tSession));

      final useCase = StartWorkoutSessionUseCase(mockRepository);
      final result = await useCase.execute(workoutId: 'workout-1', workoutName: 'Upper A');

      expect(result.isSuccess, isTrue);
      expect((result as Success).value, tSession);
    });
  });

  group('GetActiveWorkoutSessionUseCase', () {
    test('should return active session if any', () async {
      when(() => mockRepository.getActiveSession())
          .thenAnswer((_) async => Success(tSession));

      final useCase = GetActiveWorkoutSessionUseCase(mockRepository);
      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      expect((result as Success).value?.isInProgress, isTrue);
    });
  });

  group('GetWorkoutSessionByIdUseCase', () {
    test('should return session on valid ID', () async {
      when(() => mockRepository.getSessionById('session-1'))
          .thenAnswer((_) async => Success(tSession));

      final useCase = GetWorkoutSessionByIdUseCase(mockRepository);
      final result = await useCase.execute('session-1');

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.id, 'session-1');
    });

    test('should return ValidationFailure on empty ID', () async {
      final useCase = GetWorkoutSessionByIdUseCase(mockRepository);
      final result = await useCase.execute('   ');

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });
  });

  group('LogSetUseCase', () {
    test('should log valid set', () async {
      when(() => mockRepository.logSet(
            sessionExerciseId: 'se-1',
            setNumber: 1,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 10,
            rirActual: any(named: 'rirActual'),
            rpeActual: any(named: 'rpeActual'),
            restSecondsActual: any(named: 'restSecondsActual'),
            executionQuality: any(named: 'executionQuality'),
            isWarmup: any(named: 'isWarmup'),
            notes: any(named: 'notes'),
            dropSets: any(named: 'dropSets'),
            existingSetId: any(named: 'existingSetId'),
          )).thenAnswer((_) async => const Success(tLoggedSet));

      final useCase = LogSetUseCase(mockRepository);
      final result = await useCase.execute(
        sessionExerciseId: 'se-1',
        setNumber: 1,
        weightKg: 80.0,
        repsCompleted: 10,
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.volumeKg, 800.0);
    });

    test('should return ValidationFailure when reps is negative', () async {
      final useCase = LogSetUseCase(mockRepository);
      final result = await useCase.execute(
        sessionExerciseId: 'se-1',
        setNumber: 1,
        weightKg: 80.0,
        repsCompleted: -1,
      );

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });
  });

  group('DeleteLoggedSetUseCase', () {
    test('should delete set by ID', () async {
      when(() => mockRepository.deleteLoggedSet('ls-1'))
          .thenAnswer((_) async => const Success(null));

      final useCase = DeleteLoggedSetUseCase(mockRepository);
      final result = await useCase.execute('ls-1');

      expect(result.isSuccess, isTrue);
    });
  });

  group('AddExerciseToSessionUseCase', () {
    test('should add exercise to ongoing session', () async {
      when(() => mockRepository.addExerciseToSession(
            sessionId: 'session-1',
            exerciseId: 'ex-1',
            sortOrder: any(named: 'sortOrder'),
            notes: any(named: 'notes'),
            targetRestSeconds: any(named: 'targetRestSeconds'),
            targetSetsCount: any(named: 'targetSetsCount'),
          )).thenAnswer((_) async => const Success(tSessionExercise));

      final useCase = AddExerciseToSessionUseCase(mockRepository);
      final result = await useCase.execute(
        sessionId: 'session-1',
        exerciseId: 'ex-1',
      );

      expect(result.isSuccess, isTrue);
    });
  });

  group('FinishWorkoutSessionUseCase', () {
    test('should finish session and compute metrics', () async {
      final completedSession = tSession.copyWith(
        status: SessionStatus.completed,
        durationSeconds: 3600,
        perceivedExertion: 8.5,
        mood: Mood.good,
      );

      when(() => mockRepository.finishSession(
            sessionId: 'session-1',
            durationSeconds: 3600,
            perceivedExertion: 8.5,
            mood: Mood.good,
            notes: any(named: 'notes'),
          )).thenAnswer((_) async => Success(completedSession));

      final useCase = FinishWorkoutSessionUseCase(mockRepository);
      final result = await useCase.execute(
        sessionId: 'session-1',
        durationSeconds: 3600,
        perceivedExertion: 8.5,
        mood: Mood.good,
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.isCompleted, isTrue);
    });
  });

  group('AbandonWorkoutSessionUseCase', () {
    test('should abandon session', () async {
      when(() => mockRepository.abandonSession('session-1'))
          .thenAnswer((_) async => const Success(null));

      final useCase = AbandonWorkoutSessionUseCase(mockRepository);
      final result = await useCase.execute('session-1');

      expect(result.isSuccess, isTrue);
    });
  });

  group('SwapSessionExerciseUseCase', () {
    test('should return ValidationFailure when newExerciseId is empty', () async {
      final useCase = SwapSessionExerciseUseCase(mockRepository);
      final result = await useCase.execute(
        sessionExerciseId: 'se-1',
        newExerciseId: '  ',
      );

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });

    test('should swap exercise via repository when inputs are valid', () async {
      const swapped = SessionExercise(
        id: 'se-1',
        sessionId: 'session-1',
        exerciseId: 'ex-2',
        replacedExerciseId: 'ex-1',
      );
      when(() => mockRepository.swapSessionExercise(
            sessionExerciseId: 'se-1',
            newExerciseId: 'ex-2',
            replacedExerciseId: 'ex-1',
          )).thenAnswer((_) async => const Success(swapped));

      final useCase = SwapSessionExerciseUseCase(mockRepository);
      final result = await useCase.execute(
        sessionExerciseId: 'se-1',
        newExerciseId: 'ex-2',
        replacedExerciseId: 'ex-1',
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.exerciseId, 'ex-2');
    });
  });
}
