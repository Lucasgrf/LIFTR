import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/day_adherence.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/weekly_stats.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';
import 'package:personal_fitness_os/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_fitness_os/features/history/domain/repositories/history_repository.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';
import 'package:personal_fitness_os/features/nutrition/domain/repositories/nutrition_repository.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_local_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';

class GetDashboardDataUseCase {
  const GetDashboardDataUseCase({
    required TrainingRepository trainingRepository,
    required SessionRepository sessionRepository,
    required HistoryRepository historyRepository,
    NutritionRepository? nutritionRepository,
    GoalRepository? goalRepository,
    SessionLocalDataSource? localSessionDataSource,
  })  : _trainingRepository = trainingRepository,
        _sessionRepository = sessionRepository,
        _historyRepository = historyRepository,
        _nutritionRepository = nutritionRepository,
        _goalRepository = goalRepository,
        _localSessionDataSource = localSessionDataSource;

  final TrainingRepository _trainingRepository;
  final SessionRepository _sessionRepository;
  final HistoryRepository _historyRepository;
  final NutritionRepository? _nutritionRepository;
  final GoalRepository? _goalRepository;
  final SessionLocalDataSource? _localSessionDataSource;

  Future<Result<DashboardData, Failure>> execute({DateTime? referenceDate}) async {
    final now = referenceDate ?? DateTime.now();

    // 1. Fetch Active Plan
    final planResult = await _trainingRepository.getActiveTrainingPlan();
    if (planResult is Err<TrainingPlan?, Failure>) {
      return Err(planResult.failure);
    }
    final activePlan = (planResult as Success<TrainingPlan?, Failure>).value;

    // 2. Fetch Active Session
    final sessionResult = await _sessionRepository.getActiveSession();
    if (sessionResult is Err<WorkoutSession?, Failure>) {
      return Err(sessionResult.failure);
    }
    final activeSession = (sessionResult as Success<WorkoutSession?, Failure>).value;

    // 3. Determine Today's Workout
    Workout? todayWorkout;
    if (activePlan != null && activePlan.workouts.isNotEmpty) {
      final currentDayOfWeek = now.weekday % 7; // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
      todayWorkout = activePlan.workouts.where((w) => w.dayOfWeek == currentDayOfWeek).firstOrNull ??
          activePlan.workouts.first;
    }

    // 4. Calculate Weekly Window (Sunday to Saturday)
    final currentWeekday = now.weekday % 7; // 0 for Sun ... 6 for Sat
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: currentWeekday));
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999, microseconds: 999),
    );

    final historyResult = await _historyRepository.getSessionsInRange(
      start: startOfWeek,
      end: endOfWeek,
    );
    List<WorkoutSession> weeklySessions;
    if (historyResult is Err<List<WorkoutSession>, Failure>) {
      if (_localSessionDataSource == null) {
        return Err(historyResult.failure);
      }
      weeklySessions = _localSessionDataSource
          .getAllCachedSessions()
          .map((m) => m.toDomain())
          .where((s) {
        if (!s.isCompleted) return false;
        final d = s.completedAt ?? s.startedAt;
        return !d.isBefore(startOfWeek) && !d.isAfter(endOfWeek);
      }).toList();
    } else {
      weeklySessions = (historyResult as Success<List<WorkoutSession>, Failure>).value;
    }

    // 4b. Determine Last Completed Session (remote + offline local fallback)
    WorkoutSession? lastCompletedSession;
    try {
      final latestResult = await _historyRepository.getCompletedSessions(limit: 1);
      if (latestResult is Success<List<WorkoutSession>, Failure> &&
          latestResult.value.isNotEmpty) {
        lastCompletedSession = latestResult.value.first;
      }
    } catch (_) {}

    if (lastCompletedSession == null && weeklySessions.isNotEmpty) {
      final sorted = [...weeklySessions]
        ..sort((a, b) {
          final aDate = a.completedAt ?? a.startedAt;
          final bDate = b.completedAt ?? b.startedAt;
          return bDate.compareTo(aDate);
        });
      lastCompletedSession = sorted.first;
    }

    final localCompleted =
        _localSessionDataSource?.getLastCompletedSession()?.toDomain();
    if (localCompleted != null) {
      if (lastCompletedSession == null) {
        lastCompletedSession = localCompleted;
      } else {
        final localDate = localCompleted.completedAt ?? localCompleted.startedAt;
        final remoteDate =
            lastCompletedSession.completedAt ?? lastCompletedSession.startedAt;
        if (localDate.isAfter(remoteDate)) {
          lastCompletedSession = localCompleted;
        }
      }
    }

    // 5. Build 7-day Adherence List
    final days = List.generate(7, (i) {
      final dayDate = startOfWeek.add(Duration(days: i));
      final hasCompleted = weeklySessions.any((s) {
        final completedDate = s.completedAt ?? s.startedAt;
        return completedDate.year == dayDate.year &&
            completedDate.month == dayDate.month &&
            completedDate.day == dayDate.day;
      });
      final isToday = dayDate.year == now.year &&
          dayDate.month == now.month &&
          dayDate.day == now.day;

      return DayAdherence(
        date: dayDate,
        dayOfWeek: i,
        hasCompletedWorkout: hasCompleted,
        isToday: isToday,
      );
    });

    final totalVolume =
        weeklySessions.fold(0.0, (sum, s) => sum + s.totalVolumeKg);
    final totalDurationSeconds =
        weeklySessions.fold(0, (sum, s) => sum + s.durationSeconds);
    final totalMinutes = totalDurationSeconds ~/ 60;

    final weeklyStats = WeeklyStats(
      completedWorkoutsCount: weeklySessions.length,
      targetWorkoutsCount: activePlan?.workouts.length ?? 4,
      totalVolumeKg: totalVolume,
      totalDurationMinutes: totalMinutes,
      days: days,
    );

    // 6. Fetch Today's Nutrition (if repository configured)
    DailyNutrition? todayNutrition;
    if (_nutritionRepository != null) {
      final nutResult = await _nutritionRepository.getDailyNutrition(now);
      if (nutResult is Success<DailyNutrition, Failure>) {
        todayNutrition = nutResult.value;
      }
    }

    // 7. Fetch Active Goals (if repository configured)
    List<Goal> activeGoals = const [];
    if (_goalRepository != null) {
      final goalResult = await _goalRepository.getGoals(status: GoalStatus.active);
      if (goalResult is Success<List<Goal>, Failure>) {
        activeGoals = goalResult.value;
      }
    }

    return Success(
      DashboardData(
        activePlan: activePlan,
        activeSession: activeSession,
        todayWorkout: todayWorkout,
        lastCompletedSession: lastCompletedSession,
        weeklyStats: weeklyStats,
        todayNutrition: todayNutrition,
        activeGoals: activeGoals,
      ),
    );
  }
}
