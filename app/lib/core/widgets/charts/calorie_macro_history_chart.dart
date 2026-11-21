import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';

class CalorieMacroHistoryChart extends StatelessWidget {
  const CalorieMacroHistoryChart({
    super.key,
    required this.history,
    this.targetCalories,
  });

  final List<DailyNutrition> history;
  final double? targetCalories;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    final sorted = [...history]..sort((a, b) => a.date.compareTo(b.date));
    final displayItems = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;

    if (displayItems.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxY = targetCalories ?? 2500.0;
    for (final item in displayItems) {
      if (item.totalCalories > maxY) maxY = item.totalCalories;
    }
    maxY = (maxY * 1.15).ceilToDouble();

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < displayItems.length; i++) {
      final item = displayItems[i];
      final isTargetReached = targetCalories != null &&
          (item.totalCalories - targetCalories!).abs() <= 200;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: item.totalCalories,
              color: isTargetReached
                  ? fitnessColors.progressUp
                  : fitnessColors.progressMaintain,
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CONSUMO CALÓRICO (7 DIAS)',
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textSecondary,
                  letterSpacing: 1.1,
                ),
              ),
              if (targetCalories != null)
                Text(
                  'Meta: ${targetCalories!.round()} kcal',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colors.border.withValues(alpha: 0.4),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.textTertiary,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < displayItems.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              displayItems[idx].date.formatShort(),
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.textTertiary,
                                fontSize: 9,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
