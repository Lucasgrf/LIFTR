import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/workout_exercise_card.dart';
import 'package:personal_fitness_os/features/workout_session/domain/helpers/session_exercise_builder.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  const WorkoutDetailScreen({
    required this.workoutId,
    this.planId,
    super.key,
  });

  final String workoutId;
  final String? planId;

  @override
  ConsumerState<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  bool _isReordering = false;
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

  Future<void> _deleteExercise(WorkoutExercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surfaceElevated,
        title: const Text('Remover Exercício'),
        content: Text(
          'Deseja remover "${exercise.exercise?.name ?? 'este exercício'}" deste treino?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.appColors.danger),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(trainingRepositoryProvider);
      final result = await repo.deleteWorkoutExercise(exercise.id);

      if (!mounted) return;

      result.fold(
        (_) {
          if (widget.planId != null) {
            ref.invalidate(trainingPlanDetailProvider(widget.planId!));
          }
          context.showSnackBar('Exercício removido com sucesso!');
        },
        (failure) {
          context.showSnackBar('Erro ao remover exercício: ${failure.message}', isError: true);
        },
      );
    }
  }

  Future<void> _reorderExercises(Workout workout, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final exercises = List<WorkoutExercise>.from(workout.exercises);
    final moved = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, moved);

    final orderedIds = exercises.map((e) => e.id).toList();
    final useCase = ref.read(reorderWorkoutExercisesUseCaseProvider);
    final result = await useCase.execute(
      workoutId: workout.id,
      orderedWorkoutExerciseIds: orderedIds,
    );

    if (!mounted) return;

    result.fold(
      (_) {
        if (widget.planId != null) {
          ref.invalidate(trainingPlanDetailProvider(widget.planId!));
        }
      },
      (failure) {
        context.showSnackBar('Erro ao reordenar: ${failure.message}', isError: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.planId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes do Treino')),
        body: const Center(child: Text('Plano não especificado')),
      );
    }

    final workoutAsync = ref.watch(
      workoutDetailProvider((planId: widget.planId!, workoutId: widget.workoutId)),
    );

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: const Text('Prescrição do Treino'),
        actions: [
          IconButton(
            icon: Icon(
              _isReordering ? Icons.done_rounded : Icons.swap_vert_rounded,
              color: _isReordering ? context.appColors.primary : null,
            ),
            tooltip: _isReordering ? 'Concluir reordenação' : 'Reordenar exercícios',
            onPressed: () => setState(() => _isReordering = !_isReordering),
          ),
        ],
      ),
      body: workoutAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.refresh(
            workoutDetailProvider((planId: widget.planId!, workoutId: widget.workoutId)),
          ),
        ),
        data: (workout) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  children: [
                    // Header card
                    AppCard(
                      padding: EdgeInsets.all(context.appSpacing.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                workout.dayOfWeekLabel.toUpperCase(),
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: context.appColors.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              if (workout.estimatedDurationMinutes != null) ...[
                                Icon(Icons.timer_rounded,
                                    size: 14, color: context.appColors.textTertiary),
                                AppSpacing.horizontalGap4,
                                Text(
                                  '~${workout.estimatedDurationMinutes} min',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.appColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          AppSpacing.verticalGap12,
                          Text(
                            workout.name,
                            style: context.textTheme.titleLarge?.copyWith(
                              color: context.appColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (workout.notes != null && workout.notes!.isNotEmpty) ...[
                            AppSpacing.verticalGap8,
                            Text(
                              workout.notes!,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.appColors.textSecondary,
                              ),
                            ),
                          ],
                          AppSpacing.verticalGap12,
                          Row(
                            children: [
                              Text(
                                '${workout.totalExercisesCount} exercícios',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.appColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              AppSpacing.horizontalGap8,
                              Text(
                                '·',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.appColors.textTertiary,
                                ),
                              ),
                              AppSpacing.horizontalGap8,
                              Text(
                                '${workout.totalWorkingSetsCount} séries válidas',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.appColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Exercises section title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'EXERCÍCIOS',
                          style: context.textTheme.labelMedium?.copyWith(
                            color: context.appColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => context.push(
                            '/training/${widget.planId}/workout/${widget.workoutId}/add-exercise',
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Adicionar Exercício'),
                          style: TextButton.styleFrom(
                            foregroundColor: context.appColors.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Exercises list / Reorderable
                    if (workout.exercises.isEmpty)
                      EmptyStateWidget(
                        icon: Icons.fitness_center_rounded,
                        title: 'Nenhum exercício no treino',
                        subtitle: 'Adicione os exercícios prescritos a partir da biblioteca.',
                        actionLabel: 'Adicionar Exercício',
                        onAction: () => context.push(
                          '/training/${widget.planId}/workout/${widget.workoutId}/add-exercise',
                        ),
                      )
                    else if (_isReordering)
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: workout.exercises.length,
                        onReorder: (oldIdx, newIdx) => _reorderExercises(workout, oldIdx, newIdx),
                        itemBuilder: (context, index) {
                          final exercise = workout.exercises[index];
                          return Card(
                            key: ValueKey(exercise.id),
                            color: context.appColors.surfaceVariant,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Text(
                                '${index + 1}',
                                style: context.textTheme.titleSmall?.copyWith(
                                  color: context.appColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              title: Text(
                                exercise.exercise?.name ?? 'Exercício',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.appColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                '${exercise.totalSetsCount} séries',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.appColors.textSecondary,
                                ),
                              ),
                              trailing: const Icon(Icons.drag_handle_rounded),
                            ),
                          );
                        },
                      )
                    else
                      ...workout.exercises.asMap().entries.map((entry) {
                        final index = entry.key;
                        final exercise = entry.value;
                        return WorkoutExerciseCard(
                          workoutExercise: exercise,
                          index: index + 1,
                          onDelete: () => _deleteExercise(exercise),
                          onConfigureSets: () => context.push(
                            '/training/${widget.planId}/workout/${widget.workoutId}/exercise/${exercise.id}/configure-sets',
                          ),
                        );
                      }),
                  ],
                ),
              ),

              // Bottom Bar with "Iniciar Treino"
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceElevated,
                  border: Border(
                    top: BorderSide(color: context.appColors.border, width: 1),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: AppButton.primary(
                    label: 'Iniciar treino',
                    icon: Icons.play_arrow_rounded,
                    isLoading: _isStartingWorkout,
                    onPressed: () => _startWorkout(workout),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
