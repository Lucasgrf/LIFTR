import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_stats.dart';

class WeightStatsSummaryCard extends StatelessWidget {
  const WeightStatsSummaryCard({
    super.key,
    required this.stats,
    this.onTapHistory,
  });

  final WeightStats stats;
  final VoidCallback? onTapHistory;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    Color trendColor;
    switch (stats.trend) {
      case WeightTrend.gaining:
        trendColor = fitnessColors.progressUp;
        break;
      case WeightTrend.losing:
        trendColor = fitnessColors.progressDown;
        break;
      case WeightTrend.maintaining:
        trendColor = fitnessColors.progressMaintain;
        break;
      case WeightTrend.unknown:
        trendColor = colors.textTertiary;
        break;
    }

    return AppCard(
      onTap: onTapHistory,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PESO CORPORAL',
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textSecondary,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(context.appRadius.small),
                  border: Border.all(color: trendColor.withOpacity(0.4)),
                ),
                child: Text(
                  stats.trendLabel,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main weight display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                stats.currentWeightKg != null
                    ? stats.currentWeightKg!.toStringAsFixed(1)
                    : '--.-',
                style: context.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'kg',
                style: context.textTheme.titleMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              if (stats.deltaVsPreviousWeekKg != null)
                Text(
                  '${stats.deltaVsPreviousWeekKg! > 0 ? '+' : ''}${stats.deltaVsPreviousWeekKg!.toStringAsFixed(1)} kg / sem',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Moving averages grid
          Row(
            children: [
              Expanded(
                child: _AverageColumn(
                  title: 'Média 7d',
                  value: stats.average7Days != null
                      ? '${stats.average7Days!.toStringAsFixed(1)} kg'
                      : '--',
                ),
              ),
              Expanded(
                child: _AverageColumn(
                  title: 'Média 14d',
                  value: stats.average14Days != null
                      ? '${stats.average14Days!.toStringAsFixed(1)} kg'
                      : '--',
                ),
              ),
              Expanded(
                child: _AverageColumn(
                  title: 'Média 30d',
                  value: stats.average30Days != null
                      ? '${stats.average30Days!.toStringAsFixed(1)} kg'
                      : '--',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AverageColumn extends StatelessWidget {
  const _AverageColumn({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.labelSmall?.copyWith(
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
