import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';

class GoalProgressBar extends StatelessWidget {
  const GoalProgressBar({
    super.key,
    required this.goal,
  });

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    final progress = goal.progressPercentage;
    final percentText = '${(progress * 100).toStringAsFixed(0)}%';

    Color progressColor;
    if (goal.isCompleted) {
      progressColor = fitnessColors.progressUp;
    } else if (progress >= 0.75) {
      progressColor = fitnessColors.progressUp;
    } else if (progress >= 0.35) {
      progressColor = colors.primary;
    } else {
      progressColor = fitnessColors.progressMaintain;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso',
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            Text(
              percentText,
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(context.appRadius.full),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Início: ${goal.initialValue.toStringAsFixed(1)} ${goal.unit}',
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.textTertiary,
              ),
            ),
            Text(
              'Alvo: ${goal.targetValue.toStringAsFixed(1)} ${goal.unit}',
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
