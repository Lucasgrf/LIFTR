import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/weekly_stats.dart';

class WeeklyStreakWidget extends StatelessWidget {
  const WeeklyStreakWidget({
    super.key,
    required this.stats,
  });

  final WeeklyStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consistência Semanal',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                '${stats.completedWorkoutsCount}/${stats.targetWorkoutsCount} treinos',
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: stats.completedWorkoutsCount >= stats.targetWorkoutsCount
                      ? fitnessColors.progressUp
                      : colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 7 days circular streak row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stats.days.map((day) {
              final isDone = day.hasCompletedWorkout;
              final isToday = day.isToday;

              Color bg = colors.surfaceVariant;
              Color border = Colors.transparent;
              Widget iconOrText = Text(
                day.shortLabel,
                style: TextStyle(
                  color: isToday ? colors.primary : colors.textTertiary,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              );

              if (isDone) {
                bg = fitnessColors.progressUp;
                border = fitnessColors.progressUp;
                iconOrText = Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: fitnessColors.onSuccess,
                );
              } else if (isToday) {
                border = colors.primary;
              }

              return Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                      border: Border.all(color: border, width: isToday ? 2 : 1),
                    ),
                    child: iconOrText,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday ? colors.primary : colors.textTertiary,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
