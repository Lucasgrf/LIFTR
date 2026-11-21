import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/dashboard_active_goals_card.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/dashboard_nutrition_card.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/dashboard_stats_grid.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/today_workout_banner.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/weekly_streak_widget.dart';
import 'package:personal_fitness_os/features/insights/presentation/providers/insight_providers.dart';
import 'package:personal_fitness_os/features/insights/presentation/widgets/insight_card.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isStartingWorkout = false;

  Future<void> _startWorkout(Workout? workout) async {
    setState(() => _isStartingWorkout = true);

    try {
      final useCase = ref.read(startWorkoutSessionUseCaseProvider);

      List<SessionExercise>? initialExercises;
      if (workout != null && workout.exercises.isNotEmpty) {
        initialExercises = workout.exercises.map((we) {
          return SessionExercise(
            id: '',
            sessionId: '',
            exerciseId: we.exerciseId,
            sortOrder: we.sortOrder,
            notes: we.notes,
            targetRestSeconds: we.setTemplates.isNotEmpty
                ? we.setTemplates.first.restSeconds
                : 90,
            targetSetsCount: we.workingSetsCount > 0 ? we.workingSetsCount : 3,
          );
        }).toList();
      }

      final result = await useCase.execute(
        workoutId: workout?.id,
        workoutName: workout?.name ?? 'Treino Avulso',
        initialExercises: initialExercises,
      );

      if (!mounted) return;

      result.fold(
        (session) {
          ref.invalidate(dashboardDataProvider);
          context.push('/session/${session.id}');
        },
        (failure) {
          context.showSnackBar('Erro ao iniciar treino: ${failure.message}', isError: true);
        },
      );
    } finally {
      if (mounted) setState(() => _isStartingWorkout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final insightsAsync = ref.watch(fitnessInsightsProvider);

    final now = DateTime.now();
    final formattedDate = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(now);
    final capitalizedDate = formattedDate[0].toUpperCase() + formattedDate.substring(1);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoje',
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            Text(
              capitalizedDate,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Histórico & Timeline',
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
            onPressed: () => ref.invalidate(dashboardDataProvider),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, _) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(dashboardDataProvider),
        ),
        data: (data) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(dashboardDataProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // 1. Today's Workout Banner (Active Session / Prescribed Workout / Free)
                TodayWorkoutBanner(
                  activeSession: data.activeSession,
                  todayWorkout: data.todayWorkout,
                  activePlan: data.activePlan,
                  isLoading: _isStartingWorkout,
                  onStartWorkout: _startWorkout,
                ),
                const SizedBox(height: 16),

                // 2. Today's Nutrition Overview (if available)
                if (data.todayNutrition != null) ...[
                  DashboardNutritionCard(nutrition: data.todayNutrition!),
                  const SizedBox(height: 16),
                ],

                // 3. Active Goals Overview (if available)
                if (data.hasActiveGoals) ...[
                  DashboardActiveGoalsCard(goals: data.activeGoals),
                  const SizedBox(height: 16),
                ],

                // 4. Weekly Consistency / Streak Tracker
                WeeklyStreakWidget(stats: data.weeklyStats),
                const SizedBox(height: 16),

                // 5. Weekly Volume & Duration Statistics Grid
                DashboardStatsGrid(stats: data.weeklyStats),
                const SizedBox(height: 16),

                // 6. Deterministic Insights (if available)
                if (insightsAsync.hasValue && insightsAsync.value!.isNotEmpty) ...[
                  ...insightsAsync.value!.map((insight) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InsightCard(insight: insight),
                      )),
                ],
                const SizedBox(height: 8),

                // 7. Quick Shortcuts Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.fitness_center_rounded, size: 18),
                        label: const Text('Biblioteca'),
                        onPressed: () => context.push('/exercises'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.list_alt_rounded, size: 18),
                        label: const Text('Programas'),
                        onPressed: () => context.push('/training'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
