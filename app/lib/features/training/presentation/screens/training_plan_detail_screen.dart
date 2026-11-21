import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/workout_card.dart';

class TrainingPlanDetailScreen extends ConsumerStatefulWidget {
  const TrainingPlanDetailScreen({
    required this.planId,
    super.key,
  });

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
    final useCase = ref.read(setActiveTrainingPlanUseCaseProvider);
    final result = await useCase.execute(plan.id);

    if (!mounted) return;
    setState(() => _isActivating = false);

    result.fold(
      (updated) {
        ref.invalidate(trainingPlanDetailProvider(widget.planId));
        ref.read(trainingPlansStateProvider.notifier).refresh();
        context.showSnackBar('Programa "${updated.name}" agora é o plano ativo!');
      },
      (failure) {
        context.showSnackBar('Erro ao ativar programa: ${failure.message}', isError: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(trainingPlanDetailProvider(widget.planId));

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: const Text('Detalhes do Programa'),
      ),
      body: planAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(trainingPlanDetailProvider(widget.planId)),
        ),
        data: (plan) {
          final activeColor = context.fitnessColors.progressUp;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            children: [
              // Header Card
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (plan.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: activeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(context.appRadius.small),
                              border: Border.all(color: activeColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              'PROGRAMA ATIVO',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: activeColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: context.appColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(context.appRadius.small),
                            ),
                            child: Text(
                              'ARQUIVADO',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: context.appColors.textTertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (!plan.isActive)
                          SizedBox(
                            width: 140,
                            child: AppButton.secondary(
                              label: 'Tornar Ativo',
                              isLoading: _isActivating,
                              onPressed: () => _activatePlan(plan),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      plan.name,
                      style: context.textTheme.headlineMedium?.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (plan.description != null && plan.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        plan.description!,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatBox(
                          context,
                          'Treinos',
                          '${plan.totalWorkoutsCount}',
                        ),
                        const SizedBox(width: 12),
                        _buildStatBox(
                          context,
                          'Séries / semana',
                          '${plan.totalWeeklySetsCount}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Workouts section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TREINOS DA SEMANA',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.appColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/training/${plan.id}/add-workout'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Adicionar Treino'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.appColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Workouts list
              if (plan.workouts.isEmpty)
                EmptyStateWidget(
                  icon: Icons.calendar_today_rounded,
                  title: 'Nenhum treino adicionado',
                  subtitle: 'Adicione os dias de treino a este programa (ex: Treino A - Superior).',
                  actionLabel: 'Adicionar Treino',
                  onAction: () => context.push('/training/${plan.id}/add-workout'),
                )
              else
                ...plan.workouts.map(
                  (workout) => WorkoutCard(
                    workout: workout,
                    onTap: () => context.push('/training/${plan.id}/workout/${workout.id}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatBox(BuildContext context, String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appColors.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(context.appRadius.small),
          border: Border.all(color: context.appColors.border.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.appColors.textTertiary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: context.textTheme.titleMedium?.copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
