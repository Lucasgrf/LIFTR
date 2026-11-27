import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_motion.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/charts/chart_models.dart';

class ExerciseLoadProgressionChart extends StatelessWidget {
  const ExerciseLoadProgressionChart({
    super.key,
    required this.series,
    this.title = 'PROGRESSÃO DE CARGA',
    this.emptyMessage =
        'Execute este exercício em pelo menos 2 sessões para visualizar a curva de força.',
    this.height = 180,
    this.referenceValue,
    this.referenceLabel,
  });

  final List<ChartSeries> series;
  final String title;
  final String emptyMessage;
  final double height;
  final double? referenceValue;
  final String? referenceLabel;

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  String _trendSemantics(List<ChartSeries> activeSeries) {
    if (activeSeries.isEmpty) return 'Gráfico de progressão de carga';
    final primary = activeSeries.first;
    if (primary.points.length < 2) {
      return 'Gráfico de progressão de carga';
    }
    final firstVal = primary.points.first.value;
    final lastVal = primary.points.last.value;
    final unit = primary.unit;
    final direction = lastVal > firstVal
        ? 'tendência de alta'
        : lastVal < firstVal
            ? 'tendência de queda'
            : 'estável';
    return 'Gráfico de progressão de carga: ${primary.label} de '
        '${_formatValue(firstVal)} $unit para ${_formatValue(lastVal)} $unit, '
        '$direction';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nonEmptySeries =
        series.where((s) => s.points.isNotEmpty).toList(growable: false);
    final maxPointsCount = nonEmptySeries.fold<int>(
      0,
      (prev, s) => s.points.length > prev ? s.points.length : prev,
    );

    if (maxPointsCount < 2) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, nonEmptySeries),
            const SizedBox(height: 24),
            Center(
              child: Text(
                emptyMessage,
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

    var minY = double.infinity;
    var maxY = -double.infinity;
    for (final item in nonEmptySeries) {
      for (final point in item.points) {
        if (point.value < minY) minY = point.value;
        if (point.value > maxY) maxY = point.value;
      }
    }
    if (referenceValue != null) {
      if (referenceValue! < minY) minY = referenceValue!;
      if (referenceValue! > maxY) maxY = referenceValue!;
    }

    final paddingY = math.max(2.0, (maxY - minY) * 0.2);
    minY = (minY - paddingY).clamp(0.0, double.infinity);
    maxY = maxY + paddingY;

    final primarySeries = nonEmptySeries.first;
    final primaryPoints = primarySeries.points;
    final unit = primarySeries.unit;

    // Render dashed secondary series beneath solid primary series when both exist.
    final orderedForPaint = [
      ...nonEmptySeries.where((s) => s.isDashed),
      ...nonEmptySeries.where((s) => !s.isDashed),
    ];

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: _trendSemantics(nonEmptySeries),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, nonEmptySeries),
            const SizedBox(height: 16),
            SizedBox(
              height: height,
              child: LineChart(
                duration:
                    context.appMotion.resolve(context, context.appMotion.fast),
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  extraLinesData: referenceValue != null
                      ? ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: referenceValue!,
                              color: colors.textSecondary.withValues(alpha: 0.6),
                              strokeWidth: 1,
                              dashArray: const [6, 4],
                              label: referenceLabel != null
                                  ? HorizontalLineLabel(
                                      show: true,
                                      alignment: Alignment.topRight,
                                      style:
                                          context.textTheme.labelSmall?.copyWith(
                                        color: colors.textSecondary,
                                        fontFeatures:
                                            AppTypography.tabularFeatures,
                                      ),
                                      labelResolver: (_) => referenceLabel!,
                                    )
                                  : null,
                            ),
                          ],
                        )
                      : const ExtraLinesData(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colors.border.withValues(alpha: 0.5),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => colors.surfaceElevated,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final s = orderedForPaint[spot.barIndex];
                          final idx = spot.x.toInt().clamp(
                                0,
                                s.points.length - 1,
                              );
                          final pt = s.points[idx];
                          final header = spot == touchedSpots.first
                              ? '${pt.date.formatShort()}\n'
                              : '';
                          return LineTooltipItem(
                            '$header${s.label}: ${_formatValue(pt.value)} ${s.unit}',
                            context.textTheme.labelSmall!.copyWith(
                              color: colors.textPrimary,
                              fontFeatures: AppTypography.tabularFeatures,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toStringAsFixed(0)} $unit',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: colors.textTertiary,
                              fontFeatures: AppTypography.tabularFeatures,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: math.max(
                          1.0,
                          (primaryPoints.length / 4).floorToDouble(),
                        ),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < primaryPoints.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                primaryPoints[idx].date.formatShort(),
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: colors.textTertiary,
                                  fontFeatures: AppTypography.tabularFeatures,
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
                  lineBarsData: orderedForPaint
                      .map(
                        (s) => LineChartBarData(
                          spots: [
                            for (int i = 0; i < s.points.length; i++)
                              FlSpot(i.toDouble(), s.points[i].value),
                          ],
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: s.color,
                          barWidth: s.isDashed ? 2 : 2.5,
                          dashArray: s.isDashed ? const [5, 4] : null,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: s.points.length <= 15,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: s.isDashed ? 3 : 3.5,
                              color: s.color,
                              strokeWidth: 1.5,
                              strokeColor: colors.surface,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<ChartSeries> activeSeries) {
    final colors = context.appColors;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          title,
          style: context.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        if (activeSeries.isNotEmpty)
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              for (final item in activeSeries)
                _buildLegendItem(
                  item.color,
                  item.label,
                  context,
                  dashed: item.isDashed,
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildLegendItem(
    Color color,
    String label,
    BuildContext context, {
    bool dashed = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 5, height: 2, color: color),
              const SizedBox(width: 2),
              Container(width: 5, height: 2, color: color),
            ],
          )
        else
          Container(
            width: 12,
            height: 2.5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
