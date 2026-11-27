import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_motion.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';
import 'package:personal_fitness_os/features/profile/presentation/screens/profile_screen.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';

class WeightEmaPoint {
  const WeightEmaPoint({
    required this.date,
    required this.rawKg,
    required this.emaKg,
  });

  final DateTime date;
  final double rawKg;
  final double emaKg;
}

List<WeightEmaPoint> computeWeightEmaSeries(
  List<WeightEntry> entries, {
  double alpha = 0.25,
}) {
  if (entries.isEmpty) return const [];
  final sorted = [...entries]
    ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

  final points = <WeightEmaPoint>[];
  var ema = sorted.first.weightKg;
  for (final entry in sorted) {
    ema = (alpha * entry.weightKg) + ((1.0 - alpha) * ema);
    points.add(
      WeightEmaPoint(
        date: entry.measuredAt,
        rawKg: entry.weightKg,
        emaKg: ema,
      ),
    );
  }
  return points;
}

/// Computes the EMA series across all historical [entries] first, then slices
/// points on or after [cutoff] so windowed trends preserve prior EMA seed state.
List<WeightEmaPoint> computeWindowedWeightEmaSeries(
  List<WeightEntry> entries, {
  required DateTime cutoff,
  double alpha = 0.25,
}) {
  final fullSeries = computeWeightEmaSeries(entries, alpha: alpha);
  return fullSeries.where((p) => !p.date.isBefore(cutoff)).toList();
}

class ProgressWeightView extends ConsumerStatefulWidget {
  const ProgressWeightView({super.key});

  @override
  ConsumerState<ProgressWeightView> createState() => _ProgressWeightViewState();
}

class _ProgressWeightViewState extends ConsumerState<ProgressWeightView> {
  int _selectedDays = 30; // 30, 90, 180, 0 (All)

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final historyAsync = ref.watch(weightHistoryProvider);
    final statsAsync = ref.watch(weightStatsProvider);
    final settings = ref.watch(userSettingsProvider);

    return historyAsync.when(
      skipLoadingOnRefresh: true,
      skipError: true,
      loading: () => const LiftrScreenSkeleton(showHero: false, itemCount: 2),
      error: (err, st) => ErrorStateWidget(
        message: userFacingMessage(
          err,
          stackTrace: st,
          context: 'ProgressWeightView.build',
        ),
        onRetry: () {
          ref.invalidate(weightHistoryProvider);
          ref.invalidate(weightStatsProvider);
        },
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.monitor_weight_outlined,
            title: 'Nenhuma pesagem registrada',
            subtitle:
                'Atualize seu peso em Perfil → Dados corporais para acompanhar sua curva de tendência.',
            actionLabel: 'Atualizar peso',
            onAction: () => showProfileBodyDataSheet(
              context,
              settings,
              forceRecordWeight: true,
            ),
          );
        }

        final now = ref.watch(appClockProvider)();
        final cutoff = _selectedDays > 0
            ? now.subtract(Duration(days: _selectedDays))
            : DateTime.fromMillisecondsSinceEpoch(0);
        final allSeries = computeWeightEmaSeries(entries);
        final series = _selectedDays > 0
            ? allSeries.where((p) => !p.date.isBefore(cutoff)).toList()
            : allSeries;

        final currentEma = allSeries.last.emaKg;
        final deltaPerWeek = statsAsync.asData?.value.deltaVsPreviousWeekKg ?? 0.0;
        final rateSign = deltaPerWeek >= 0 ? '+' : '';
        final rateText =
            'Ritmo: $rateSign${deltaPerWeek.toStringAsFixed(2).replaceAll('.', ',')} kg/sem';

        return AppCard(
          borderRadius: radius.xl,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TENDÊNCIA EMA ATUAL', style: AppTypography.eyebrow(context)),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  text: currentEma.toStringAsFixed(1).replaceAll('.', ','),
                  style: context.textTheme.displayLarge,
                  children: [
                    TextSpan(
                      text: ' kg',
                      style: context.textTheme.titleLarge?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  LiftrBadge(
                    label: rateText,
                    tone: LiftrBadgeTone.brand,
                  ),
                  LiftrBadge(
                    label:
                        'Alvo (${settings.goal.label}): ${settings.goal.weeklyRateTargetLabel}',
                    tone: LiftrBadgeTone.success,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Period pills
              Wrap(
                spacing: context.appSpacing.space8,
                runSpacing: context.appSpacing.space8,
                children: [
                  for (final option in const [
                    ('30D', 30),
                    ('90D', 90),
                    ('6M', 180),
                    ('Tudo', 0),
                  ])
                    Semantics(
                      label: 'Período ${option.$1}',
                      button: true,
                      selected: _selectedDays == option.$2,
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedDays = option.$2);
                          },
                          borderRadius: BorderRadius.circular(radius.xs),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: _selectedDays == option.$2
                                  ? colors.primary
                                  : colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(radius.xs),
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.appSpacing.space12,
                                ),
                                child: Center(
                                  widthFactor: 1,
                                  child: Text(
                                    option.$1,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        context.textTheme.labelSmall?.copyWith(
                                      color: _selectedDays == option.$2
                                          ? colors.onPrimary
                                          : colors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures:
                                          AppTypography.tabularFeatures,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: context.appSpacing.space16),

              if (series.length < 2)
                Container(
                  height: 170,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(radius.medium),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Envie pelo menos 2 pesagens no período pelo WhatsApp para visualizar a curva EMA.',
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 224,
                  child: _WeightEmaChart(series: series),
                ),

              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 14),
              Text(
                'Envie seu peso pelo WhatsApp pela manhã para manter a tendência atualizada.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeightEmaChart extends StatelessWidget {
  const _WeightEmaChart({required this.series});

  final List<WeightEmaPoint> series;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final rawSpots = <FlSpot>[];
    final emaSpots = <FlSpot>[];
    var minY = double.infinity;
    var maxY = -double.infinity;

    for (int i = 0; i < series.length; i++) {
      final p = series[i];
      rawSpots.add(FlSpot(i.toDouble(), p.rawKg));
      emaSpots.add(FlSpot(i.toDouble(), p.emaKg));
      minY = math.min(minY, math.min(p.rawKg, p.emaKg));
      maxY = math.max(maxY, math.max(p.rawKg, p.emaKg));
    }

    final pad = math.max(0.8, (maxY - minY) * 0.25);
    minY = (minY - pad).clamp(0.0, double.infinity);
    maxY = maxY + pad;

    final startEma = series.first.emaKg;
    final endEma = series.last.emaKg;
    final trendDirection = endEma > startEma
        ? 'tendência de alta'
        : endEma < startEma
            ? 'tendência de queda'
            : 'estável';
    final semanticsLabel =
        'Gráfico de tendência EMA de peso: média móvel de '
        '${startEma.toStringAsFixed(1).replaceAll('.', ',')} kg para '
        '${endEma.toStringAsFixed(1).replaceAll('.', ',')} kg, $trendDirection';

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticsLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.textTertiary.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Peso',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Média móvel (EMA)',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(
              duration:
                  context.appMotion.resolve(context, context.appMotion.fast),
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colors.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => colors.surfaceElevated,
                    getTooltipItems: (touchedSpots) {
                      var emitted = false;
                      return touchedSpots.map((spot) {
                        if (emitted) return null;
                        emitted = true;
                        final idx = spot.x.toInt().clamp(0, series.length - 1);
                        final point = series[idx];
                        final rawStr = point.rawKg
                            .toStringAsFixed(1)
                            .replaceAll('.', ',');
                        final emaStr = point.emaKg
                            .toStringAsFixed(1)
                            .replaceAll('.', ',');
                        return LineTooltipItem(
                          '${point.date.formatShort()}\n'
                          'Peso bruto: $rawStr kg\n'
                          'EMA: $emaStr kg',
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
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 54,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toStringAsFixed(1).replaceAll('.', ',')} kg',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.textTertiary,
                          fontFeatures: AppTypography.tabularFeatures,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: math.max(1.0, (series.length / 4).floorToDouble()),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < series.length) {
                          return Padding(
                            padding:
                                EdgeInsets.only(top: context.appSpacing.space8),
                            child: Text(
                              series[idx].date.formatShort(),
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
                lineBarsData: [
                  // Raw daily scatter dots
                  LineChartBarData(
                    spots: rawSpots,
                    barWidth: 0,
                    color: Colors.transparent,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: colors.textTertiary.withValues(alpha: 0.45),
                        strokeWidth: 0,
                      ),
                    ),
                  ),
                  // Smooth EMA trend curve
                  LineChartBarData(
                    spots: emaSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: colors.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
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
    );
  }
}
