import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/utils/pt_br_copy_utils.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';

class WorkoutCard extends StatelessWidget {
  const WorkoutCard({
    required this.workout,
    this.onTap,
    super.key,
  });

  final Workout workout;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Day of Week indicator box
            Container(
              constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
              padding: EdgeInsets.all(context.appSpacing.space4),
              decoration: BoxDecoration(
                color: context.appColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(context.appRadius.small),
                border: Border.all(
                  color: context.appColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    size: 20,
                    color: context.appColors.primary,
                  ),
                  AppSpacing.verticalGap4,
                  Text(
                    workout.dayOfWeek != null ? _shortDay(workout.dayOfWeek!) : 'Livre',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.appColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.horizontalGap12,

            // Workout info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppSpacing.verticalGap4,
                  Wrap(
                    spacing: context.appSpacing.space8,
                    runSpacing: context.appSpacing.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        workout.dayOfWeekLabel,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.appColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '·',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.appColors.textTertiary,
                        ),
                      ),
                      Text(
                        pluralize(
                          workout.totalExercisesCount,
                          'exercício',
                          'exercícios',
                        ),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (workout.totalWorkingSetsCount > 0) ...[
                    AppSpacing.verticalGap4,
                    Text(
                      '${pluralize(workout.totalWorkingSetsCount, 'série', 'séries')} ${workout.totalWorkingSetsCount == 1 ? 'válida' : 'válidas'}',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.appColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: context.appColors.textTertiary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  String _shortDay(int day) {
    switch (day) {
      case 0:
        return 'DOM';
      case 1:
        return 'SEG';
      case 2:
        return 'TER';
      case 3:
        return 'QUA';
      case 4:
        return 'QUI';
      case 5:
        return 'SEX';
      case 6:
        return 'SÁB';
      default:
        return 'D$day';
    }
  }
}
