import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/workout_card_palette.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

class LastCompletedWorkoutCard extends StatelessWidget {
  const LastCompletedWorkoutCard({
    super.key,
    required this.session,
    this.previousSession,
    this.referenceNow,
    this.fichaColor,
    this.onTap,
  });

  final WorkoutSession session;
  final WorkoutSession? previousSession;
  final DateTime? referenceNow;
  final Color? fichaColor;
  final VoidCallback? onTap;

  String _formatDateLabel(DateTime date) {
    final now = referenceNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;
    final time = ptBrDateFormat('HH:mm').format(date);
    if (difference == 0) return 'hoje, $time';
    if (difference == 1) return 'ontem, $time';
    return '${ptBrDateFormat("d 'de' MMM").format(date)}, $time';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final completedAt = session.completedAt ?? session.startedAt;
    final minutes = math.max(1, session.durationSeconds ~/ 60);
    final targetSets = session.exercises
        .where((exercise) => !exercise.isCardio)
        .fold<int>(0, (sum, exercise) => sum + exercise.targetSetsCount);
    final setSummary = targetSets > 0
        ? '${session.totalWorkingSetsCount} de $targetSets séries'
        : '${session.totalWorkingSetsCount} séries';
    final volume = NumberFormat(
      '#,##0',
      'pt_BR',
    ).format(session.totalVolumeKg.round());
    final previous = previousSession;
    final comparison = previous == null
        ? null
        : session.totalVolumeKg - previous.totalVolumeKg > .5
        ? 'Acima da ${session.workoutName} anterior.'
        : previous.totalVolumeKg - session.totalVolumeKg > .5
        ? 'Abaixo da ${session.workoutName} anterior.'
        : 'Igual à ${session.workoutName} anterior.';

    return Semantics(
      button: true,
      label:
          'Abrir registro de ${session.workoutName}, ${_formatDateLabel(completedAt)}',
      child: InkWell(
        onTap: onTap ?? () => context.push('/session/${session.id}/summary'),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 16,
                height: 20,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color:
                      fichaColor ??
                      WorkoutCardPalette.forWorkout(session.workoutName),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.workoutName,
                            style: context.textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _formatDateLabel(completedAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                              fontFeatures: AppTypography.tabularFeatures,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '$setSummary em $minutes min, '),
                          TextSpan(
                            text: '$volume kg',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontFeatures: AppTypography.tabularFeatures,
                      ),
                    ),
                    if (comparison != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        comparison,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
