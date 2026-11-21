import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/progression_recommendation.dart';

class ProgressionBadge extends StatelessWidget {
  const ProgressionBadge({
    super.key,
    required this.recommendation,
  });

  final ProgressionRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final fitnessColors = context.fitnessColors;

    Color color;
    IconData icon;
    String text;

    switch (recommendation.type) {
      case ProgressionType.increase:
        color = fitnessColors.progressUp;
        icon = Icons.trending_up_rounded;
        text = '+${recommendation.weightDeltaKg.toStringAsFixed(1)} kg';
        break;
      case ProgressionType.maintain:
        color = fitnessColors.progressMaintain;
        icon = Icons.trending_flat_rounded;
        text = 'Manter';
        break;
      case ProgressionType.decrease:
        color = fitnessColors.progressDown;
        icon = Icons.trending_down_rounded;
        text = '${recommendation.weightDeltaKg.toStringAsFixed(1)} kg';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(context.appRadius.small),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
