import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/progression/data/datasources/progression_remote_datasource.dart';
import 'package:personal_fitness_os/features/progression/data/repositories/progression_repository_impl.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/progression_recommendation.dart';
import 'package:personal_fitness_os/features/progression/domain/usecases/calculate_progression.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_remote_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/logged_set_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/repositories/session_repository_impl.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/log_set.dart';

class MockProgressionRemoteDataSource extends Mock
    implements ProgressionRemoteDataSource {}
class MockSessionRemoteDataSource extends Mock
    implements SessionRemoteDataSource {}

void main() {
  late MockProgressionRemoteDataSource mockProgressionDataSource;
  late MockSessionRemoteDataSource mockSessionDataSource;

  late ProgressionRepositoryImpl progressionRepository;
  late SessionRepositoryImpl sessionRepository;

  late CalculateProgressionUseCase calculateProgressionUseCase;
  late LogSetUseCase logSetUseCase;

  setUp(() {
    mockProgressionDataSource = MockProgressionRemoteDataSource();
    mockSessionDataSource = MockSessionRemoteDataSource();

    progressionRepository = ProgressionRepositoryImpl(mockProgressionDataSource);
    sessionRepository = SessionRepositoryImpl(mockSessionDataSource);

    calculateProgressionUseCase = CalculateProgressionUseCase(
      repository: progressionRepository,
    );
    logSetUseCase = LogSetUseCase(sessionRepository);
  });

  group('Progression Engine End-to-End Integration Flow', () {
    test('should fetch past performance, calculate overload recommendation and log next session set', () async {
      // 1. Setup past completed session performance (3 sets of 80kg x 12 reps @ RIR 2)
      final pastHistory = ExercisePerformanceHistory(
        exerciseId: 'ex-bench',
        workoutSessionId: 'ws-prev',
        workoutName: 'Upper A',
        date: DateTime(2026, 8, 15),
        loggedSets: const [
          LoggedSet(
            id: 's-1',
            sessionExerciseId: 'se-prev',
            setNumber: 1,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 12,
            rirActual: 2,
            executionQuality: ExecutionQuality.good,
          ),
          LoggedSet(
            id: 's-2',
            sessionExerciseId: 'se-prev',
            setNumber: 2,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 12,
            rirActual: 2,
            executionQuality: ExecutionQuality.good,
          ),
          LoggedSet(
            id: 's-3',
            sessionExerciseId: 'se-prev',
            setNumber: 3,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 12,
            rirActual: 2,
            executionQuality: ExecutionQuality.good,
          ),
        ],
      );

      final olderHistory = ExercisePerformanceHistory(
        exerciseId: 'ex-bench',
        workoutSessionId: 'ws-prev-0',
        workoutName: 'Upper A',
        date: DateTime(2026, 8, 11),
        loggedSets: const [
          LoggedSet(
            id: 's-01',
            sessionExerciseId: 'se-prev-0',
            setNumber: 1,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 12,
            rirActual: 2,
            executionQuality: ExecutionQuality.good,
          ),
          LoggedSet(
            id: 's-02',
            sessionExerciseId: 'se-prev-0',
            setNumber: 2,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 12,
            rirActual: 2,
            executionQuality: ExecutionQuality.good,
          ),
          LoggedSet(
            id: 's-03',
            sessionExerciseId: 'se-prev-0',
            setNumber: 3,
            setType: SetType.working,
            weightKg: 80.0,
            repsCompleted: 12,
            rirActual: 2,
            executionQuality: ExecutionQuality.good,
          ),
        ],
      );

      when(
        () => mockProgressionDataSource.fetchRecentExercisePerformances(
          'ex-bench',
          limit: 2,
        ),
      ).thenAnswer((_) async => [pastHistory, olderHistory]);

      // 2. Calculate progression recommendation for next session (Target 8-12 reps, Barbell)
      final progResult = await calculateProgressionUseCase.execute(
        exerciseId: 'ex-bench',
        targetRepsMin: 8,
        targetRepsMax: 12,
        equipment: 'barbell',
      );

      expect(progResult.isSuccess, isTrue);
      final recommendation = (progResult as Success<ProgressionRecommendation, dynamic>).value;

      expect(recommendation.type, ProgressionType.increase);
      expect(recommendation.suggestedWeightKg, 82.5);
      expect(recommendation.weightDeltaKg, 2.5);
      expect(recommendation.consecutiveCeilingHits, 2);
      expect(recommendation.rationale, contains('Meta consolidada (2/2)'));

      // 3. User begins new session and logs first set with the recommended weight (82.5kg x 10 reps)
      const tLoggedSetModel = LoggedSetModel(
        id: 'ls-new-1',
        sessionExerciseId: 'se-new',
        setNumber: 1,
        setType: 'working',
        weightKg: 82.5,
        repsCompleted: 10,
        rirActual: 2,
        isWarmup: false,
      );

      when(() => mockSessionDataSource.insertLoggedSet(any()))
          .thenAnswer((_) async => tLoggedSetModel);

      final logResult = await logSetUseCase.execute(
        sessionExerciseId: 'se-new',
        setNumber: 1,
        setType: SetType.working,
        weightKg: recommendation.suggestedWeightKg,
        repsCompleted: 10,
        rirActual: 2,
      );

      expect(logResult.isSuccess, isTrue);
      final loggedSet = (logResult as Success<LoggedSet, dynamic>).value;
      expect(loggedSet.weightKg, 82.5);
      expect(loggedSet.repsCompleted, 10);
    });
  });
}
