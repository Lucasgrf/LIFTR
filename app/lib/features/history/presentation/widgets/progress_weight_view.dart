import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_icon.dart';
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
  double alpha = .25,
}) {
  if (entries.isEmpty) return const [];
  final sorted = [...entries]
    ..sort((first, second) => first.measuredAt.compareTo(second.measuredAt));
  final points = <WeightEmaPoint>[];
  var ema = sorted.first.weightKg;
  for (final entry in sorted) {
    ema = alpha * entry.weightKg + (1 - alpha) * ema;
    points.add(
      WeightEmaPoint(date: entry.measuredAt, rawKg: entry.weightKg, emaKg: ema),
    );
  }
  return points;
}

List<WeightEmaPoint> computeWindowedWeightEmaSeries(
  List<WeightEntry> entries, {
  required DateTime cutoff,
  double alpha = .25,
}) => computeWeightEmaSeries(
  entries,
  alpha: alpha,
).where((point) => !point.date.isBefore(cutoff)).toList();

class ProgressWeightView extends ConsumerStatefulWidget {
  const ProgressWeightView({super.key});

  @override
  ConsumerState<ProgressWeightView> createState() => _ProgressWeightViewState();
}

class _ProgressWeightViewState extends ConsumerState<ProgressWeightView> {
  int _selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final entriesAsync = ref.watch(weightHistoryProvider);
    final statsAsync = ref.watch(weightStatsProvider);
    final settings = ref.watch(userSettingsProvider);

    return entriesAsync.when(
      skipLoadingOnRefresh: entriesAsync.hasValue,
      skipError: entriesAsync.hasValue,
      loading: () => const LiftrScreenSkeleton(showHero: false, itemCount: 2),
      error: (error, stack) => ErrorStateWidget(
        message: userFacingMessage(
          error,
          stackTrace: stack,
          context: 'ProgressWeightView.build',
        ),
        onRetry: () {
          ref.invalidate(weightHistoryProvider);
          ref.invalidate(weightStatsProvider);
        },
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nenhuma pesagem registrada',
                style: context.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Registre seu peso para acompanhar a tendência e a faixa da sua meta.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              AppButton.primary(
                label: 'Registrar peso',
                onPressed: () => showProfileBodyDataSheet(
                  context,
                  settings,
                  forceRecordWeight: true,
                ),
              ),
            ],
          );
        }

        final now = ref.watch(appClockProvider)();
        final allPoints = computeWeightEmaSeries(entries);
        final cutoff = _selectedDays == 0
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : now.subtract(Duration(days: _selectedDays));
        final points = allPoints
            .where((point) => !point.date.isBefore(cutoff))
            .toList();
        final latest = allPoints.last.rawKg;
        final delta = statsAsync.asData?.value.deltaVsPreviousWeekKg ?? 0;
        final trend = delta.abs() < .1
            ? 'Estável.'
            : delta > 0
            ? 'Subindo ${delta.toStringAsFixed(2).replaceAll('.', ',')} kg nesta semana.'
            : 'Descendo ${delta.abs().toStringAsFixed(2).replaceAll('.', ',')} kg nesta semana.';
        final goalSentence = switch (settings.goal) {
          UserGoal.bulking =>
            'No bulking, o esperado é ganhar de 0,20 a 0,35 kg por semana.',
          UserGoal.cutting =>
            'No cutting, o esperado é perder de 0,35 a 0,50 kg por semana.',
          UserGoal.maintenance =>
            'Na manutenção, o esperado é variar de −0,10 a +0,10 kg por semana.',
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 19),
            Text(
              '${latest.toStringAsFixed(1).replaceAll('.', ',')} kg',
              style: context.textTheme.displayLarge?.copyWith(
                color: colors.primary,
                fontFeatures: AppTypography.tabularFeatures,
              ),
            ),
            const SizedBox(height: 12),
            Text('$trend $goalSentence', style: context.textTheme.bodyLarge),
            const SizedBox(height: 20),
            _PeriodSelector(
              selectedDays: _selectedDays,
              onChanged: (days) {
                HapticFeedback.selectionClick();
                setState(() => _selectedDays = days);
              },
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    points.length < 2
                        ? 'Falta uma pesagem para desenhar a linha'
                        : 'Seu peso ao longo do tempo',
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A faixa hachurada é onde você estaria seguindo a meta.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final chartWidth = constraints.maxWidth + 32;
                        return OverflowBox(
                          alignment: Alignment.centerLeft,
                          minWidth: chartWidth,
                          maxWidth: chartWidth,
                          child: Transform.translate(
                            offset: const Offset(-16, 0),
                            child: Semantics(
                              label:
                                  'Gráfico de peso, ${points.length} pesagens, tendência ${delta > .1
                                      ? 'de alta'
                                      : delta < -.1
                                      ? 'de queda'
                                      : 'estável'}',
                              child: CustomPaint(
                                size: Size(chartWidth, 120),
                                painter: _WeightGoalPainter(
                                  values: points
                                      .map((point) => point.rawKg)
                                      .toList(),
                                  ink: colors.primary,
                                  line: colors.divider,
                                  hatch: colors.textPrimary.withValues(
                                    alpha: .28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => showProfileBodyDataSheet(
                context,
                settings,
                forceRecordWeight: true,
              ),
              icon: const LiftrIcon(LiftrIconName.message, size: 20),
              label: const Text('Mandar peso pelo WhatsApp'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.textPrimary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selectedDays, required this.onChanged});

  final int selectedDays;
  final ValueChanged<int> onChanged;

  static const _periods = <(String, int)>[
    ('30 dias', 30),
    ('90 dias', 90),
    ('6 meses', 180),
    ('Tudo', 0),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        for (var index = 0; index < _periods.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              label: 'Período ${_periods[index].$1}',
              button: true,
              selected: selectedDays == _periods[index].$2,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => onChanged(_periods[index].$2),
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Ink(
                        decoration: BoxDecoration(
                          color: selectedDays == _periods[index].$2
                              ? colors.textPrimary
                              : colors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: SizedBox(
                          height: 44,
                          width: double.infinity,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _periods[index].$1,
                                style: context.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: selectedDays == _periods[index].$2
                                      ? colors.background
                                      : colors.textPrimary,
                                  fontFeatures: AppTypography.tabularFeatures,
                                ),
                              ),
                            ),
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
      ],
    );
  }
}

class _WeightGoalPainter extends CustomPainter {
  const _WeightGoalPainter({
    required this.values,
    required this.ink,
    required this.line,
    required this.hatch,
  });

  final List<double> values;
  final Color ink;
  final Color line;
  final Color hatch;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = line
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, 40), Offset(size.width, 40), gridPaint);
    canvas.drawLine(Offset(0, 80), Offset(size.width, 80), gridPaint);

    final target = Path()
      ..moveTo(0, size.height * .77)
      ..lineTo(size.width, size.height * .25)
      ..lineTo(size.width, size.height * .5)
      ..lineTo(0, size.height * .92)
      ..close();
    canvas.save();
    canvas.clipPath(target);
    final hatchPaint = Paint()
      ..color = hatch
      ..strokeWidth = 1.5;
    for (var x = -size.height; x < size.width + size.height; x += 6) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        hatchPaint,
      );
    }
    canvas.restore();

    final markerX = values.length < 2 ? size.width * .943 : size.width;
    final all = values.isEmpty ? const <double>[0] : values;
    final low = all.reduce(math.min);
    final high = all.reduce(math.max);
    final span = (high - low).abs() < .01 ? 1.0 : high - low;
    final points = <Offset>[];
    for (var i = 0; i < all.length; i++) {
      final x = all.length < 2 ? markerX : size.width * i / (all.length - 1);
      final normalized = (all[i] - low) / span;
      final y = all.length < 2 ? 52.0 : size.height * (.8 - normalized * .6);
      points.add(Offset(x, y));
    }
    final trendPaint = Paint()
      ..color = ink
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (points.length > 1) {
      final trend = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        trend.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(trend, trendPaint);
    }
    canvas.drawCircle(points.last, 6, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(covariant _WeightGoalPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.ink != ink ||
      oldDelegate.line != line ||
      oldDelegate.hatch != hatch;
}
