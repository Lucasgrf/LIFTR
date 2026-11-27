import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/dashboard/domain/usecases/get_dashboard_data.dart';
import 'package:personal_fitness_os/features/history/domain/repositories/history_repository.dart';
import 'package:personal_fitness_os/features/history/domain/usecases/get_workout_history.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';

class MockTrainingRepository extends Mock implements TrainingRepository {}
class MockSessionRepository extends Mock implements SessionRepository {}
class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late MockTrainingRepository mockTrainingRepo;
  late MockSessionRepository mockSessionRepo;
  late MockHistoryRepository mockHistoryRepo;

  const tWorkout = Workout(
    id: 'w-1',
    trainingPlanId: 'plan-1',
    name: 'Treino A - Peito',
    dayOfWeek: 1, // Segunda
  );

  const tPlan = TrainingPlan(
    id: 'plan-1',
    userId: 'u-1',
    name: 'Upper / Lower',
    isActive: true,
    workouts: [tWorkout],
  );

  final tSession = WorkoutSession(
    id: 'session-1',
    userId: 'u-1',
    startedAt: DateTime(2026, 8, 22, 10, 0),
    status: SessionStatus.inProgress,
  );

  setUp(() {
    mockTrainingRepo = MockTrainingRepository();
    mockSessionRepo = MockSessionRepository();
    mockHistoryRepo = MockHistoryRepository();
  });

  group('GetDashboardDataUseCase', () {
    test('should aggregate active plan, session and stats correctly', () async {
      final completedSession = tSession.copyWith(
        id: 'session-prev',
        workoutName: 'Treino Anterior',
        status: SessionStatus.completed,
        completedAt: DateTime(2026, 8, 21, 18, 0),
        durationSeconds: 2400,
      );

      when(() => mockTrainingRepo.getActiveTrainingPlan())
          .thenAnswer((_) async => const Success(tPlan));
      when(() => mockSessionRepo.getActiveSession())
          .thenAnswer((_) async => Success(tSession));
      when(() => mockHistoryRepo.getSessionsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => const Success([]));
      when(() => mockHistoryRepo.getCompletedSessions(limit: 1))
          .thenAnswer((_) async => Success([completedSession]));

      final useCase = GetDashboardDataUseCase(
        trainingRepository: mockTrainingRepo,
        sessionRepository: mockSessionRepo,
        historyRepository: mockHistoryRepo,
      );

      final result = await useCase.execute(
        referenceDate: DateTime(2026, 8, 22), // Sábado
      );

      expect(result.isSuccess, isTrue);
      final data = (result as Success).value;
      expect(data.activePlan?.id, 'plan-1');
      expect(data.activeSession?.id, 'session-1');
      expect(data.lastCompletedSession?.id, 'session-prev');
      expect(data.hasLastCompletedSession, isTrue);
      expect(data.hasActiveSession, isTrue);
      expect(data.weeklyStats.days.length, 7);
      expect(data.weeklyStats.targetWorkoutsCount, 1);
    });

    test('should propagate failure when getActiveTrainingPlan fails', () async {
      when(() => mockTrainingRepo.getActiveTrainingPlan())
          .thenAnswer((_) async => const Err(ServerFailure('DB error')));

      final useCase = GetDashboardDataUseCase(
        trainingRepository: mockTrainingRepo,
        sessionRepository: mockSessionRepo,
        historyRepository: mockHistoryRepo,
      );

      final result = await useCase.execute();
      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ServerFailure>());
    });
  });

  group('GetWorkoutHistoryUseCase', () {
    test('should fetch completed sessions from repository', () async {
      when(() => mockHistoryRepo.getCompletedSessions(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => Success([tSession]));

      final useCase = GetWorkoutHistoryUseCase(mockHistoryRepo);
      final result = await useCase.execute(limit: 20);

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.length, 1);
    });
  });
}
