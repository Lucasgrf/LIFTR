import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/dashboard/domain/usecases/get_dashboard_data.dart';
import 'package:personal_fitness_os/features/history/data/datasources/history_remote_datasource.dart';
import 'package:personal_fitness_os/features/history/data/repositories/history_repository_impl.dart';
import 'package:personal_fitness_os/features/history/domain/usecases/get_workout_history.dart';
import 'package:personal_fitness_os/features/training/data/datasources/training_remote_datasource.dart';
import 'package:personal_fitness_os/features/training/data/models/training_plan_model.dart';
import 'package:personal_fitness_os/features/training/data/models/workout_model.dart';
import 'package:personal_fitness_os/features/training/data/repositories/training_repository_impl.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_remote_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/workout_session_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/repositories/session_repository_impl.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/finish_workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/usecases/start_workout_session.dart';

class MockTrainingRemoteDataSource extends Mock
    implements TrainingRemoteDataSource {}
class MockSessionRemoteDataSource extends Mock
    implements SessionRemoteDataSource {}
class MockHistoryRemoteDataSource extends Mock
    implements HistoryRemoteDataSource {}

void main() {
  late MockTrainingRemoteDataSource mockTrainingDataSource;
  late MockSessionRemoteDataSource mockSessionDataSource;
  late MockHistoryRemoteDataSource mockHistoryDataSource;

  late TrainingRepositoryImpl trainingRepository;
  late SessionRepositoryImpl sessionRepository;
  late HistoryRepositoryImpl historyRepository;

  late GetDashboardDataUseCase getDashboardDataUseCase;
  late StartWorkoutSessionUseCase startWorkoutSessionUseCase;
  late FinishWorkoutSessionUseCase finishWorkoutSessionUseCase;
  late GetWorkoutHistoryUseCase getWorkoutHistoryUseCase;

  setUp(() {
    mockTrainingDataSource = MockTrainingRemoteDataSource();
    mockSessionDataSource = MockSessionRemoteDataSource();
    mockHistoryDataSource = MockHistoryRemoteDataSource();

    trainingRepository = TrainingRepositoryImpl(mockTrainingDataSource);
    sessionRepository = SessionRepositoryImpl(mockSessionDataSource);
    historyRepository = HistoryRepositoryImpl(mockHistoryDataSource);

    getDashboardDataUseCase = GetDashboardDataUseCase(
      trainingRepository: trainingRepository,
      sessionRepository: sessionRepository,
      historyRepository: historyRepository,
    );
    startWorkoutSessionUseCase = StartWorkoutSessionUseCase(sessionRepository);
    finishWorkoutSessionUseCase = FinishWorkoutSessionUseCase(sessionRepository);
    getWorkoutHistoryUseCase = GetWorkoutHistoryUseCase(historyRepository);
  });

  group('Dashboard and History End-to-End Integration Flow', () {
    test('should load dashboard, start and complete workout and reflect in history', () async {
      final now = DateTime(2026, 8, 22, 10, 0); // Sábado (weekday 6)

      const tWorkoutModel = WorkoutModel(
        id: 'w-1',
        trainingPlanId: 'p-1',
        name: 'Treino A - Peito',
        dayOfWeek: 6, // Sábado
      );

      final tActivePlanModel = TrainingPlanModel(
        id: 'p-1',
        userId: 'u-1',
        name: 'Upper / Lower',
        isActive: true,
        workouts: const [tWorkoutModel],
      );

      final tCreatedSessionModel = WorkoutSessionModel(
        id: 'session-1',
        userId: 'u-1',
        workoutId: 'w-1',
        workoutName: 'Treino A - Peito',
        startedAt: now,
        status: 'in_progress',
      );

      final tCompletedSessionModel = tCreatedSessionModel.copyWith(
        status: 'completed',
        completedAt: now.add(const Duration(minutes: 45)),
        durationSeconds: 2700,
        perceivedExertion: 8.0,
        mood: 'good',
      );

      // 1. Fetch initial dashboard data (no active session yet)
      when(() => mockTrainingDataSource.fetchActiveTrainingPlan())
          .thenAnswer((_) async => tActivePlanModel);
      when(() => mockSessionDataSource.fetchActiveSession())
          .thenAnswer((_) async => null);
      when(() => mockHistoryDataSource.fetchSessionsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => []);

      final initialDashboardResult = await getDashboardDataUseCase.execute(referenceDate: now);
      expect(initialDashboardResult.isSuccess, isTrue);
      final dashboardData = (initialDashboardResult as Success).value;

      expect(dashboardData.hasActivePlan, isTrue);
      expect(dashboardData.hasActiveSession, isFalse);
      expect(dashboardData.todayWorkout?.name, 'Treino A - Peito');
      expect(dashboardData.weeklyStats.completedWorkoutsCount, 0);

      // 2. Start workout session
      when(() => mockSessionDataSource.insertSession(any()))
          .thenAnswer((_) async => tCreatedSessionModel);

      final startSessionResult = await startWorkoutSessionUseCase.execute(
        workoutId: dashboardData.todayWorkout!.id,
        workoutName: dashboardData.todayWorkout!.name,
      );
      expect(startSessionResult.isSuccess, isTrue);

      // 3. Complete workout session
      when(() => mockSessionDataSource.updateSession('session-1', any()))
          .thenAnswer((_) async => tCompletedSessionModel);

      final finishResult = await finishWorkoutSessionUseCase.execute(
        sessionId: 'session-1',
        durationSeconds: 2700,
        perceivedExertion: 8.0,
        mood: Mood.good,
      );
      expect(finishResult.isSuccess, isTrue);

      // 4. Verify in history
      when(() => mockHistoryDataSource.fetchCompletedSessions(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => [tCompletedSessionModel]);

      final historyResult = await getWorkoutHistoryUseCase.execute();
      expect(historyResult.isSuccess, isTrue);
      final historyList = (historyResult as Success).value;
      expect(historyList.length, 1);
      expect(historyList.first.id, 'session-1');
      expect(historyList.first.isCompleted, isTrue);
      expect(historyList.first.durationSeconds, 2700);
      expect(historyList.first.mood, Mood.good);
    });
  });
}
