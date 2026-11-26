import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/workout_queue_provider.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/export_plan_sheet.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/import_plan_sheet.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/switch_program_sheet.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/weekly_muscle_volume_card.dart';
import 'package:personal_fitness_os/features/workout_session/domain/helpers/session_exercise_builder.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';

class TrainingListScreen extends ConsumerStatefulWidget {
  const TrainingListScreen({super.key});

  @override
  ConsumerState<TrainingListScreen> createState() => _TrainingListScreenState();
}

class _TrainingListScreenState extends ConsumerState<TrainingListScreen> {
  bool _isStartingWorkout = false;

  Future<void> _startWorkout(Workout workout) async {
    if (_isStartingWorkout) return;
    setState(() => _isStartingWorkout = true);

    try {
      final useCase = ref.read(startWorkoutSessionUseCaseProvider);
      final defaultRest = ref.read(userSettingsProvider).defaultRestSeconds;
      final initialExercises = buildInitialSessionExercises(
        workout,
        defaultRestSeconds: defaultRest,
      );

      final result = await useCase.execute(
        workoutId: workout.id,
        workoutName: workout.name,
        initialExercises: initialExercises.isNotEmpty ? initialExercises : null,
      );

      if (!mounted) return;
      result.fold(
        (session) {
          ref.invalidate(dashboardDataProvider);
          context.push('/session/${session.id}');
        },
        (failure) => context.showSnackBar(
          'Erro ao iniciar treino: ${failure.message}',
          isError: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _isStartingWorkout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final plansAsync = ref.watch(trainingPlansStateProvider);
    ref.watch(workoutQueueProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: plansAsync.when(
        loading: () => const SafeArea(child: LiftrScreenSkeleton()),
        error: (error, st) => ErrorStateWidget(
          message: userFacingMessage(
            error,
            stackTrace: st,
            context: 'TrainingListScreen.build',
          ),
          safetyNote: offlineSafetyNoteFor(error),
          onRetry: () => ref.read(trainingPlansStateProvider.notifier).refresh(),
        ),
        data: (plans) {
          if (plans.isEmpty) {
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EmptyStateWidget(
                        icon: Icons.fitness_center_rounded,
                        title: 'Nenhum programa cadastrado',
                        subtitle:
                            'Crie seu programa com IA, importe o treino de alguém ou monte manualmente.',
                        actionLabel: 'Criar Programa',
                        onAction: () => context.push('/training/new'),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: Column(
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  context.push('/training/ai-generator'),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                foregroundColor: colors.primaryLight,
                              ),
                              icon: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 18,
                              ),
                              label: const Text('Montar treino com IA'),
                            ),
                            TextButton.icon(
                              onPressed: () => ImportPlanSheet.show(context),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                foregroundColor: colors.textSecondary,
                              ),
                              icon: const Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 18,
                              ),
                              label: const Text('Importar treino por código'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final activePlan =
              plans.where((p) => p.isActive).firstOrNull ?? plans.first;
          final orderedWorkouts = ref
              .read(workoutQueueProvider.notifier)
              .orderedWorkouts(activePlan.id, activePlan.workouts);

          return RefreshIndicator(
            color: colors.primary,
            onRefresh: () =>
                ref.read(trainingPlansStateProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 36),
              children: [
                ResponsiveContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Builder(
                          builder: (context) {
                            final isCompact =
                                MediaQuery.sizeOf(context).width < 360 ||
                                    MediaQuery.textScalerOf(context).scale(14) >
                                        18;
                            final titleBlock = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PROGRAMA ATIVO',
                                  style: AppTypography.eyebrow(context),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Treino',
                                  style: context.textTheme.displayMedium,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${activePlan.name} · ${orderedWorkouts.length} sessões',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                    fontFeatures: AppTypography.tabularFeatures,
                                  ),
                                ),
                              ],
                            );
                            final switchBtn = TextButton(
                              onPressed: () => SwitchProgramSheet.show(
                                context,
                                plans: plans,
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                foregroundColor: colors.primaryLight,
                              ),
                              child: const Text('Trocar programa'),
                            );

                            if (isCompact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  titleBlock,
                                  const SizedBox(height: 4),
                                  switchBtn,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: titleBlock),
                                switchBtn,
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Rotating Queue Header
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Fila rotativa',
                              style: context.textTheme.titleMedium,
                            ),
                            Text(
                              'ARRASTE PARA ORDENAR',
                              style: AppTypography.eyebrow(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (orderedWorkouts.isEmpty)
                        EmptyStateWidget(
                          icon: Icons.queue_rounded,
                          title: 'Nenhuma sessão na fila',
                          subtitle:
                              'Adicione as sessões deste programa (ex: Upper A, Lower A).',
                          actionLabel: 'Adicionar Sessão',
                          onAction: () => context.push(
                            '/training/${activePlan.id}/add-workout',
                          ),
                        )
                      else
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: orderedWorkouts.length,
                          proxyDecorator: (child, index, animation) {
                            return Material(
                              color: Colors.transparent,
                              child: child,
                            );
                          },
                          onReorder: (oldIndex, newIndex) {
                            HapticFeedback.selectionClick();
                            ref.read(workoutQueueProvider.notifier).reorder(
                                  activePlan.id,
                                  orderedWorkouts,
                                  oldIndex,
                                  newIndex,
                                );
                          },
                          itemBuilder: (context, index) {
                            final workout = orderedWorkouts[index];
                            return _QueueWorkoutCard(
                              key: ValueKey(workout.id),
                              index: index,
                              plan: activePlan,
                              workout: workout,
                              isStarting: _isStartingWorkout,
                              onStart: () => _startWorkout(workout),
                              onEdit: () => context.push(
                                '/training/${activePlan.id}/workout/${workout.id}',
                              ),
                              onSkipToEnd: orderedWorkouts.length > 1
                                  ? () {
                                      HapticFeedback.selectionClick();
                                      ref
                                          .read(workoutQueueProvider.notifier)
                                          .skipFirstToEnd(
                                            activePlan.id,
                                            orderedWorkouts,
                                          );
                                    }
                                  : null,
                            );
                          },
                        ),

                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: () => ExportPlanSheet.show(
                              context,
                              plan: activePlan,
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              foregroundColor: colors.textSecondary,
                            ),
                            icon: Icon(Icons.adaptive.share, size: 17),
                            label: const Text('Compartilhar plano'),
                          ),
                          TextButton.icon(
                            onPressed: () => context.push(
                              '/training/${activePlan.id}/add-workout',
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Adicionar sessão'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Weekly muscle volume card
                      WeeklyMuscleVolumeCard(plan: activePlan),
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

class _QueueWorkoutCard extends StatelessWidget {
  const _QueueWorkoutCard({
    super.key,
    required this.index,
    required this.plan,
    required this.workout,
    required this.isStarting,
    required this.onStart,
    required this.onEdit,
    this.onSkipToEnd,
  });

  final int index;
  final TrainingPlan plan;
  final Workout workout;
  final bool isStarting;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback? onSkipToEnd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final isNext = index == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: AppCard(
        variant: isNext ? AppCardVariant.accented : AppCardVariant.raised,
        accentColor: colors.primary,
        borderColor: isNext
            ? colors.primary.withValues(alpha: 0.48)
            : colors.border,
        borderRadius: radius.large,
        onTap: onEdit,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 310 ||
                MediaQuery.textScalerOf(context).scale(14) > 18;

            final dragHandle = ReorderableDragStartListener(
              index: index,
              child: Semantics(
                label: 'Reordenar ${workout.name}',
                child: SizedBox(
                  width: 40,
                  height: 48,
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: colors.textTertiary,
                    size: 20,
                  ),
                ),
              ),
            );

            final orderBadge = isNext
                ? const LiftrBadge(
                    label: 'Próximo',
                    tone: LiftrBadgeTone.brand,
                  )
                : SizedBox(
                    width: 36,
                    child: Text(
                      '${index + 1}º',
                      textAlign: TextAlign.center,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: colors.textTertiary,
                        fontFeatures: AppTypography.tabularFeatures,
                      ),
                    ),
                  );

            final infoColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  workout.name,
                  maxLines: isCompact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  '${workout.totalExercisesCount} exercícios · ${workout.totalWorkingSetsCount} séries',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    fontFeatures: AppTypography.tabularFeatures,
                  ),
                ),
              ],
            );

            final startButton = ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: ElevatedButton(
                onPressed: isStarting ? null : onStart,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(64, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius.small),
                  ),
                ),
                child: const Text('Iniciar'),
              ),
            );

            final menuButton = PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: colors.textSecondary,
              ),
              color: colors.surfaceElevated,
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'skip') {
                  onSkipToEnd?.call();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Editar sessão'),
                ),
                if (onSkipToEnd != null)
                  const PopupMenuItem(
                    value: 'skip',
                    child: Text('Pular para o fim da fila'),
                  ),
              ],
            );

            final trailingChevron = Icon(
              Icons.chevron_right_rounded,
              color: colors.textTertiary,
              size: 20,
            );

            if (isCompact) {
              return ConstrainedBox(
                constraints: BoxConstraints(minHeight: isNext ? 62 : 50),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        dragHandle,
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              orderBadge,
                              const SizedBox(height: 4),
                              infoColumn,
                            ],
                          ),
                        ),
                        if (isNext) menuButton else trailingChevron,
                      ],
                    ),
                    if (isNext) ...[
                      const SizedBox(height: 8),
                      startButton,
                    ],
                  ],
                ),
              );
            }

            return ConstrainedBox(
              constraints: BoxConstraints(minHeight: isNext ? 62 : 50),
              child: Row(
                children: [
                  dragHandle,
                  const SizedBox(width: 4),
                  orderBadge,
                  const SizedBox(width: 10),
                  Expanded(child: infoColumn),
                  if (isNext) ...[
                    const SizedBox(width: 6),
                    startButton,
                    menuButton,
                  ] else
                    trailingChevron,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
