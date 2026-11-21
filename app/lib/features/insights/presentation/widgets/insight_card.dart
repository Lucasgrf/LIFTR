import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/insights/domain/entities/fitness_insight.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.insight,
    this.onTap,
  });

  final FitnessInsight insight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    final Color badgeColor;
    final IconData icon;

    switch (insight.severity) {
      case InsightSeverity.alert:
        badgeColor = fitnessColors.progressDown;
        icon = Icons.warning_amber_rounded;
        break;
      case InsightSeverity.warning:
        badgeColor = fitnessColors.progressMaintain;
        icon = Icons.lightbulb_outline_rounded;
        break;
      case InsightSeverity.success:
        badgeColor = fitnessColors.progressUp;
        icon = Icons.emoji_events_outlined;
        break;
      case InsightSeverity.info:
        badgeColor = fitnessColors.progressNeutral;
        icon = Icons.info_outline_rounded;
        break;
    }

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: badgeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
