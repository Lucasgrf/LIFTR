import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';

class SetTemplateRow extends StatelessWidget {
  const SetTemplateRow({
    required this.template,
    this.isCardio = false,
    this.onDelete,
    super.key,
  });

  final SetTemplate template;
  final bool isCardio;
  final VoidCallback? onDelete;

  static String getSetTypeBadge(SetTemplate template) {
    switch (template.setType) {
      case SetType.mobility:
        return 'MOB';
      case SetType.warmup:
        return 'AQ';
      case SetType.rampUp:
        return 'REC';
      case SetType.working:
        return '${template.setNumber}';
      case SetType.dropSet:
        return 'DROP';
      case SetType.myoRep:
        return 'MYO';
    }
  }

  static Color getSetTypeColor(BuildContext context, SetType type) {
    final colors = context.fitnessColors;
    final appColors = context.appColors;
    switch (type) {
      case SetType.mobility:
        return colors.progressNeutral;
      case SetType.warmup:
        return colors.progressMaintain;
      case SetType.rampUp:
        return appColors.info;
      case SetType.working:
        return colors.progressUp;
      case SetType.dropSet:
        return colors.dropSetTag;
      case SetType.myoRep:
        return appColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeText = getSetTypeBadge(template);
    final badgeColor = getSetTypeColor(context, template.setType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: context.appColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(context.appRadius.small),
        border: Border.all(
          color: context.appColors.border.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Set Type Badge
          Container(
            width: 38,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(context.appRadius.small),
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Text(
              badgeText,
              style: context.textTheme.labelSmall?.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Target Reps / Minutes
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCardio
                      ? '${template.repRangeText} min'
                      : '${template.repRangeText} reps',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isCardio && template.targetRirMin != null)
                  Text(
                    'RIR ${template.rirRangeText}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.appColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // Rest time
          if (!isCardio && template.restSeconds > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: context.appColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${template.restSeconds}s',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.appColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

          // Target Weight if present
          if (template.targetWeight != null && template.targetWeight! > 0) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.appColors.surfaceElevated,
                borderRadius: BorderRadius.circular(context.appRadius.small),
              ),
              child: Text(
                '${template.targetWeight!.toStringAsFixed(1)} kg',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.appColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],

          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.close_rounded, size: 16, color: context.appColors.textTertiary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}
