import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/core/widgets/liftr_confirm_dialog.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet_header.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/training/domain/constants/split_presets.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/export_plan_sheet.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/import_plan_sheet.dart';

class SwitchProgramSheet extends ConsumerStatefulWidget {
  const SwitchProgramSheet({
    super.key,
    required this.plans,
    this.embedded = false,
  });

  final List<TrainingPlan> plans;
  final bool embedded;

  static Future<void> show(
    BuildContext context, {
    required List<TrainingPlan> plans,
  }) {
    return showLiftrSheet<void>(
      context: context,
      isScrollable: false,
      heightFactor: 0.84,
      builder: (_) => SwitchProgramSheet(plans: plans, embedded: true),
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
        userFacingMessage(
          failure,
          context: 'SwitchProgramSheet._activatePlan',
        ),
        isError: true,
      ),
    );
  }

  Future<void> _createFromTemplate(SplitPreset template) async {
    if (_busyKey != null) return;
    final confirmed = await showLiftrConfirmDialog(
      context,
      title: 'Criar e ativar "${template.name}"?',
      message:
          'Um novo programa com ${template.sessions.length} sessões será criado e ativado. Seu histórico de cargas continua preservado.',
      confirmLabel: 'Criar e ativar',
      icon: Icons.fitness_center_rounded,
      isDestructive: false,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyKey = template.id);

    final createResult = await ref
        .read(createTrainingPlanUseCaseProvider)
        .execute(
          name: template.name,
          description: template.queueDescription,
          isActive: false,
        );

    await createResult.fold(
      (plan) async {
        final addWorkout = ref.read(addWorkoutToPlanUseCaseProvider);
        Failure? firstFailure;
        for (int i = 0; i < template.sessions.length; i++) {
          final addResult = await addWorkout.execute(
            trainingPlanId: plan.id,
            name: template.sessions[i],
            sortOrder: i,
            estimatedDurationMinutes: 50,
          );
          addResult.fold(
            (_) {},
            (failure) => firstFailure ??= failure,
          );
          if (firstFailure != null) break;
        }

        if (firstFailure != null) {
          await ref.read(deleteTrainingPlanUseCaseProvider).execute(plan.id);
          if (!mounted) return;
          context.showSnackBar(
            'Não foi possível criar o programa "${plan.name}". ${userFacingMessage(firstFailure!, context: 'SwitchProgramSheet._createFromTemplate')}',
            isError: true,
          );
          return;
        }

        final activateResult = await ref
            .read(setActiveTrainingPlanUseCaseProvider)
            .execute(plan.id);
        await activateResult.fold(
          (activated) async {
            ref.read(trainingPlansStateProvider.notifier).refresh();
            ref.invalidate(dashboardDataProvider);
            if (!mounted) return;
            context.showSnackBar(
              'Programa "${activated.name}" criado e ativado!',
            );
            Navigator.pop(context);
          },
          (activationFailure) async {
            await ref.read(deleteTrainingPlanUseCaseProvider).execute(plan.id);
            if (!mounted) return;
            context.showSnackBar(
              'Não foi possível criar o programa "${plan.name}". ${userFacingMessage(activationFailure, context: 'SwitchProgramSheet._createFromTemplate.activate')}',
              isError: true,
            );
          },
        );
      },
      (failure) async {
        if (!mounted) return;
        context.showSnackBar(
          userFacingMessage(
            failure,
            context: 'SwitchProgramSheet._createFromTemplate',
          ),
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
    final templates = SplitPresets.featuredTemplates;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiftrSheetHeader(
          title: 'Trocar programa',
          trailing: Semantics(
            label: 'Fechar seleção de programa',
            button: true,
            child: IconButton(
              tooltip: 'Fechar seleção de programa',
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
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
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
                  const SizedBox(height: 16),

                  // Quick AI + Import actions
                  Text(
                    'CRIAR COM IA OU IMPORTAR',
                    style: AppTypography.eyebrow(context),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                      context.push('/training/ai-generator');
                    },
                    backgroundColor: colors.primary.withValues(alpha: 0.12),
                    borderColor: colors.primary.withValues(alpha: 0.5),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: colors.primaryLight,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Montar treino com IA',
                                style: context.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Estudo rápido com Gemini para criar as sessões e séries no seu perfil',
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.primaryLight,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                      ImportPlanSheet.show(context);
                    },
                    backgroundColor: colors.surfaceElevated,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          color: colors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Importar treino por código',
                                style: context.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Cole um código LIFTR-PLAN-V1 compartilhado com você',
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (widget.plans.isNotEmpty) ...[
                    Text(
                      'SEUS PROGRAMAS',
                      style: AppTypography.eyebrow(context),
                    ),
                    const SizedBox(height: 8),
                    ...widget.plans.map((plan) {
                      final busy = _busyKey == plan.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (plan.isActive) {
                              Navigator.pop(context);
                              context.push('/training/${plan.id}');
                            } else {
                              _activatePlan(plan);
                            }
                          },
                          backgroundColor: plan.isActive
                              ? colors.primary.withValues(alpha: 0.1)
                              : colors.surfaceElevated,
                          borderColor: plan.isActive
                              ? colors.primary.withValues(alpha: 0.5)
                              : colors.border,
                          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                const LiftrBadge(
                                  label: 'Ativo',
                                  tone: LiftrBadgeTone.success,
                                )
                              else
                                Text(
                                  'Ativar',
                                  style: context.textTheme.labelMedium
                                      ?.copyWith(color: colors.primaryLight),
                                ),
                              Semantics(
                                label: 'Compartilhar ${plan.name}',
                                button: true,
                                child: IconButton(
                                  tooltip: 'Compartilhar ${plan.name}',
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    ExportPlanSheet.show(
                                      context,
                                      plan: plan,
                                    );
                                  },
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  icon: Icon(
                                    Icons.adaptive.share,
                                    size: 18,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  Text(
                    'MODELOS PRONTOS (2 A 6 DIAS)',
                    style: AppTypography.eyebrow(context),
                  ),
                  const SizedBox(height: 8),
                  ...templates.map((tpl) {
                    final busy = _busyKey == tpl.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        onTap: () => _createFromTemplate(tpl),
                        backgroundColor: colors.surfaceElevated,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        tpl.name,
                                        style: context.textTheme.titleSmall,
                                      ),
                                      LiftrBadge(
                                        label: '${tpl.daysPerWeek}×/sem',
                                        tone: LiftrBadgeTone.neutral,
                                      ),
                                      if (tpl.focusTag != null)
                                        LiftrBadge(
                                          label: tpl.focusTag!,
                                          tone: LiftrBadgeTone.brand,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tpl.queueDescription,
                                    style: context.textTheme.labelSmall
                                        ?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
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
                    );
                  }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
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
    );

    if (widget.embedded) {
      return body;
    }

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.84,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius.xl)),
        border: Border.all(color: colors.border),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: body,
        ),
      ),
    );
  }
}
