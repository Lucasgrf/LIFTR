import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_brand_mark.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/last_completed_workout_card.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/today_exercise_preview_card.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/today_workout_banner.dart';
import 'package:personal_fitness_os/features/insights/domain/entities/fitness_insight.dart';
import 'package:personal_fitness_os/features/insights/presentation/providers/insight_providers.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/workout_queue_provider.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/providers/weekly_comparison_providers.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/widgets/log_cardio_modal.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/widgets/weekly_summary_card.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/helpers/session_exercise_builder.dart';
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
      final defaultRest = ref.read(userSettingsProvider).defaultRestSeconds;

      List<SessionExercise>? initialExercises;
      if (workout != null && workout.exercises.isNotEmpty) {
        initialExercises = buildInitialSessionExercises(
          workout,
          defaultRestSeconds: defaultRest,
        );
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
          context.showSnackBar(
            'Erro ao iniciar treino: ${failure.message}',
            isError: true,
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isStartingWorkout = false);
    }
  }

  void _openSkipOrSwapSheet(
    BuildContext context,
    TrainingPlan plan,
    List<Workout> orderedWorkouts,
  ) {
    final colors = context.appColors;
    final radius = context.appRadius;

    showLiftrSheet<void>(
      context: context,
      eyebrow: 'Fila rotativa · ${plan.name}',
      title: 'Escolher treino de hoje',
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (orderedWorkouts.length > 1)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(radius.small),
                  ),
                  child: Icon(
                    Icons.skip_next_rounded,
                    color: colors.primaryLight,
                  ),
                ),
                title: const Text('Pular treino atual'),
                subtitle: Text(
                  'Move "${orderedWorkouts.first.name}" para o fim da fila',
                  style: ctx.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(workoutQueueProvider.notifier)
                      .skipFirstToEnd(plan.id, orderedWorkouts);
                  Navigator.pop(ctx);
                },
              ),
            const Divider(),
            ...orderedWorkouts.asMap().entries.map((entry) {
              final idx = entry.key;
              final w = entry.value;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: idx == 0
                        ? colors.primaryMuted
                        : colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(radius.small),
                  ),
                  child: Text(
                    '${idx + 1}º',
                    style: ctx.textTheme.labelMedium?.copyWith(
                      color: idx == 0
                          ? colors.primaryLight
                          : colors.textSecondary,
                      fontFeatures: AppTypography.tabularFeatures,
                    ),
                  ),
                ),
                title: Text(w.name),
                subtitle: Text(
                  '${w.exercises.length} exercícios · ${w.totalWorkingSetsCount} séries',
                  style: ctx.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontFeatures: AppTypography.tabularFeatures,
                  ),
                ),
                trailing: idx == 0
                    ? Icon(Icons.check_rounded, color: colors.primary)
                    : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(workoutQueueProvider.notifier)
                      .selectNext(plan.id, orderedWorkouts, w.id);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final settings = ref.watch(userSettingsProvider);
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final weekSummaryAsync = ref.watch(currentWeekSummaryProvider);
    final insightsAsync = ref.watch(fitnessInsightsProvider);
    ref.watch(workoutQueueProvider);

    final now = ref.watch(appClockProvider)();
    final formattedDate = DateFormat("EEEE, d 'de' MMM", 'pt_BR').format(now);
    final capitalizedDate =
        formattedDate[0].toUpperCase() + formattedDate.substring(1);

    return Scaffold(
      backgroundColor: colors.background,
      body: dashboardAsync.when(
        loading: () => const SafeArea(child: LiftrScreenSkeleton()),
        error: (err, st) => ErrorStateWidget(
          message: userFacingMessage(
            err,
            stackTrace: st,
            context: 'DashboardScreen.build',
          ),
          safetyNote: offlineSafetyNoteFor(err),
          onRetry: () => ref.invalidate(dashboardDataProvider),
        ),
        data: (data) {
          final activePlan = data.activePlan;
          final orderedWorkouts = activePlan != null &&
                  activePlan.workouts.isNotEmpty
              ? ref.read(workoutQueueProvider.notifier).orderedWorkouts(
                    activePlan.id,
                    activePlan.workouts,
                    lastCompletedWorkoutId: data.lastCompletedSession?.workoutId,
                  )
              : const <Workout>[];
          final todayWorkout = orderedWorkouts.isNotEmpty
              ? orderedWorkouts.first
              : data.todayWorkout;

          final topInsight =
              insightsAsync.hasValue && insightsAsync.value!.isNotEmpty
                  ? insightsAsync.value!.first
                  : null;

          return RefreshIndicator(
            color: colors.primary,
            onRefresh: () async {
              ref.invalidate(currentWeekSummaryProvider);
              ref.invalidate(dashboardDataProvider);
              await ref.read(dashboardDataProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
              children: [
                ResponsiveContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Compact Header
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const LiftrBrandMark(size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'LIFTR · HOJE',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.eyebrow(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Hoje',
                                    style: context.textTheme.displayMedium,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    capitalizedDate,
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Semantics(
                              label: 'Abrir perfil',
                              button: true,
                              child: Material(
                                color: colors.surface,
                                shape: CircleBorder(
                                  side: BorderSide(color: colors.border),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => context.push('/profile'),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: _HeaderAvatarThumb(
                                      avatarUrl: settings.avatarUrl,
                                      storagePath: settings.avatarStoragePath,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Semantics(
                              label: 'Abrir configurações',
                              button: true,
                              child: Material(
                                color: colors.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(radius.medium),
                                  side: BorderSide(color: colors.border),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => context.push('/settings'),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Icon(
                                      Icons.settings_rounded,
                                      color: colors.textSecondary,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. Hero Card do Próximo Treino
                      TodayWorkoutBanner(
                        activeSession: data.activeSession,
                        todayWorkout: todayWorkout,
                        activePlan: activePlan,
                        isLoading: _isStartingWorkout,
                        queuePosition: orderedWorkouts.isNotEmpty ? 1 : null,
                        queueTotal: orderedWorkouts.isNotEmpty
                            ? orderedWorkouts.length
                            : null,
                        onSkipOrSwap: (activePlan != null &&
                                orderedWorkouts.length > 1)
                            ? () => _openSkipOrSwapSheet(
                                  context,
                                  activePlan,
                                  orderedWorkouts,
                                )
                            : null,
                        onStartWorkout: _startWorkout,
                      ),

                      // 2b. Último treino realizado
                      if (data.lastCompletedSession != null) ...[
                        const SizedBox(height: 14),
                        LastCompletedWorkoutCard(
                          session: data.lastCompletedSession!,
                          referenceNow: now,
                        ),
                      ],

                      // 2c. Resumo semanal compacto (Cardio + Treinos)
                      if (weekSummaryAsync.hasValue) ...[
                        const SizedBox(height: 14),
                        WeeklySummaryCard(
                          data: weekSummaryAsync.value!,
                          onOpenComparison: () =>
                              context.push('/weekly-comparison'),
                          onLogCardio: () => LogCardioModal.show(context),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 3. Exercícios de hoje
                      if (todayWorkout != null &&
                          todayWorkout.exercises.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Exercícios de hoje',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              flex: 2,
                              child: Text(
                                '${todayWorkout.exercises.length} PRESCRITOS',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: AppTypography.eyebrow(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (var i = 0;
                                  i < todayWorkout.exercises.length;
                                  i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: colors.borderSubtle,
                                  ),
                                TodayExercisePreviewCard(
                                  index: i,
                                  workoutExercise: todayWorkout.exercises[i],
                                  embedded: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // 4. Máximo 1 card de Insight discreto
                      if (topInsight != null) ...[
                        const SizedBox(height: 6),
                        _DashboardSingleInsightCard(insight: topInsight),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderAvatarThumb extends StatelessWidget {
  const _HeaderAvatarThumb({
    required this.avatarUrl,
    required this.storagePath,
  });

  final String? avatarUrl;
  final String? storagePath;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final url = avatarUrl?.trim() ?? '';

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          cacheKey: (storagePath != null && storagePath!.isNotEmpty)
              ? storagePath
              : url,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Icon(
            Icons.person_outline_rounded,
            color: colors.textSecondary,
            size: 22,
          ),
        ),
      );
    }

    if (url.isNotEmpty) {
      final file = File(url);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(file, fit: BoxFit.cover),
        );
      }
    }

    return Icon(
      Icons.person_outline_rounded,
      color: colors.textSecondary,
      size: 22,
    );
  }
}

class _DashboardSingleInsightCard extends StatelessWidget {
  const _DashboardSingleInsightCard({required this.insight});

  final FitnessInsight insight;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final fitnessColors = context.fitnessColors;

    final Color accent;
    final IconData icon;
    switch (insight.severity) {
      case InsightSeverity.success:
        accent = fitnessColors.progressUp;
        icon = Icons.trending_up_rounded;
        break;
      case InsightSeverity.warning:
      case InsightSeverity.alert:
        accent = fitnessColors.progressStalled;
        icon = Icons.warning_amber_rounded;
        break;
      case InsightSeverity.info:
        accent = colors.primaryLight;
        icon = Icons.insights_rounded;
        break;
    }

    return AppCard(
      variant: AppCardVariant.accented,
      accentColor: accent,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(radius.small),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${insight.title}. ${insight.description}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
