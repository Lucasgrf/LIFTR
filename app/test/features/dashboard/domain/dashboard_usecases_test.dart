import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/dashboard/domain/usecases/get_dashboard_data.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_category.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';
import 'package:personal_fitness_os/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_fitness_os/features/history/domain/repositories/history_repository.dart';
import 'package:personal_fitness_os/features/history/domain/usecases/get_workout_history.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/nutrition_goal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/repositories/nutrition_repository.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';

class MockTrainingRepository extends Mock implements TrainingRepository {}
class MockSessionRepository extends Mock implements SessionRepository {}
class MockHistoryRepository extends Mock implements HistoryRepository {}
class MockNutritionRepository extends Mock implements NutritionRepository {}
class MockGoalRepository extends Mock implements GoalRepository {}

void main() {
  late MockTrainingRepository mockTrainingRepo;
  late MockSessionRepository mockSessionRepo;
  late MockHistoryRepository mockHistoryRepo;
  late MockNutritionRepository mockNutritionRepo;
  late MockGoalRepository mockGoalRepo;

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

  final tNutrition = DailyNutrition(
    id: 'dn-1',
    date: DateTime(2026, 8, 22),
    goal: const NutritionGoal(
      id: 'ng-1',
      calories: 2500,
      proteinGrams: 180,
      carbsGrams: 280,
      fatGrams: 70,
    ),
    meals: const [],
  );

  final tGoal = Goal(
    id: 'g-1',
    title: 'Chegar a 80kg',
    category: GoalCategory.weight,
    initialValue: 86.0,
    targetValue: 80.0,
    currentValue: 83.0,
    unit: 'kg',
    startedAt: DateTime(2026, 8, 1),
    status: GoalStatus.active,
  );

  setUp(() {
    mockTrainingRepo = MockTrainingRepository();
    mockSessionRepo = MockSessionRepository();
    mockHistoryRepo = MockHistoryRepository();
    mockNutritionRepo = MockNutritionRepository();
    mockGoalRepo = MockGoalRepository();
  });

  group('GetDashboardDataUseCase', () {
    test('should aggregate active plan, session, stats, nutrition and goals correctly', () async {
      when(() => mockTrainingRepo.getActiveTrainingPlan())
          .thenAnswer((_) async => const Success(tPlan));
      when(() => mockSessionRepo.getActiveSession())
          .thenAnswer((_) async => Success(tSession));
      when(() => mockHistoryRepo.getSessionsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => const Success([]));
      when(() => mockNutritionRepo.getDailyNutrition(any()))
          .thenAnswer((_) async => Success(tNutrition));
      when(() => mockGoalRepo.getGoals(status: GoalStatus.active))
          .thenAnswer((_) async => Success([tGoal]));

      final useCase = GetDashboardDataUseCase(
        trainingRepository: mockTrainingRepo,
        sessionRepository: mockSessionRepo,
        historyRepository: mockHistoryRepo,
        nutritionRepository: mockNutritionRepo,
        goalRepository: mockGoalRepo,
      );

      final result = await useCase.execute(
        referenceDate: DateTime(2026, 8, 22), // Sábado
      );

      expect(result.isSuccess, isTrue);
      final data = (result as Success).value;
      expect(data.activePlan?.id, 'plan-1');
      expect(data.activeSession?.id, 'session-1');
      expect(data.hasActiveSession, isTrue);
      expect(data.hasNutrition, isTrue);
      expect(data.hasActiveGoals, isTrue);
      expect(data.activeGoals.length, 1);
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
