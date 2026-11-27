import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_comparison_data.dart';

class WeeklySummaryCard extends StatelessWidget {
  const WeeklySummaryCard({
    super.key,
    required this.data,
    required this.onOpenComparison,
    required this.onLogCardio,
  });

  final WeeklyComparisonData data;
  final VoidCallback onOpenComparison;
  final VoidCallback onLogCardio;

  LiftrBadge _buildCardioBadge() {
    final delta = data.cardioDeltaSeconds;
    if (delta == null) {
      return const LiftrBadge(
        label: '1ª sem.',
        tone: LiftrBadgeTone.neutral,
      );
    }
    final deltaMinutes = (delta / 60).round();
    if (deltaMinutes > 0) {
      return LiftrBadge(
        label: formatCardioDeltaSeconds(delta),
        tone: LiftrBadgeTone.success,
      );
    }
    if (deltaMinutes < 0) {
      return LiftrBadge(
        label: formatCardioDeltaSeconds(delta),
        tone: LiftrBadgeTone.warning,
      );
    }
    return const LiftrBadge(
      label: 'Igual',
      tone: LiftrBadgeTone.neutral,
    );
  }

  LiftrBadge _buildWorkoutsBadge() {
    final delta = data.workoutsDelta;
    if (delta == null) {
      return const LiftrBadge(
        label: '1ª sem.',
        tone: LiftrBadgeTone.neutral,
      );
    }
    if (delta > 0) {
      return LiftrBadge(
        label: '+$delta',
        tone: LiftrBadgeTone.success,
      );
    }
    if (delta < 0) {
      return LiftrBadge(
        label: '$delta',
        tone: LiftrBadgeTone.warning,
      );
    }
    return const LiftrBadge(
      label: 'Igual',
      tone: LiftrBadgeTone.neutral,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final current = data.currentWeek;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label:
                'Resumo semanal, Cardio ${formatCardioSeconds(current.cardioDurationSeconds)}, ${current.workoutsCompleted} treinos. Toque para comparar semanas',
            button: true,
            child: InkWell(
              onTap: onOpenComparison,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(radius.large),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Resumo semanal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatWeekRange(current.weekStart),
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.textTertiary,
                            fontFeatures: AppTypography.tabularFeatures,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: colors.textTertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cardio',
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      formatCardioSeconds(
                                        current.cardioDurationSeconds,
                                      ),
                                      style: context.textTheme.titleLarge
                                          ?.copyWith(
                                        fontFeatures:
                                            AppTypography.tabularFeatures,
                                      ),
                                    ),
                                    _buildCardioBadge(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          VerticalDivider(width: 24, color: colors.divider),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Treinos',
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '${current.workoutsCompleted}',
                                      style: context.textTheme.titleLarge
                                          ?.copyWith(
                                        fontFeatures:
                                            AppTypography.tabularFeatures,
                                      ),
                                    ),
                                    _buildWorkoutsBadge(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.borderSubtle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Ver comparação semanal completa',
                    button: true,
                    child: InkWell(
                      onTap: onOpenComparison,
                      borderRadius: BorderRadius.circular(radius.small),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Comparar semana',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: 'Registrar cardio avulso',
                  button: true,
                  child: TextButton.icon(
                    onPressed: onLogCardio,
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text('Cardio'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: colors.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
