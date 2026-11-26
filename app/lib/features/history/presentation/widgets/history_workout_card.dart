import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/workout_mood_icon.dart';

class HistoryWorkoutCard extends StatelessWidget {
  const HistoryWorkoutCard({
    super.key,
    required this.session,
    this.onTap,
  });

  final WorkoutSession session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    final date = session.completedAt ?? session.startedAt;
    final dateStr = DateFormat("d 'de' MMMM • HH:mm", 'pt_BR').format(date);
    final minutes = session.durationSeconds ~/ 60;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: context.appSpacing.space8,
              runSpacing: context.appSpacing.space4,
              children: [
                Text(
                  dateStr,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (session.mood != null || session.perceivedExertion != null)
                  Wrap(
                    spacing: context.appSpacing.space8,
                    runSpacing: context.appSpacing.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (session.mood != null)
                        WorkoutMoodChip(mood: session.mood!, compact: true),
                      if (session.perceivedExertion != null)
                        LiftrBadge(
                          label:
                              'RPE ${session.perceivedExertion!.toStringAsFixed(1)}',
                          tone: LiftrBadgeTone.brand,
                        ),
                    ],
                  ),
              ],
            ),
          ),
          AppSpacing.verticalGap8,

          Text(
            session.workoutName,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          AppSpacing.verticalGap12,

          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: context.appSpacing.space12,
                  runSpacing: context.appSpacing.space4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildMetricChip(
                      context,
                      icon: Icons.timer_rounded,
                      label: '$minutes min',
                      color: colors.textSecondary,
                    ),
                    _buildMetricChip(
                      context,
                      icon: Icons.checklist_rounded,
                      label: '${session.totalWorkingSetsCount} séries',
                      color: fitnessColors.progressNeutral,
                    ),
                    _buildMetricChip(
                      context,
                      icon: Icons.fitness_center_rounded,
                      label: '${session.totalVolumeKg.toStringAsFixed(0)} kg',
                      color: fitnessColors.progressUp,
                    ),
                  ],
                ),
              ),
              AppSpacing.horizontalGap8,
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.textTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
