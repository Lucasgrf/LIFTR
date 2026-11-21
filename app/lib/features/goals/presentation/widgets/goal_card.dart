import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';
import 'package:personal_fitness_os/features/goals/presentation/widgets/goal_progress_bar.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.onTap,
  });

  final Goal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    Color statusBadgeColor;
    switch (goal.status) {
      case GoalStatus.active:
        statusBadgeColor = colors.primary;
        break;
      case GoalStatus.completed:
        statusBadgeColor = fitnessColors.progressUp;
        break;
      case GoalStatus.paused:
        statusBadgeColor = fitnessColors.progressMaintain;
        break;
      case GoalStatus.abandoned:
        statusBadgeColor = fitnessColors.progressDown;
        break;
    }

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(context.appRadius.small),
                ),
                child: Text(
                  goal.category.label.toUpperCase(),
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBadgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(context.appRadius.small),
                ),
                child: Text(
                  goal.status.label,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusBadgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            goal.title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          if (goal.description != null && goal.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              goal.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Value stats
          Row(
            children: [
              Text(
                'Atual: ',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Text(
                '${goal.currentValue.toStringAsFixed(1)} ${goal.unit}',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              if (goal.deadline != null) ...[
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  goal.deadline!.formatShort(),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          GoalProgressBar(goal: goal),
        ],
      ),
    );
  }
}
