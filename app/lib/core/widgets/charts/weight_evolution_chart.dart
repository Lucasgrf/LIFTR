import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';

class WeightEvolutionChart extends StatefulWidget {
  const WeightEvolutionChart({
    super.key,
    required this.entries,
  });

  final List<WeightEntry> entries;

  @override
  State<WeightEvolutionChart> createState() => _WeightEvolutionChartState();
}

class _WeightEvolutionChartState extends State<WeightEvolutionChart> {
  int _selectedDays = 30; // 30, 60, 90, 0 (all)

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final now = DateTime.now();
    final cutoff = _selectedDays > 0
        ? now.subtract(Duration(days: _selectedDays))
        : DateTime.fromMillisecondsSinceEpoch(0);

    final filtered = widget.entries
        .where((e) => e.measuredAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    if (filtered.length < 2) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(colors),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Registre pelo menos 2 pesagens no período para visualizar o gráfico.',
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

    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (int i = 0; i < filtered.length; i++) {
      final entry = filtered[i];
      final val = entry.weightKg;
      spots.add(FlSpot(i.toDouble(), val));
      if (val < minY) minY = val;
      if (val > maxY) maxY = val;
    }

    final paddingY = math.max(1.0, (maxY - minY) * 0.2);
    minY = (minY - paddingY).clamp(0.0, double.infinity);
    maxY = maxY + paddingY;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Gráfico de evolução de peso corporal',
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors),
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
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: context.textTheme.labelSmall?.copyWith(
                              color: colors.textTertiary,
                              fontSize: 11,
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
                        interval: math.max(1.0, (filtered.length / 4).floorToDouble()),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < filtered.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                filtered[idx].measuredAt.formatShort(),
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: colors.textTertiary,
                                  fontSize: 11,
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
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: colors.primary,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: spots.length <= 15,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 3.5,
                          color: colors.primary,
                          strokeWidth: 1.5,
                          strokeColor: colors.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'EVOLUÇÃO DO PESO',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterChip('30d', 30),
            const SizedBox(width: 4),
            _buildFilterChip('60d', 60),
            const SizedBox(width: 4),
            _buildFilterChip('90d', 90),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int days) {
    final colors = context.appColors;
    final isSelected = _selectedDays == days;

    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: () => setState(() => _selectedDays = days),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
            ),
          ),
          child: Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: isSelected ? colors.onPrimary : colors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              fontFeatures: AppTypography.tabularFeatures,
            ),
          ),
        ),
      ),
    );
  }
}
