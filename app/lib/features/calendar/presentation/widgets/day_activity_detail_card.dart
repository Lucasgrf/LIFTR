import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/calendar/domain/entities/day_activity_summary.dart';

class DayActivityDetailCard extends StatelessWidget {
  const DayActivityDetailCard({
    super.key,
    required this.summary,
  });

  final DayActivitySummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    final session = summary.workoutSession;
    final weight = summary.weightEntry;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                summary.date.formatFull(),
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              if (summary.hasWorkout || summary.hasWeight)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: fitnessColors.progressUp.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(context.appRadius.small),
                  ),
                  child: Text(
                    'Ativo',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: fitnessColors.progressUp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(context.appRadius.small),
                  ),
                  child: Text(
                    'Descanso',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Workout Info
          if (session != null) ...[
            InkWell(
              onTap: () => context.push('/session/${session.id}/summary'),
              borderRadius: BorderRadius.circular(context.appRadius.small),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(context.appRadius.small),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.fitness_center_rounded, color: colors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.workoutName ?? 'Treino Realizado',
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '${session.formattedDuration} • ${session.totalVolumeKg.round()} kg volume',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: colors.textTertiary, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ] else ...[
            Text(
              'Nenhum treino registrado neste dia.',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Weight Info
          if (weight != null) ...[
            Row(
              children: [
                Icon(Icons.monitor_weight_outlined, size: 18, color: fitnessColors.progressMaintain),
                const SizedBox(width: 8),
                Text(
                  'Peso: ${weight.weightKg.toStringAsFixed(1)} kg',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
