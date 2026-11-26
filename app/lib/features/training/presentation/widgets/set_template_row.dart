import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
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
    final spacing = context.appSpacing;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.space12,
        vertical: spacing.space8,
      ),
      margin: EdgeInsets.only(bottom: spacing.space8),
      decoration: BoxDecoration(
        color: context.appColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(context.appRadius.small),
        border: Border.all(
          color: context.appColors.border.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 290;
          final hasMeta = (!isCardio && template.restSeconds > 0) ||
              (template.targetWeight != null && template.targetWeight! > 0);

          final metaWrap = Wrap(
            spacing: spacing.space12,
            runSpacing: spacing.space4,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              if (!isCardio && template.restSeconds > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      size: 14,
                      color: context.appColors.textTertiary,
                    ),
                    SizedBox(width: spacing.space4),
                    Flexible(
                      child: Text(
                        '${template.restSeconds}s',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.appColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              if (template.targetWeight != null && template.targetWeight! > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.space8,
                    vertical: spacing.space4,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceElevated,
                    borderRadius:
                        BorderRadius.circular(context.appRadius.small),
                  ),
                  child: Text(
                    '${template.targetWeight!.toStringAsFixed(1)} kg',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.appColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          );

          return Row(
            children: [
              // Set Type Badge
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 38, minHeight: 24),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: spacing.space4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(context.appRadius.small),
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
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacing.space12),

              // Target Reps / Minutes
              Expanded(
                flex: isCompact ? 1 : 3,
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
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    if (isCompact && hasMeta) ...[
                      SizedBox(height: spacing.space4),
                      metaWrap,
                    ],
                  ],
                ),
              ),

              if (!isCompact && hasMeta) ...[
                SizedBox(width: spacing.space8),
                Flexible(
                  flex: 2,
                  child: metaWrap,
                ),
              ],

              if (onDelete != null) ...[
                SizedBox(width: spacing.space4),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: context.appColors.textTertiary,
                  ),
                  tooltip: 'Remover série',
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: onDelete,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
