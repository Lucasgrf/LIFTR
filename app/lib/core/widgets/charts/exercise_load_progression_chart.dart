import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/history/domain/entities/exercise_history_record.dart';

class ExerciseLoadProgressionChart extends StatelessWidget {
  const ExerciseLoadProgressionChart({
    super.key,
    required this.records,
  });

  final List<ExerciseHistoryRecord> records;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    final sorted = [...records]..sort((a, b) => a.date.compareTo(b.date));

    if (sorted.length < 2) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Execute este exercício em pelo menos 2 sessões para visualizar a curva de força.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    }

    final topWeightSpots = <FlSpot>[];
    final e1rmSpots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (int i = 0; i < sorted.length; i++) {
      final rec = sorted[i];
      topWeightSpots.add(FlSpot(i.toDouble(), rec.topWeightKg));
      e1rmSpots.add(FlSpot(i.toDouble(), rec.bestEstimated1Rm));

      if (rec.topWeightKg < minY) minY = rec.topWeightKg;
      if (rec.bestEstimated1Rm > maxY) maxY = rec.bestEstimated1Rm;
    }

    final paddingY = math.max(2.0, (maxY - minY) * 0.2);
    minY = (minY - paddingY).clamp(0.0, double.infinity);
    maxY = maxY + paddingY;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colors.border.withValues(alpha: 0.5),
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
                          '${value.toStringAsFixed(0)}kg',
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
                      interval: math.max(1.0, (sorted.length / 4).floorToDouble()),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < sorted.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              sorted[idx].date.formatShort(),
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
                lineBarsData: [
                  // 1RM Estimado Line
                  LineChartBarData(
                    spots: e1rmSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: fitnessColors.progressUp,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: e1rmSpots.length <= 15,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: fitnessColors.progressUp,
                        strokeWidth: 1.5,
                        strokeColor: colors.surface,
                      ),
                    ),
                  ),
                  // Carga Máxima Line
                  LineChartBarData(
                    spots: topWeightSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: colors.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: topWeightSpots.length <= 15,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: colors.primary,
                        strokeWidth: 1.5,
                        strokeColor: colors.surface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'PROGRESSÃO DE CARGA',
          style: context.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        Row(
          children: [
            _buildLegendItem(colors.primary, 'Carga máx', context),
            const SizedBox(width: 8),
            _buildLegendItem(fitnessColors.progressUp, '1RM est', context),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.appColors.textTertiary,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
