import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/workout_mood_icon.dart';

class LastCompletedWorkoutCard extends StatelessWidget {
  const LastCompletedWorkoutCard({
    super.key,
    required this.session,
    this.referenceNow,
    this.onTap,
  });

  final WorkoutSession session;
  final DateTime? referenceNow;
  final VoidCallback? onTap;

  String _formatDateLabel(DateTime dt) {
    final now = referenceNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;
    final hm = DateFormat('HH:mm', 'pt_BR').format(dt);
    if (diff == 0) return 'Hoje · $hm';
    if (diff == 1) return 'Ontem · $hm';
    return DateFormat("d 'de' MMM · HH:mm", 'pt_BR').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final fitnessColors = context.fitnessColors;

    final completedAt = session.completedAt ?? session.startedAt;
    final minutes = math.max(1, session.durationSeconds ~/ 60);
    final volumeFormatted = NumberFormat('#,##0', 'pt_BR').format(
      session.totalVolumeKg.round(),
    );

    return InkWell(
      onTap: onTap ?? () => context.push('/session/${session.id}/summary'),
      borderRadius: BorderRadius.circular(radius.large),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radius.large),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: fitnessColors.progressUp.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(radius.xs),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: fitnessColors.progressUp,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    'ÚLTIMO TREINO REALIZADO',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.eyebrow(context),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: Text(
                    _formatDateLabel(completedAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                      fontFeatures: AppTypography.tabularFeatures,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.workoutName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium,
                  ),
                ),
                if (session.mood != null) ...[
                  const SizedBox(width: 6),
                  WorkoutMoodChip(mood: session.mood!, compact: true),
                ],
                if (session.executionScore != null) ...[
                  const SizedBox(width: 6),
                  LiftrBadge(
                    label: '${session.executionScore}%',
                    tone: session.executionScore! >= 85
                        ? LiftrBadgeTone.success
                        : LiftrBadgeTone.neutral,
                  ),
                ],
                if (session.perceivedExertion != null) ...[
                  const SizedBox(width: 6),
                  LiftrBadge(
                    label: 'RPE ${session.perceivedExertion!.toStringAsFixed(1)}',
                    tone: LiftrBadgeTone.brand,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _MetricPill(
                  icon: Icons.timer_rounded,
                  label: '$minutes min',
                  color: colors.textSecondary,
                ),
                _MetricPill(
                  icon: Icons.format_list_numbered_rounded,
                  label: '${session.totalWorkingSetsCount} séries',
                  color: colors.textSecondary,
                ),
                _MetricPill(
                  icon: Icons.fitness_center_rounded,
                  label: '$volumeFormatted kg',
                  color: fitnessColors.progressUp,
                ),
                if (session.totalCardioDurationSeconds > 0)
                  _MetricPill(
                    icon: Icons.directions_run_rounded,
                    label: formatCardioSeconds(
                      session.totalCardioDurationSeconds,
                    ),
                    color: colors.primaryLight,
                  ),
                if (session.totalExercisesCount > 0)
                  _MetricPill(
                    icon: Icons.layers_rounded,
                    label: '${session.totalExercisesCount} exerc.',
                    color: colors.textTertiary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontFeatures: AppTypography.tabularFeatures,
          ),
        ),
      ],
    );
  }
}
