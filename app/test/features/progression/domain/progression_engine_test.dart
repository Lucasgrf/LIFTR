import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/progression_recommendation.dart';
import 'package:personal_fitness_os/features/progression/domain/repositories/progression_repository.dart';
import 'package:personal_fitness_os/features/progression/domain/services/progression_engine.dart';
import 'package:personal_fitness_os/features/progression/domain/usecases/calculate_progression.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';

class MockProgressionRepository extends Mock implements ProgressionRepository {}

void main() {
  const engine = ProgressionEngine();
  late MockProgressionRepository mockRepo;
  late CalculateProgressionUseCase useCase;

  setUp(() {
    mockRepo = MockProgressionRepository();
    useCase = CalculateProgressionUseCase(repository: mockRepo, engine: engine);
  });

  group('ProgressionEngine - evaluate', () {
    test('should recommend INCREASE when all working sets reach max reps with good form', () {
      final history = ExercisePerformanceHistory(
        exerciseId: 'ex-1',
        workoutSessionId: 'ws-1',
        date: DateTime(2026, 8, 20),
        loggedSets: const [
          LoggedSet(
            id: 's-1',
            sessionExerciseId: 'se-1',
            setNumber: 1,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 12,
            rirActual: 2,
            executionQuality: ExecutionQuality.good,
          ),
          LoggedSet(
            id: 's-2',
            sessionExerciseId: 'se-1',
            setNumber: 2,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 12,
            rirActual: 2,
            executionQuality: ExecutionQuality.good,
          ),
          LoggedSet(
            id: 's-3',
            sessionExerciseId: 'se-1',
            setNumber: 3,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 12,
            rirActual: 1,
            executionQuality: ExecutionQuality.good,
          ),
        ],
      );

      final rec = engine.evaluate(
        history: history,
        targetRepsMin: 8,
        targetRepsMax: 12,
        equipment: 'barbell',
      );

      expect(rec.type, ProgressionType.increase);
      expect(rec.isIncrease, isTrue);
      expect(rec.suggestedWeightKg, 82.5);
      expect(rec.weightDeltaKg, 2.5);
      expect(rec.rationale, contains('Meta atingida'));
    });

    test('should recommend MAINTAIN when max reps hit but execution quality is poor', () {
      final history = ExercisePerformanceHistory(
        exerciseId: 'ex-1',
        workoutSessionId: 'ws-1',
        date: DateTime(2026, 8, 20),
        loggedSets: const [
          LoggedSet(
            id: 's-1',
            sessionExerciseId: 'se-1',
            setNumber: 1,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 12,
            rirActual: 2,
            executionQuality: ExecutionQuality.good,
          ),
          LoggedSet(
            id: 's-2',
            sessionExerciseId: 'se-1',
            setNumber: 2,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 12,
            rirActual: 0,
            executionQuality: ExecutionQuality.poor,
          ),
        ],
      );

      final rec = engine.evaluate(
        history: history,
        targetRepsMin: 8,
        targetRepsMax: 12,
        equipment: 'barbell',
      );

      expect(rec.type, ProgressionType.maintain);
      expect(rec.suggestedWeightKg, 80.0);
      expect(rec.rationale, contains('execução técnica precisa melhorar'));
    });

    test('should recommend MAINTAIN when reps are inside the range (e.g. 10 reps in 8-12 target)', () {
      final history = ExercisePerformanceHistory(
        exerciseId: 'ex-1',
        workoutSessionId: 'ws-1',
        date: DateTime(2026, 8, 20),
        loggedSets: const [
          LoggedSet(
            id: 's-1',
            sessionExerciseId: 'se-1',
            setNumber: 1,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 10,
            rirActual: 2,
            executionQuality: ExecutionQuality.good,
          ),
          LoggedSet(
            id: 's-2',
            sessionExerciseId: 'se-1',
            setNumber: 2,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 9,
            rirActual: 2,
            executionQuality: ExecutionQuality.good,
          ),
        ],
      );

      final rec = engine.evaluate(
        history: history,
        targetRepsMin: 8,
        targetRepsMax: 12,
      );

      expect(rec.type, ProgressionType.maintain);
      expect(rec.suggestedWeightKg, 80.0);
      expect(rec.rationale, contains('Dentro da faixa alvo'));
    });

    test('should recommend DECREASE when multiple sets fall below min reps', () {
      final history = ExercisePerformanceHistory(
        exerciseId: 'ex-1',
        workoutSessionId: 'ws-1',
        date: DateTime(2026, 8, 20),
        loggedSets: const [
          LoggedSet(
            id: 's-1',
            sessionExerciseId: 'se-1',
            setNumber: 1,
            setType: SetType.working,
            weightKg: 100.0,
            repsCompleted: 5, // below 8
            rirActual: 0,
            executionQuality: ExecutionQuality.poor,
          ),
          LoggedSet(
            id: 's-2',
            sessionExerciseId: 'se-1',
            setNumber: 2,
            setType: SetType.working,
            weightKg: 100.0,
            repsCompleted: 4, // below 8
            rirActual: 0,
            executionQuality: ExecutionQuality.poor,
          ),
        ],
      );

      final rec = engine.evaluate(
        history: history,
        targetRepsMin: 8,
        targetRepsMax: 12,
      );

      expect(rec.type, ProgressionType.decrease);
      expect(rec.isDecrease, isTrue);
      expect(rec.suggestedWeightKg, lessThan(100.0));
      expect(rec.rationale, contains('Reduza para'));
    });

    test('should return maintain when history has only warmup/non-working sets', () {
      final history = ExercisePerformanceHistory(
        exerciseId: 'ex-1',
        workoutSessionId: 'ws-1',
        date: DateTime(2026, 8, 20),
        loggedSets: const [
          LoggedSet(
            id: 's-warmup',
            sessionExerciseId: 'se-1',
            setNumber: 1,
            setType: SetType.warmup,
            weightKg: 40.0,
            repsCompleted: 15,
            isWarmup: true,
          ),
        ],
      );

      final rec = engine.evaluate(
        history: history,
        targetRepsMin: 8,
        targetRepsMax: 12,
      );

      expect(rec.type, ProgressionType.maintain);
      expect(rec.suggestedWeightKg, 0.0);
    });

    test('should NOT recommend increase when mixed RIR [0, 1] does not meet targetRir 2 threshold', () {
      final history = ExercisePerformanceHistory(
        exerciseId: 'ex-1',
        workoutSessionId: 'ws-1',
        date: DateTime(2026, 8, 20),
        loggedSets: const [
          LoggedSet(
            id: 's-1',
            sessionExerciseId: 'se-1',
            setNumber: 1,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 12,
            rirActual: 0, // RIR 0 does not meet threshold (2 - 1 = 1)
            executionQuality: ExecutionQuality.good,
          ),
          LoggedSet(
            id: 's-2',
            sessionExerciseId: 'se-1',
            setNumber: 2,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 12,
            rirActual: 1,
            executionQuality: ExecutionQuality.good,
          ),
        ],
      );

      final rec = engine.evaluate(
        history: history,
        targetRepsMin: 8,
        targetRepsMax: 12,
        targetRir: 2,
      );

      expect(rec.type, ProgressionType.maintain);
      expect(rec.suggestedWeightKg, 80.0);
    });

    test('should use appropriate equipment increments', () {
      expect(ProgressionEngine.defaultWeightIncrement('barbell'), 2.5);
      expect(ProgressionEngine.defaultWeightIncrement('dumbbell'), 2.0);
      expect(ProgressionEngine.defaultWeightIncrement('machine'), 2.5);
      expect(ProgressionEngine.defaultWeightIncrement('bodyweight'), 1.0);
    });
  });

  group('CalculateProgressionUseCase', () {
    test('should return default start recommendation when history is null', () async {
      when(() => mockRepo.getLastExercisePerformance('ex-new'))
          .thenAnswer((_) async => const Success(null));

      final result = await useCase.execute(
        exerciseId: 'ex-new',
        targetRepsMin: 8,
        targetRepsMax: 12,
      );

      expect(result.isSuccess, isTrue);
      final rec = (result as Success<ProgressionRecommendation, Failure>).value;
      expect(rec.type, ProgressionType.maintain);
      expect(rec.rationale, contains('Primeira vez executando este exercício'));
    });

    test('should propagate failure when repository fails', () async {
      when(() => mockRepo.getLastExercisePerformance('ex-err'))
          .thenAnswer((_) async => const Err(ServerFailure('Query error')));

      final result = await useCase.execute(
        exerciseId: 'ex-err',
        targetRepsMin: 8,
        targetRepsMax: 12,
      );

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ServerFailure>());
    });
  });
}
