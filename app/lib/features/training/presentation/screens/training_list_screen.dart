import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/workout_queue_provider.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/switch_program_sheet.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/weekly_muscle_volume_card.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
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
      final initialExercises = workout.exercises.map((we) {
        final firstWorking =
            we.setTemplates.where((s) => s.isWorkingSet).firstOrNull;
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
          targetRepsMin: firstWorking?.targetRepsMin ?? 8,
          targetRepsMax: firstWorking?.targetRepsMax ?? 12,
          targetRir: firstWorking?.targetRirMin ?? 2,
        );
      }).toList();

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
        error: (error, _) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.read(trainingPlansStateProvider.notifier).refresh(),
        ),
        data: (plans) {
          if (plans.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.fitness_center_rounded,
              title: 'Nenhum programa cadastrado',
              subtitle:
                  'Crie seu primeiro programa para organizar sua fila rotativa de treinos.',
              actionLabel: 'Criar Programa',
              onAction: () => context.push('/training/new'),
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
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
                                      fontFeatures:
                                          AppTypography.tabularFeatures,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => SwitchProgramSheet.show(
                                context,
                                plans: plans,
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                foregroundColor: colors.primaryLight,
                              ),
                              child: const Text('Trocar programa'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Rotating Queue Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => context.push(
                              '/training/${activePlan.id}/add-workout',
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
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(radius.large),
        child: Container(
          constraints: BoxConstraints(minHeight: isNext ? 86 : 74),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(radius.large),
            border: Border.all(
              color: isNext
                  ? colors.primary.withValues(alpha: 0.48)
                  : colors.border,
            ),
            gradient: isNext
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      colors.primary.withValues(alpha: 0.09),
                      colors.surface,
                    ],
                    stops: const [0.0, 0.7],
                  )
                : null,
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Semantics(
                  label: 'Reordenar ${workout.name}',
                  child: SizedBox(
                    width: 32,
                    height: 44,
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: colors.textTertiary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (isNext)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryMuted,
                    borderRadius: BorderRadius.circular(radius.full),
                  ),
                  child: Text(
                    'Próximo',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.primaryLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: 36,
                  child: Text(
                    '${index + 1}º',
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: colors.textTertiary,
                      fontFeatures: AppTypography.tabularFeatures,
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      workout.name,
                      maxLines: 1,
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
                ),
              ),
              if (isNext) ...[
                const SizedBox(width: 6),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: isStarting ? null : onStart,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(64, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radius.small),
                      ),
                    ),
                    child: const Text('Iniciar'),
                  ),
                ),
                PopupMenuButton<String>(
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
                ),
              ] else
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.textTertiary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
