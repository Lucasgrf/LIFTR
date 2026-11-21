import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';
import 'package:personal_fitness_os/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_fitness_os/features/goals/presentation/widgets/add_checkpoint_modal.dart';
import 'package:personal_fitness_os/features/goals/presentation/widgets/goal_progress_bar.dart';

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({
    super.key,
    required this.goalId,
  });

  final String goalId;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Meta'),
        content: const Text(
            'Deseja realmente excluir esta meta e todo o seu histórico de checkpoints?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final useCase = ref.read(deleteGoalUseCaseProvider);
      final result = await useCase.execute(goalId);

      result.fold(
        (_) {
          ref.invalidate(goalsListProvider);
          messenger.showSnackBar(
            const SnackBar(content: Text('Meta excluída com sucesso.')),
          );
          if (context.mounted) {
            context.pop();
          }
        },
        (failure) => messenger.showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final goalAsync = ref.watch(goalDetailProvider(goalId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Meta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Excluir Meta',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: goalAsync.when(
        data: (goal) {
          final sortedCheckpoints = [...goal.checkpoints]
            ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(context.appRadius.small),
                          ),
                          child: Text(
                            goal.category.label.toUpperCase(),
                            style: context.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        PopupMenuButton<GoalStatus>(
                          initialValue: goal.status,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant,
                              borderRadius: BorderRadius.circular(
                                  context.appRadius.small),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  goal.status.label,
                                  style:
                                      context.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, size: 16),
                              ],
                            ),
                          ),
                          onSelected: (newStatus) async {
                            final messenger = ScaffoldMessenger.of(context);
                            final useCase =
                                ref.read(updateGoalStatusUseCaseProvider);
                            final res =
                                await useCase.execute(goal.id, newStatus);
                            res.fold(
                              (_) {
                                ref.invalidate(goalDetailProvider(goal.id));
                                ref.invalidate(goalsListProvider);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Status atualizado para ${newStatus.label}.'),
                                  ),
                                );
                              },
                              (failure) => messenger.showSnackBar(
                                SnackBar(
                                  content: Text(failure.message),
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            );
                          },
                          itemBuilder: (context) => GoalStatus.values.map(
                            (st) => PopupMenuItem(
                              value: st,
                              child: Text(st.label),
                            ),
                          ).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      goal.title,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (goal.description != null &&
                        goal.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        goal.description!,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Progress bar
                    GoalProgressBar(goal: goal),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Metadata
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MetaInfo(
                          label: 'Início',
                          value: goal.startedAt.formatShort(),
                        ),
                        if (goal.deadline != null)
                          _MetaInfo(
                            label: 'Prazo',
                            value: goal.deadline!.formatShort(),
                          ),
                        if (goal.completedAt != null)
                          _MetaInfo(
                            label: 'Concluída em',
                            value: goal.completedAt!.formatShort(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Checkpoints Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'HISTÓRICO DE CHECK-INS',
                    style: context.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textSecondary,
                      letterSpacing: 1.1,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => AddCheckpointModal.show(context, goal: goal),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Registrar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (sortedCheckpoints.isEmpty) ...[
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Nenhum check-in registrado ainda.\nClique em "Registrar" para atualizar seu progresso!',
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                ...sortedCheckpoints.map(
                  (cp) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant,
                              borderRadius: BorderRadius.circular(
                                  context.appRadius.small),
                            ),
                            child: Icon(Icons.trending_up_rounded,
                                size: 20, color: fitnessColors.progressUp),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${cp.value.toStringAsFixed(1)} ${goal.unit}',
                                  style: context.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                if (cp.notes != null &&
                                    cp.notes!.isNotEmpty) ...[
                                  Text(
                                    cp.notes!,
                                    style:
                                        context.textTheme.bodySmall?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            cp.recordedAt.formatShort(),
                            style: context.textTheme.labelSmall?.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: LoadingWidget()),
        error: (err, _) {
          final message = err is Failure ? err.message : err.toString();
          return Center(
            child: AppErrorWidget(
              message: message,
              onRetry: () => ref.refresh(goalDetailProvider(goalId)),
            ),
          );
        },
      ),
    );
  }
}

class _MetaInfo extends StatelessWidget {
  const _MetaInfo({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
