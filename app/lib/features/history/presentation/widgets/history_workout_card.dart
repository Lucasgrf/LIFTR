import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
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
          Row(
            children: [
              Text(
                dateStr,
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (session.mood != null) ...[
                WorkoutMoodChip(mood: session.mood!, compact: true),
                const SizedBox(width: 6),
              ],
              if (session.perceivedExertion != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.appSpacing.space8,
                    vertical: context.appSpacing.space2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(context.appRadius.small),
                  ),
                  child: Text(
                    'RPE ${session.perceivedExertion!.toStringAsFixed(1)}',
                    style: context.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            session.workoutName,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildMetricChip(
                context,
                icon: Icons.timer_rounded,
                label: '$minutes min',
                color: colors.textSecondary,
              ),
              const SizedBox(width: 12),
              _buildMetricChip(
                context,
                icon: Icons.checklist_rounded,
                label: '${session.totalWorkingSetsCount} séries',
                color: fitnessColors.progressNeutral,
              ),
              const SizedBox(width: 12),
              _buildMetricChip(
                context,
                icon: Icons.fitness_center_rounded,
                label: '${session.totalVolumeKg.toStringAsFixed(0)} kg',
                color: fitnessColors.progressUp,
              ),
              const Spacer(),
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
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
