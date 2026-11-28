import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/workout_card_palette.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_blank_fiche.dart';
import 'package:personal_fitness_os/core/widgets/liftr_icon.dart';
import 'package:personal_fitness_os/core/widgets/liftr_workout_card.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/workout_queue_provider.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/export_plan_sheet.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/import_plan_sheet.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/switch_program_sheet.dart';

class TrainingListScreen extends ConsumerWidget {
  const TrainingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final plansAsync = ref.watch(trainingPlansStateProvider);

    Future<void> refreshPlans() async {
      final hadData = ref.read(trainingPlansStateProvider).hasValue;
      final failure = await ref
          .read(trainingPlansStateProvider.notifier)
          .refresh();
      if (failure != null && hadData && context.mounted) {
        final message = userFacingMessage(
          failure,
          stackTrace: failure.stackTrace,
          context: 'TrainingListScreen.refreshPlans',
        );
        context.showSnackBar('$message Mostrando dados salvos.');
      }
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: plansAsync.when(
        loading: () => const LiftrScreenSkeleton(),
        error: (error, stack) => RefreshIndicator(
          color: colors.primary,
          onRefresh: refreshPlans,
          child: LayoutBuilder(
            builder: (context, constraints) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: ErrorStateWidget(
                    message: userFacingMessage(
                      error,
                      stackTrace: stack,
                      context: 'TrainingListScreen.build',
                    ),
                    safetyNote: offlineSafetyNoteFor(error),
                    onRetry: refreshPlans,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (plans) {
          if (plans.isEmpty) {
            return _NoProgramState(
              onCreate: () => context.push('/training/new'),
              onImport: () => ImportPlanSheet.show(context),
              onAi: () => context.push('/training/ai-generator'),
              onRefresh: refreshPlans,
            );
          }

          final activePlan =
              plans.where((plan) => plan.isActive).firstOrNull ?? plans.first;
          final orderedWorkouts = ref
              .read(workoutQueueProvider.notifier)
              .orderedWorkouts(activePlan.id, activePlan.workouts);

          return RefreshIndicator(
            color: colors.primary,
            onRefresh: refreshPlans,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 32, 0, 36),
              children: [
                ResponsiveContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Treino', style: context.textTheme.displayMedium),
                      const SizedBox(height: 4),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final planName = Text(
                            activePlan.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          );
                          final switchButton = TextButton(
                            onPressed: () =>
                                SwitchProgramSheet.show(context, plans: plans),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              foregroundColor: colors.textPrimary,
                              padding: EdgeInsets.zero,
                              textStyle: context.textTheme.labelMedium
                                  ?.copyWith(
                                    decoration: TextDecoration.underline,
                                    decorationThickness: 1.5,
                                  ),
                            ),
                            child: const Text('Trocar programa'),
                          );

                          if (MediaQuery.textScalerOf(context).scale(14) >=
                              20) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                planName,
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: switchButton,
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: planName),
                              switchButton,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'O baralho',
                              style: context.textTheme.titleLarge,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'segure e arraste para reordenar',
                              textAlign: TextAlign.right,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (orderedWorkouts.isEmpty)
                        _EmptyQueue(
                          onAdd: () => context.push(
                            '/training/${activePlan.id}/add-workout',
                          ),
                        )
                      else
                        _WorkoutDeck(
                          plan: activePlan,
                          workouts: orderedWorkouts,
                          onReorder: (oldIndex, newIndex) {
                            HapticFeedback.selectionClick();
                            ref
                                .read(workoutQueueProvider.notifier)
                                .reorder(
                                  activePlan.id,
                                  orderedWorkouts,
                                  oldIndex,
                                  newIndex,
                                );
                          },
                        ),
                      if (orderedWorkouts.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Cada treino ganha uma cor de papel quando entra no programa. Você pode trocar a cor na própria ficha.',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context.push(
                                '/training/${activePlan.id}/add-workout',
                              ),
                              icon: const LiftrIcon(
                                LiftrIconName.plus,
                                size: 20,
                              ),
                              label: const Text('Nova ficha'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                textStyle: context.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => ExportPlanSheet.show(
                                context,
                                plan: activePlan,
                              ),
                              icon: const LiftrIcon(
                                LiftrIconName.share,
                                size: 20,
                              ),
                              label: const Text('Compartilhar'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                textStyle: context.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _NoProgramState extends StatelessWidget {
  const _NoProgramState({
    required this.onCreate,
    required this.onImport,
    required this.onAi,
    required this.onRefresh,
  });

  final VoidCallback onCreate;
  final VoidCallback onImport;
  final VoidCallback onAi;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return RefreshIndicator(
      color: colors.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 32, 0, 36),
        children: [
          ResponsiveContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Treino', style: context.textTheme.displayMedium),
                const SizedBox(height: 8),
                Text(
                  'Nenhum programa ainda',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                LiftrBlankFiche(
                  title: 'Nenhuma ficha ainda',
                  description:
                      'Monte seu programa ou cole o código de um programa que alguém te mandou.',
                ),
                const LiftrBlankFicheDeck(),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const LiftrIcon(LiftrIconName.plus),
                  label: const Text('Montar programa'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onImport,
                  icon: const LiftrIcon(LiftrIconName.copy),
                  label: const Text('Colar código de programa'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onAi,
                  child: const Text('Montar treino com IA'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const LiftrBlankFiche(
        title: 'Nenhuma ficha no baralho',
        description:
            'Adicione uma ficha para começar a preencher o seu programa.',
      ),
      const LiftrBlankFicheDeck(),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: onAdd,
        icon: const LiftrIcon(LiftrIconName.plus),
        label: const Text('Nova ficha'),
      ),
    ],
  );
}

class _WorkoutDeck extends StatelessWidget {
  const _WorkoutDeck({
    required this.plan,
    required this.workouts,
    required this.onReorder,
  });

  final TrainingPlan plan;
  final List<Workout> workouts;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    const firstHeight = 96.0;
    const lastHeight = 72.0;
    const cardHeight = 70.0;
    const step = 62.0;
    return SizedBox(
      height: workouts.isEmpty
          ? 0
          : firstHeight + step * (workouts.length - 1) + 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < workouts.length; index++)
            Positioned(
              top: index == 0 ? 0 : 88 + step * (index - 1),
              left: 0,
              right: 0,
              height: index == 0
                  ? firstHeight
                  : index == workouts.length - 1
                  ? lastHeight
                  : cardHeight,
              child: _WorkoutDeckCard(
                index: index,
                workout: workouts[index],
                isFirst: index == 0,
                isLast: index == workouts.length - 1,
                onTap: () => context.push(
                  '/training/${plan.id}/workout/${workouts[index].id}',
                ),
                onReorder: onReorder,
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkoutDeckCard extends StatelessWidget {
  const _WorkoutDeckCard({
    required this.index,
    required this.workout,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.onReorder,
  });

  final int index;
  final Workout workout;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    final color = WorkoutCardPalette.forIndex(workout.sortOrder);
    final width = MediaQuery.sizeOf(context).width - 40;
    final largeText = MediaQuery.textScalerOf(context).scale(14) >= 20;
    final height = isFirst
        ? 96.0
        : isLast
        ? 72.0
        : 70.0;
    final bottomPadding = largeText ? 7.0 : 8.0;

    return DragTarget<int>(
      onAcceptWithDetails: (details) {
        if (details.data == index) return;
        final destination = details.data < index ? index + 1 : index;
        onReorder(details.data, destination);
      },
      builder: (context, candidates, rejects) => Semantics(
        label:
            'Ficha ${index + 1}, ${workout.name}, ${workout.exercises.length} exercícios, ${workout.totalWorkingSetsCount} séries',
        child: LiftrWorkoutCard(
          color: color,
          onTap: onTap,
          padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 8, 16, bottomPadding),
          child: Row(
            crossAxisAlignment: isFirst
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${index + 1}',
                  style: context.textTheme.displaySmall?.copyWith(
                    color: WorkoutCardPalette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      workout.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (isFirst
                                  ? context.textTheme.titleLarge
                                  : context.textTheme.bodyLarge)
                              ?.copyWith(
                                color: WorkoutCardPalette.ink,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    if (!largeText)
                      Text(
                        '${workout.exercises.length} exercícios, ${workout.totalWorkingSetsCount} séries${isFirst ? '. Próxima.' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: WorkoutCardPalette.secondaryInk,
                          fontFeatures: AppTypography.tabularFeatures,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              LongPressDraggable<int>(
                data: index,
                delay: const Duration(milliseconds: 250),
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: LiftrWorkoutCard(
                      color: color,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        isFirst ? 16 : 8,
                        16,
                        bottomPadding,
                      ),
                      child: Text(
                        workout.name,
                        style: context.textTheme.titleLarge?.copyWith(
                          color: WorkoutCardPalette.ink,
                        ),
                      ),
                    ),
                  ),
                ),
                child: Semantics(
                  label: 'Segure e arraste para reordenar ${workout.name}',
                  button: true,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: LiftrIcon(
                        LiftrIconName.reorder,
                        color: WorkoutCardPalette.secondaryInk.withValues(
                          alpha: .7,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
