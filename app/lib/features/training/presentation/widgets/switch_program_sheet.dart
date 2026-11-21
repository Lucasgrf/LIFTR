import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';

class _ProgramTemplate {
  const _ProgramTemplate({
    required this.name,
    required this.description,
    required this.sessions,
  });

  final String name;
  final String description;
  final List<String> sessions;
}

const List<_ProgramTemplate> _templates = [
  _ProgramTemplate(
    name: 'Full Body 3×',
    description: '3 sessões equilibradas de corpo inteiro por semana',
    sessions: ['Full Body A', 'Full Body B', 'Full Body C'],
  ),
  _ProgramTemplate(
    name: 'Upper / Lower 4×',
    description: '4 sessões alternando superiores e inferiores',
    sessions: ['Upper A', 'Lower A', 'Upper B', 'Lower B'],
  ),
  _ProgramTemplate(
    name: 'Push / Pull / Legs 6×',
    description: '6 sessões divididas por padrão de movimento',
    sessions: ['Push A', 'Pull A', 'Legs A', 'Push B', 'Pull B', 'Legs B'],
  ),
];

class SwitchProgramSheet extends ConsumerStatefulWidget {
  const SwitchProgramSheet({
    super.key,
    required this.plans,
  });

  final List<TrainingPlan> plans;

  static Future<void> show(
    BuildContext context, {
    required List<TrainingPlan> plans,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SwitchProgramSheet(plans: plans),
    );
  }

  @override
  ConsumerState<SwitchProgramSheet> createState() => _SwitchProgramSheetState();
}

class _SwitchProgramSheetState extends ConsumerState<SwitchProgramSheet> {
  String? _busyKey;

  Future<void> _activatePlan(TrainingPlan plan) async {
    if (plan.isActive || _busyKey != null) return;
    setState(() => _busyKey = plan.id);
    final result = await ref
        .read(setActiveTrainingPlanUseCaseProvider)
        .execute(plan.id);
    if (!mounted) return;
    setState(() => _busyKey = null);

    result.fold(
      (updated) {
        ref.read(trainingPlansStateProvider.notifier).refresh();
        ref.invalidate(dashboardDataProvider);
        context.showSnackBar('Programa "${updated.name}" ativado!');
        Navigator.pop(context);
      },
      (failure) => context.showSnackBar(
        'Erro ao ativar programa: ${failure.message}',
        isError: true,
      ),
    );
  }

  Future<void> _createFromTemplate(_ProgramTemplate template) async {
    if (_busyKey != null) return;
    setState(() => _busyKey = template.name);

    final createResult = await ref
        .read(createTrainingPlanUseCaseProvider)
        .execute(
          name: template.name,
          description: template.description,
          isActive: true,
        );

    await createResult.fold(
      (plan) async {
        final addWorkout = ref.read(addWorkoutToPlanUseCaseProvider);
        for (int i = 0; i < template.sessions.length; i++) {
          await addWorkout.execute(
            trainingPlanId: plan.id,
            name: template.sessions[i],
            sortOrder: i,
            estimatedDurationMinutes: 50,
          );
        }
        if (!mounted) return;
        ref.read(trainingPlansStateProvider.notifier).refresh();
        ref.invalidate(dashboardDataProvider);
        context.showSnackBar('Programa "${plan.name}" criado e ativado!');
        Navigator.pop(context);
      },
      (failure) async {
        if (!mounted) return;
        context.showSnackBar(
          'Erro ao criar programa: ${failure.message}',
          isError: true,
        );
      },
    );

    if (mounted) setState(() => _busyKey = null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final fitnessColors = context.fitnessColors;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.78,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius.xl)),
        border: Border.all(color: colors.border),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(radius.full),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Trocar programa',
                      style: context.textTheme.headlineMedium,
                    ),
                  ),
                  Semantics(
                    label: 'Fechar seleção de programa',
                    button: true,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  // Preserved history banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.primaryMuted,
                      borderRadius: BorderRadius.circular(radius.medium),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: colors.primaryLight,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Seu histórico de cargas e progressões é 100% preservado ao trocar de programa.',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (widget.plans.isNotEmpty) ...[
                    Text('SEUS PROGRAMAS', style: AppTypography.eyebrow(context)),
                    const SizedBox(height: 8),
                    ...widget.plans.map((plan) {
                      final busy = _busyKey == plan.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (plan.isActive) {
                              Navigator.pop(context);
                              context.push('/training/${plan.id}');
                            } else {
                              _activatePlan(plan);
                            }
                          },
                          borderRadius: BorderRadius.circular(radius.large),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: plan.isActive
                                  ? colors.primary.withValues(alpha: 0.1)
                                  : colors.surfaceElevated,
                              borderRadius:
                                  BorderRadius.circular(radius.large),
                              border: Border.all(
                                color: plan.isActive
                                    ? colors.primary.withValues(alpha: 0.5)
                                    : colors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plan.name,
                                        style: context.textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${plan.totalWorkoutsCount} sessões · ${plan.totalWeeklySetsCount} séries',
                                        style: context.textTheme.labelSmall
                                            ?.copyWith(
                                          color: colors.textSecondary,
                                          fontFeatures:
                                              AppTypography.tabularFeatures,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (busy)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else if (plan.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: fitnessColors.progressUp
                                          .withValues(alpha: 0.16),
                                      borderRadius:
                                          BorderRadius.circular(radius.full),
                                    ),
                                    child: Text(
                                      'Ativo',
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                        color: fitnessColors.progressUp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    'Ativar',
                                    style: context.textTheme.labelMedium
                                        ?.copyWith(color: colors.primaryLight),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  Text(
                    'MODELOS PRONTOS',
                    style: AppTypography.eyebrow(context),
                  ),
                  const SizedBox(height: 8),
                  ..._templates.map((tpl) {
                    final busy = _busyKey == tpl.name;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _createFromTemplate(tpl),
                        borderRadius: BorderRadius.circular(radius.large),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(radius.large),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tpl.name,
                                      style: context.textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      tpl.description,
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (busy)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: colors.primaryLight,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: AppButton.secondary(
                label: 'Criar programa personalizado',
                icon: Icons.add_rounded,
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/training/new');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
