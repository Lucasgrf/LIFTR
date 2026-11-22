import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/services/training_plan_share_codec.dart';

class ExportPlanSheet extends StatelessWidget {
  const ExportPlanSheet({
    super.key,
    required this.plan,
  });

  final TrainingPlan plan;

  static Future<void> show(
    BuildContext context, {
    required TrainingPlan plan,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportPlanSheet(plan: plan),
    );
  }

  Future<void> _copyToClipboard(
    BuildContext context, {
    required String text,
    required String feedback,
  }) async {
    HapticFeedback.mediumImpact();
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    context.showSnackBar(feedback);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final shareCode = TrainingPlanShareCodec.encode(plan);
    final shareMessage = TrainingPlanShareCodec.buildShareMessage(plan);
    final totalExercises = plan.workouts.fold<int>(
      0,
      (sum, w) => sum + w.exercises.length,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius.xl)),
        border: Border.all(color: colors.border),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMPARTILHAR PROGRAMA',
                          style: AppTypography.eyebrow(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plan.name,
                          style: context.textTheme.headlineMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: 'Fechar compartilhamento',
                    button: true,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
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
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  LiftrBadge(
                    label: '${plan.totalWorkoutsCount} sessões',
                    tone: LiftrBadgeTone.brand,
                  ),
                  LiftrBadge(
                    label: '$totalExercises exercícios',
                    tone: LiftrBadgeTone.neutral,
                  ),
                  LiftrBadge(
                    label: '${plan.totalWeeklySetsCount} séries/sem',
                    tone: LiftrBadgeTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Envie este código para outra conta LIFTR (ex: seu irmão ou amigo). '
                'Todas as sessões, séries, faixas de repetições, descansos e exercícios '
                'personalizados serão recriados automaticamente.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(radius.medium),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CÓDIGO DO TREINO',
                      style: AppTypography.eyebrow(context),
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 96),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          shareCode,
                          key: const Key('export_plan_code_text'),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.textPrimary,
                            fontFeatures: AppTypography.tabularFeatures,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppButton.primary(
                label: 'Copiar mensagem para WhatsApp',
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: () => _copyToClipboard(
                  context,
                  text: shareMessage,
                  feedback: 'Mensagem com código copiada! Cole no WhatsApp.',
                ),
              ),
              const SizedBox(height: 10),
              AppButton.secondary(
                label: 'Copiar apenas o código',
                icon: Icons.copy_rounded,
                onPressed: () => _copyToClipboard(
                  context,
                  text: shareCode,
                  feedback: 'Código do treino copiado!',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
