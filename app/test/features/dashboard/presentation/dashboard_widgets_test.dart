import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/day_adherence.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/weekly_stats.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/dashboard_active_goals_card.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/dashboard_nutrition_card.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/dashboard_stats_grid.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/today_workout_banner.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/weekly_streak_widget.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_category.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/nutrition_goal.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });
  final tWeeklyStats = WeeklyStats(
    completedWorkoutsCount: 3,
    targetWorkoutsCount: 4,
    totalVolumeKg: 12500.0,
    totalDurationMinutes: 180,
    days: [
      DayAdherence(date: DateTime(2026, 8, 16), dayOfWeek: 0, hasCompletedWorkout: true),
      DayAdherence(date: DateTime(2026, 8, 17), dayOfWeek: 1, hasCompletedWorkout: true),
      DayAdherence(date: DateTime(2026, 8, 18), dayOfWeek: 2, hasCompletedWorkout: false),
      DayAdherence(date: DateTime(2026, 8, 19), dayOfWeek: 3, hasCompletedWorkout: true),
      DayAdherence(date: DateTime(2026, 8, 20), dayOfWeek: 4, hasCompletedWorkout: false),
      DayAdherence(date: DateTime(2026, 8, 21), dayOfWeek: 5, hasCompletedWorkout: false),
      DayAdherence(date: DateTime(2026, 8, 22), dayOfWeek: 6, isToday: true),
    ],
  );

  const tWorkout = Workout(
    id: 'w-1',
    trainingPlanId: 'p-1',
    name: 'Treino A - Peito e Tríceps',
    dayOfWeek: 6,
  );

  final tSession = WorkoutSession(
    id: 's-1',
    userId: 'u-1',
    workoutName: 'Treino A - Peito e Tríceps',
    startedAt: DateTime(2026, 8, 22, 10, 0),
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
  );

  Widget createWidgetUnderTest(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('TodayWorkoutBanner Widget Test', () {
    testWidgets('should render active session banner when ongoing session exists', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          TodayWorkoutBanner(
            activeSession: tSession,
            onStartWorkout: (_) async {},
          ),
        ),
      );

      expect(find.text('EM ANDAMENTO'), findsOneWidget);
      expect(find.text('Treino A - Peito e Tríceps'), findsOneWidget);
      expect(find.text('Continuar Treino'), findsOneWidget);
    });

    testWidgets('should render today workout banner when scheduled workout exists', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          TodayWorkoutBanner(
            todayWorkout: tWorkout,
            onStartWorkout: (_) async {},
          ),
        ),
      );

      expect(find.text('TREINO DE HOJE'), findsOneWidget);
      expect(find.text('Treino A - Peito e Tríceps'), findsOneWidget);
      expect(find.text('Iniciar Treino'), findsOneWidget);
    });
  });

  group('DashboardNutritionCard Widget Test', () {
    testWidgets('should render calories and protein targets', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          DashboardNutritionCard(nutrition: tNutrition),
        ),
      );

      expect(find.text('NUTRIÇÃO HOJE'), findsOneWidget);
      expect(find.text('Calorias'), findsOneWidget);
      expect(find.text('0 / 2500 kcal'), findsOneWidget);
      expect(find.text('Proteína'), findsOneWidget);
      expect(find.text('0 / 180 g'), findsOneWidget);
    });
  });

  group('DashboardActiveGoalsCard Widget Test', () {
    testWidgets('should render active goals title and percentage', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          DashboardActiveGoalsCard(goals: [tGoal]),
        ),
      );

      expect(find.text('METAS EM ANDAMENTO'), findsOneWidget);
      expect(find.text('Chegar a 80kg'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });
  });

  group('WeeklyStreakWidget Widget Test', () {
    testWidgets('should render 7 days streak and count', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          WeeklyStreakWidget(stats: tWeeklyStats),
        ),
      );

      expect(find.text('Consistência Semanal'), findsOneWidget);
      expect(find.text('3/4 treinos'), findsOneWidget);
      expect(find.text('22'), findsOneWidget);
    });
  });

  group('DashboardStatsGrid Widget Test', () {
    testWidgets('should render volume, workouts count and duration', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          DashboardStatsGrid(stats: tWeeklyStats),
        ),
      );

      expect(find.text('12500 kg'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('180m'), findsOneWidget);
    });
  });
}
