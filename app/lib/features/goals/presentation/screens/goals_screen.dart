import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';
import 'package:personal_fitness_os/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_fitness_os/features/goals/presentation/widgets/create_goal_modal.dart';
import 'package:personal_fitness_os/features/goals/presentation/widgets/goal_card.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final activeFilter = ref.watch(goalStatusFilterProvider);
    final goalsAsync = ref.watch(goalsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas & Objetivos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateGoalModal.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova Meta'),
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Ativas'),
                    selected: activeFilter == GoalStatus.active,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(goalStatusFilterProvider.notifier).state =
                            GoalStatus.active;
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Concluídas'),
                    selected: activeFilter == GoalStatus.completed,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(goalStatusFilterProvider.notifier).state =
                            GoalStatus.completed;
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: activeFilter == null,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(goalStatusFilterProvider.notifier).state = null;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Goals list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(goalsListProvider.future),
              child: goalsAsync.when(
                data: (goals) {
                  if (goals.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.flag_outlined,
                      title: 'Nenhuma meta encontrada',
                      subtitle: activeFilter == GoalStatus.active
                          ? 'Você não possui metas ativas no momento.\nClique em "Nova Meta" para começar!'
                          : 'Nenhuma meta registrada neste filtro.',
                      actionLabel: 'Criar Meta',
                      onAction: () => CreateGoalModal.show(context),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 88,
                    ),
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GoalCard(
                          goal: goal,
                          onTap: () => context.push('/goals/${goal.id}'),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: LoadingWidget()),
                error: (err, _) {
                  final message = err is Failure ? err.message : err.toString();
                  return Center(
                    child: AppErrorWidget(
                      message: message,
                      onRetry: () => ref.refresh(goalsListProvider),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
