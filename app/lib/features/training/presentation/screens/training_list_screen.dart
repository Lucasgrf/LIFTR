import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/training_plan_card.dart';

class TrainingListScreen extends ConsumerStatefulWidget {
  const TrainingListScreen({super.key});

  @override
  ConsumerState<TrainingListScreen> createState() => _TrainingListScreenState();
}

class _TrainingListScreenState extends ConsumerState<TrainingListScreen> {
  String? _activatingPlanId;

  Future<void> _activatePlan(TrainingPlan plan) async {
    setState(() => _activatingPlanId = plan.id);
    final useCase = ref.read(setActiveTrainingPlanUseCaseProvider);
    final result = await useCase.execute(plan.id);

    if (!mounted) return;
    setState(() => _activatingPlanId = null);

    result.fold(
      (updated) {
        ref.read(trainingPlansStateProvider.notifier).refresh();
        context.showSnackBar('Programa "${updated.name}" ativado com sucesso!');
      },
      (failure) {
        context.showSnackBar('Erro ao ativar programa: ${failure.message}', isError: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(trainingPlansStateProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: const Text('Programas de Treino'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
            onPressed: () => ref.read(trainingPlansStateProvider.notifier).refresh(),
          ),
        ],
      ),
      body: plansAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.read(trainingPlansStateProvider.notifier).refresh(),
        ),
        data: (plans) {
          if (plans.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.fitness_center_rounded,
              title: 'Nenhum programa cadastrado',
              subtitle: 'Crie seu primeiro programa de treino (ex: Upper/Lower, ABC, Push/Pull/Legs).',
              actionLabel: 'Criar Programa',
              onAction: () => context.push('/training/new'),
            );
          }

          final activePlans = plans.where((p) => p.isActive).toList();
          final archivedPlans = plans.where((p) => !p.isActive).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(trainingPlansStateProvider.notifier).refresh(),
            color: context.appColors.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              children: [
                if (activePlans.isNotEmpty) ...[
                  Text(
                    'PROGRAMA ATUAL',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.appColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...activePlans.map(
                    (plan) => TrainingPlanCard(
                      plan: plan,
                      onTap: () => context.push('/training/${plan.id}'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (archivedPlans.isNotEmpty) ...[
                  Text(
                    'OUTROS PROGRAMAS',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.appColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...archivedPlans.map(
                    (plan) => TrainingPlanCard(
                      plan: plan,
                      isActivating: _activatingPlanId == plan.id,
                      onTap: () => context.push('/training/${plan.id}'),
                      onActivate: () => _activatePlan(plan),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/training/new'),
        backgroundColor: context.appColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo Programa', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
