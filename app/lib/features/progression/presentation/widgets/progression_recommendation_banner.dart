import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/progression_recommendation.dart';
import 'package:personal_fitness_os/features/progression/presentation/widgets/progression_badge.dart';

class ProgressionRecommendationBanner extends StatelessWidget {
  const ProgressionRecommendationBanner({
    super.key,
    required this.recommendation,
  });

  final ProgressionRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    Color borderColor;
    switch (recommendation.type) {
      case ProgressionType.increase:
        borderColor = fitnessColors.progressUp.withOpacity(0.3);
        break;
      case ProgressionType.maintain:
        borderColor = colors.border;
        break;
      case ProgressionType.decrease:
        borderColor = fitnessColors.progressDown.withOpacity(0.3);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(context.appRadius.medium),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProgressionBadge(recommendation: recommendation),
              const SizedBox(width: 8),
              if (recommendation.previousSummary != null)
                Expanded(
                  child: Text(
                    'Anterior: ${recommendation.previousSummary}',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.rationale,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textPrimary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
