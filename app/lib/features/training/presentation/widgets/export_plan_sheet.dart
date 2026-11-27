import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/utils/pt_br_copy_utils.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet_header.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/services/training_plan_share_codec.dart';

class ExportPlanSheet extends StatelessWidget {
  const ExportPlanSheet({
    super.key,
    required this.plan,
    this.embedded = false,
  });

  final TrainingPlan plan;
  final bool embedded;

  static Future<void> show(
    BuildContext context, {
    required TrainingPlan plan,
  }) {
    return showLiftrSheet<void>(
      context: context,
      maxHeightFactor: 0.82,
      builder: (_) => ExportPlanSheet(plan: plan, embedded: true),
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

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiftrSheetHeader(
          eyebrow: 'COMPARTILHAR PROGRAMA',
          title: plan.name,
          trailing: Semantics(
            label: 'Fechar compartilhamento',
            button: true,
            child: IconButton(
              tooltip: 'Fechar compartilhamento',
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
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            LiftrBadge(
              label: pluralize(plan.totalWorkoutsCount, 'sessão', 'sessões'),
              tone: LiftrBadgeTone.brand,
            ),
            LiftrBadge(
              label: pluralize(totalExercises, 'exercício', 'exercícios'),
              tone: LiftrBadgeTone.neutral,
            ),
            LiftrBadge(
              label:
                  '${plan.totalWeeklySetsCount} ${plan.totalWeeklySetsCount == 1 ? 'série/sem' : 'séries/sem'}',
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
                'Código do treino',
                style: context.textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
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
    );

    if (embedded) {
      return content;
    }

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
          child: content,
        ),
      ),
    );
  }
}
