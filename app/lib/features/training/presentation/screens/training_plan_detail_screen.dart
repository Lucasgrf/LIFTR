import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_icon.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/export_plan_sheet.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/weekly_muscle_volume_card.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/workout_card.dart';

class TrainingPlanDetailScreen extends ConsumerStatefulWidget {
  const TrainingPlanDetailScreen({required this.planId, super.key});

  final String planId;

  @override
  ConsumerState<TrainingPlanDetailScreen> createState() =>
      _TrainingPlanDetailScreenState();
}

class _TrainingPlanDetailScreenState
    extends ConsumerState<TrainingPlanDetailScreen> {
  bool _isActivating = false;

  Future<void> _activatePlan(TrainingPlan plan) async {
    setState(() => _isActivating = true);
    final result = await ref
        .read(setActiveTrainingPlanUseCaseProvider)
        .execute(plan.id);
    if (!mounted) return;
    setState(() => _isActivating = false);
    result.fold(
      (updated) {
        ref.invalidate(trainingPlanDetailProvider(widget.planId));
        ref.read(trainingPlansStateProvider.notifier).refresh();
        context.showSnackBar(
          'Programa “${updated.name}” agora é o programa ativo.',
        );
      },
      (failure) => context.showSnackBar(
        'Erro ao ativar programa: ${failure.message}',
        isError: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final planAsync = ref.watch(trainingPlanDetailProvider(widget.planId));

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            ResponsiveContainer(
              child: Row(
                children: [
                  _HeaderIcon(
                    label: 'Voltar',
                    icon: LiftrIconName.back,
                    onTap: () => context.pop(),
                  ),
                  const Spacer(),
                  Semantics(
                    label: 'Compartilhar programa',
                    button: true,
                    child: planAsync.asData == null
                        ? const SizedBox(width: 48, height: 48)
                        : TextButton.icon(
                            onPressed: () => ExportPlanSheet.show(
                              context,
                              plan: planAsync.asData!.value,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              textStyle: context.textTheme.bodyMedium?.copyWith(
                                decoration: TextDecoration.underline,
                              ),
                              minimumSize: const Size(48, 48),
                            ),
                            icon: const LiftrIcon(
                              LiftrIconName.share,
                              size: 18,
                            ),
                            label: const Text('Compartilhar'),
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: planAsync.when(
                loading: () => const LiftrScreenSkeleton(),
                error: (error, stack) => ErrorStateWidget(
                  message: userFacingMessage(
                    error,
                    stackTrace: stack,
                    context: 'TrainingPlanDetailScreen.build',
                  ),
                  safetyNote: offlineSafetyNoteFor(error),
                  onRetry: () =>
                      ref.invalidate(trainingPlanDetailProvider(widget.planId)),
                ),
                data: (plan) => ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                  children: [
                    ResponsiveContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Treino',
                            style: context.textTheme.displayMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  plan.name,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                plan.isActive
                                    ? 'Programa ativo'
                                    : 'Programa arquivado',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (plan.description?.trim().isNotEmpty ?? false) ...[
                            const SizedBox(height: 12),
                            Text(
                              plan.description!.trim(),
                              style: context.textTheme.bodyMedium,
                            ),
                          ],
                          if (!plan.isActive) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: _isActivating
                                    ? null
                                    : () => _activatePlan(plan),
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.textPrimary,
                                  minimumSize: const Size(48, 48),
                                  textStyle: context.textTheme.bodyMedium
                                      ?.copyWith(
                                        decoration: TextDecoration.underline,
                                      ),
                                ),
                                child: Text(
                                  _isActivating ? 'Ativando…' : 'Tornar ativo',
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'O baralho',
                                  style: context.textTheme.titleLarge,
                                ),
                              ),
                              Text(
                                '${plan.workouts.length} fichas',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (plan.workouts.isEmpty)
                            _EmptyPlan(
                              onAdd: () => context.push(
                                '/training/${plan.id}/add-workout',
                              ),
                            )
                          else
                            for (final workout
                                in [...plan.workouts]..sort(
                                  (a, b) => a.sortOrder.compareTo(b.sortOrder),
                                ))
                              WorkoutCard(
                                workout: workout,
                                onTap: () => context.push(
                                  '/training/${plan.id}/workout/${workout.id}',
                                ),
                              ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: () => context.push(
                              '/training/${plan.id}/add-workout',
                            ),
                            icon: const LiftrIcon(LiftrIconName.plus),
                            label: const Text('Nova ficha'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                          const SizedBox(height: 32),
                          WeeklyMuscleVolumeCard(plan: plan),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final LiftrIconName icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: LiftrIcon(icon, color: context.appColors.textPrimary),
        ),
      ),
    ),
  );
}

class _EmptyPlan extends StatelessWidget {
  const _EmptyPlan({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Nenhuma ficha neste programa.',
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.appColors.textSecondary,
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: onAdd,
        style: TextButton.styleFrom(
          foregroundColor: context.appColors.textPrimary,
          minimumSize: const Size(48, 48),
          textStyle: context.textTheme.bodyMedium?.copyWith(
            decoration: TextDecoration.underline,
          ),
        ),
        child: const Text('Adicionar ficha'),
      ),
    ],
  );
}
