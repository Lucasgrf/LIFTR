import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/cardio_log.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_comparison_data.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_snapshot.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/providers/weekly_comparison_providers.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/widgets/log_cardio_modal.dart';

class WeeklyComparisonScreen extends ConsumerWidget {
  const WeeklyComparisonScreen({super.key});

  String _offsetTitle(int offset) {
    if (offset == 0) return 'Esta semana';
    if (offset == -1) return 'Semana passada';
    return 'Há ${offset.abs()} semanas';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final offset = ref.watch(weeklyComparisonOffsetProvider);
    final comparisonAsync = ref.watch(weeklyComparisonProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Comparação semanal'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              label: 'Registrar cardio',
              button: true,
              child: TextButton.icon(
                onPressed: () => LogCardioModal.show(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Cardio'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: colors.primaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
      body: comparisonAsync.when(
        loading: () => const SafeArea(child: LiftrScreenSkeleton()),
        error: (err, st) => ErrorStateWidget(
          message: userFacingMessage(
            err,
            stackTrace: st,
            context: 'WeeklyComparisonScreen.build',
          ),
          safetyNote: offlineSafetyNoteFor(err),
          onRetry: () => ref.invalidate(weeklyComparisonProvider),
        ),
        data: (data) {
          final current = data.currentWeek;
          final previous = data.previousWeek;
          final volumeFormat = NumberFormat('#,##0', 'pt_BR');

          return RefreshIndicator(
            color: colors.primary,
            onRefresh: () => ref.refresh(weeklyComparisonProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 36),
              children: [
                ResponsiveContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Week Navigator Strip
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Semantics(
                              label: 'Semana anterior',
                              button: true,
                              child: IconButton(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  ref
                                      .read(
                                        weeklyComparisonOffsetProvider.notifier,
                                      )
                                      .state = offset - 1;
                                },
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                icon: Icon(
                                  Icons.chevron_left_rounded,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    _offsetTitle(offset),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatWeekRange(current.weekStart),
                                    style: context.textTheme.labelSmall
                                        ?.copyWith(
                                      color: colors.textSecondary,
                                      fontFeatures:
                                          AppTypography.tabularFeatures,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Semantics(
                              label: 'Próxima semana',
                              button: true,
                              child: IconButton(
                                onPressed: offset < 0
                                    ? () {
                                        HapticFeedback.selectionClick();
                                        ref
                                            .read(
                                              weeklyComparisonOffsetProvider
                                                  .notifier,
                                            )
                                            .state = offset + 1;
                                      }
                                    : null,
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                icon: Icon(
                                  Icons.chevron_right_rounded,
                                  color: offset < 0
                                      ? colors.textPrimary
                                      : colors.textDisabled,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Hero Cardio Weekly Card + 7-day Breakdown
                      _HeroCardioCard(
                        data: data,
                        onDeleteStandalone: (log) async {
                          final repo =
                              ref.read(weeklyComparisonRepositoryProvider);
                          await repo.deleteStandaloneCardio(log.id);
                          ref.invalidate(weeklyComparisonProvider);
                          ref.invalidate(currentWeekSummaryProvider);
                          ref.invalidate(dashboardDataProvider);
                          if (context.mounted) {
                            context.showSnackBar('Cardio removido.');
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // 3. Weekly Comparison Matrix
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Comparativo semanal',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.titleMedium,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  flex: 2,
                                  child: Text(
                                    previous != null
                                        ? 'ATUAL VS ANTERIOR'
                                        : 'BASELINE INICIAL',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: AppTypography.eyebrow(context),
                                  ),
                                ),
                              ],
                            ),
                            if (previous == null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Primeira semana registrada neste período. Conforme você treinar nas próximas semanas, a comparação aparecerá aqui.',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            _ComparisonRow(
                              label: 'Treinos concluídos',
                              currentValue: '${current.workoutsCompleted}',
                              previousValue: previous != null
                                  ? '${previous.workoutsCompleted}'
                                  : '—',
                              deltaBadge: _intDeltaBadge(data.workoutsDelta),
                            ),
                            Divider(height: 18, color: colors.borderSubtle),
                            _ComparisonRow(
                              label: 'Cardio total',
                              currentValue: formatCardioSeconds(
                                current.cardioDurationSeconds,
                              ),
                              previousValue: previous != null
                                  ? formatCardioSeconds(
                                      previous.cardioDurationSeconds,
                                    )
                                  : '—',
                              deltaBadge:
                                  _durationDeltaBadge(data.cardioDeltaSeconds),
                            ),
                            Divider(height: 18, color: colors.borderSubtle),
                            _ComparisonRow(
                              label: 'Tempo de treino',
                              currentValue: formatCardioSeconds(
                                current.trainingDurationSeconds,
                              ),
                              previousValue: previous != null
                                  ? formatCardioSeconds(
                                      previous.trainingDurationSeconds,
                                    )
                                  : '—',
                              deltaBadge: _durationDeltaBadge(
                                data.trainingDurationDeltaSeconds,
                              ),
                            ),
                            Divider(height: 18, color: colors.borderSubtle),
                            _ComparisonRow(
                              label: 'Séries válidas',
                              currentValue: '${current.workingSetsCount}',
                              previousValue: previous != null
                                  ? '${previous.workingSetsCount}'
                                  : '—',
                              deltaBadge:
                                  _intDeltaBadge(data.workingSetsDelta),
                            ),
                            Divider(height: 18, color: colors.borderSubtle),
                            _ComparisonRow(
                              label: 'Volume total',
                              currentValue:
                                  '${volumeFormat.format(current.totalVolumeKg.round())} kg',
                              previousValue: previous != null
                                  ? '${volumeFormat.format(previous.totalVolumeKg.round())} kg'
                                  : '—',
                              deltaBadge: _volumeDeltaBadge(
                                data.volumeDeltaKg,
                                volumeFormat,
                              ),
                            ),
                            Divider(height: 18, color: colors.borderSubtle),
                            _ComparisonRow(
                              label: 'RPE médio (auto)',
                              currentValue: current.avgRpe != null
                                  ? current.avgRpe!
                                      .toStringAsFixed(1)
                                      .replaceAll('.', ',')
                                  : '—',
                              previousValue: previous?.avgRpe != null
                                  ? previous!.avgRpe!
                                      .toStringAsFixed(1)
                                      .replaceAll('.', ',')
                                  : '—',
                              deltaBadge: _doubleDeltaBadge(
                                data.avgRpeDelta,
                                neutralOnly: true,
                              ),
                            ),
                            Divider(height: 18, color: colors.borderSubtle),
                            _ComparisonRow(
                              label: 'Score de execução',
                              currentValue: current.avgExecutionScore != null
                                  ? '${current.avgExecutionScore!.round()}%'
                                  : '—',
                              previousValue: previous?.avgExecutionScore != null
                                  ? '${previous!.avgExecutionScore!.round()}%'
                                  : '—',
                              deltaBadge: _doubleDeltaBadge(
                                data.avgExecutionScoreDelta,
                                suffix: '%',
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (data.recentWeeksHistory.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _WeeklyHistorySection(
                          snapshots: data.recentWeeksHistory,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static LiftrBadge? _intDeltaBadge(int? delta) {
    if (delta == null) return null;
    if (delta > 0) {
      return LiftrBadge(label: '+$delta', tone: LiftrBadgeTone.success);
    }
    if (delta < 0) {
      return LiftrBadge(label: '$delta', tone: LiftrBadgeTone.warning);
    }
    return const LiftrBadge(label: 'Igual', tone: LiftrBadgeTone.neutral);
  }

  static LiftrBadge? _durationDeltaBadge(int? deltaSeconds) {
    if (deltaSeconds == null) return null;
    final mins = (deltaSeconds / 60).round();
    if (mins > 0) {
      return LiftrBadge(
        label: formatCardioDeltaSeconds(deltaSeconds),
        tone: LiftrBadgeTone.success,
      );
    }
    if (mins < 0) {
      return LiftrBadge(
        label: formatCardioDeltaSeconds(deltaSeconds),
        tone: LiftrBadgeTone.warning,
      );
    }
    return const LiftrBadge(label: 'Igual', tone: LiftrBadgeTone.neutral);
  }

  static LiftrBadge? _volumeDeltaBadge(
    double? deltaKg,
    NumberFormat fmt,
  ) {
    if (deltaKg == null) return null;
    final rounded = deltaKg.round();
    if (rounded > 0) {
      return LiftrBadge(
        label: '+${fmt.format(rounded)} kg',
        tone: LiftrBadgeTone.success,
      );
    }
    if (rounded < 0) {
      return LiftrBadge(
        label: '${fmt.format(rounded)} kg',
        tone: LiftrBadgeTone.warning,
      );
    }
    return const LiftrBadge(label: 'Igual', tone: LiftrBadgeTone.neutral);
  }

  static LiftrBadge? _doubleDeltaBadge(
    double? delta, {
    String suffix = '',
    bool neutralOnly = false,
  }) {
    if (delta == null) return null;
    if (delta == 0) {
      return const LiftrBadge(label: 'Igual', tone: LiftrBadgeTone.neutral);
    }
    final sign = delta > 0 ? '+' : '';
    final formatted = delta.toStringAsFixed(1).replaceAll('.', ',');
    final tone = neutralOnly
        ? LiftrBadgeTone.neutral
        : (delta > 0 ? LiftrBadgeTone.success : LiftrBadgeTone.warning);
    return LiftrBadge(label: '$sign$formatted$suffix', tone: tone);
  }
}

class _HeroCardioCard extends StatelessWidget {
  const _HeroCardioCard({
    required this.data,
    required this.onDeleteStandalone,
  });

  final WeeklyComparisonData data;
  final Future<void> Function(CardioLog log) onDeleteStandalone;

  static const List<String> _weekdayInitials = [
    'S',
    'T',
    'Q',
    'Q',
    'S',
    'S',
    'D',
  ];

  static const List<String> _weekdayFullNames = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final current = data.currentWeek;
    final previous = data.previousWeek;
    final deltaSec = data.cardioDeltaSeconds;

    final maxMinutes = data.currentWeekDailyCardio.fold<int>(
      30,
      (m, d) => math.max(m, d.totalMinutes),
    );

    final LiftrBadge deltaBadge;
    if (deltaSec == null) {
      deltaBadge = const LiftrBadge(
        label: 'Primeira semana',
        tone: LiftrBadgeTone.neutral,
      );
    } else if ((deltaSec / 60).round() > 0) {
      deltaBadge = LiftrBadge(
        label: '${formatCardioDeltaSeconds(deltaSec)} vs ant.',
        tone: LiftrBadgeTone.success,
      );
    } else if ((deltaSec / 60).round() < 0) {
      deltaBadge = LiftrBadge(
        label: '${formatCardioDeltaSeconds(deltaSec)} vs ant.',
        tone: LiftrBadgeTone.warning,
      );
    } else {
      deltaBadge = const LiftrBadge(
        label: 'Igual à anterior',
        tone: LiftrBadgeTone.neutral,
      );
    }

    return AppCard(
      borderRadius: radius.xl,
      borderColor: colors.primary.withValues(alpha: 0.38),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'CARDIO NA SEMANA',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.eyebrow(context),
              ),
              deltaBadge,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatCardioSeconds(current.cardioDurationSeconds),
            style: context.textTheme.displayMedium?.copyWith(
              color: colors.primaryLight,
              fontFeatures: AppTypography.tabularFeatures,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            previous != null
                ? 'Semana anterior: ${formatCardioSeconds(previous.cardioDurationSeconds)}'
                : 'Primeira semana registrada — a comparação aparecerá na próxima semana.',
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontFeatures: AppTypography.tabularFeatures,
            ),
          ),
          AppSpacing.verticalGap16,
          LayoutBuilder(
            builder: (context, constraints) {
              final minColumnWidth = constraints.maxWidth / 7;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    minHeight: 102,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (idx) {
                      final dayItem = idx < data.currentWeekDailyCardio.length
                          ? data.currentWeekDailyCardio[idx]
                          : DailyCardioBreakdown(
                              day: current.weekStart.add(Duration(days: idx)),
                            );
                      final mins = dayItem.totalMinutes;
                      final barHeight = mins <= 0
                          ? 6.0
                          : (44.0 * (mins / maxMinutes)).clamp(10.0, 44.0);
                      final weekdayIdx = (dayItem.day.weekday - 1).clamp(0, 6);
                      final dayLabel = _weekdayInitials[weekdayIdx];
                      final fullDayName = _weekdayFullNames[weekdayIdx];

                      return ConstrainedBox(
                        constraints: BoxConstraints(minWidth: minColumnWidth),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Semantics(
                            label: '$fullDayName: $mins minutos de cardio',
                            excludeSemantics: true,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  mins > 0 ? '${mins}m' : '',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: colors.primaryLight,
                                    fontFeatures: AppTypography.tabularFeatures,
                                  ),
                                ),
                                SizedBox(height: context.appSpacing.space4),
                                Container(
                                  width: 18,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    color: mins > 0
                                        ? colors.primary
                                        : colors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(radius.xs),
                                  ),
                                ),
                                SizedBox(height: context.appSpacing.space8),
                                Text(
                                  dayLabel,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: mins > 0
                                        ? colors.textPrimary
                                        : colors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              );
            },
          ),
          if (data.currentWeekStandaloneCardio.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: colors.borderSubtle),
            const SizedBox(height: 12),
            Text(
              'CARDIOS AVULSOS',
              style: AppTypography.eyebrow(context),
            ),
            const SizedBox(height: 8),
            ...data.currentWeekStandaloneCardio.map((log) {
              final day = log.performedAt.day.toString().padLeft(2, '0');
              final month = log.performedAt.month.toString().padLeft(2, '0');
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_run_rounded,
                      size: 16,
                      color: colors.primaryLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${log.modality} · $day/$month',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontFeatures: AppTypography.tabularFeatures,
                            ),
                          ),
                          if (log.notes != null && log.notes!.isNotEmpty)
                            Text(
                              log.notes!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      formatCardioSeconds(log.durationSeconds),
                      style: context.textTheme.labelMedium?.copyWith(
                        color: colors.primaryLight,
                        fontFeatures: AppTypography.tabularFeatures,
                      ),
                    ),
                    Semantics(
                      label: 'Remover cardio ${log.modality}',
                      button: true,
                      child: IconButton(
                        onPressed: () => onDeleteStandalone(log),
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: colors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.currentValue,
    required this.previousValue,
    this.deltaBadge,
  });

  final String label;
  final String currentValue;
  final String previousValue;
  final LiftrBadge? deltaBadge;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ant.: $previousValue',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                  fontFeatures: AppTypography.tabularFeatures,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currentValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: context.textTheme.titleSmall?.copyWith(
                  fontFeatures: AppTypography.tabularFeatures,
                ),
              ),
              if (deltaBadge != null) ...[
                const SizedBox(height: 4),
                deltaBadge!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklyHistorySection extends StatelessWidget {
  const _WeeklyHistorySection({required this.snapshots});

  final List<WeeklySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radius.large),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Evolução semanal',
                  style: context.textTheme.titleMedium,
                ),
              ),
              Text(
                'HISTÓRICO',
                style: AppTypography.eyebrow(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < snapshots.length; i++) ...[
            if (i > 0) Divider(height: 16, color: colors.borderSubtle),
            _HistoryWeekRow(snapshot: snapshots[i]),
          ],
        ],
      ),
    );
  }
}

class _HistoryWeekRow extends StatelessWidget {
  const _HistoryWeekRow({required this.snapshot});

  final WeeklySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatWeekRange(snapshot.weekStart),
                style: context.textTheme.titleSmall?.copyWith(
                  fontFeatures: AppTypography.tabularFeatures,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${snapshot.workoutsCompleted} treinos · ${formatCardioSeconds(snapshot.cardioDurationSeconds)} cardio',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                  fontFeatures: AppTypography.tabularFeatures,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.end,
            children: [
              if (snapshot.avgExecutionScore != null)
                LiftrBadge(
                  label: '${snapshot.avgExecutionScore!.round()}%',
                  tone: snapshot.avgExecutionScore! >= 85
                      ? LiftrBadgeTone.success
                      : LiftrBadgeTone.neutral,
                ),
              if (snapshot.avgRpe != null)
                LiftrBadge(
                  label:
                      'RPE ${snapshot.avgRpe!.toStringAsFixed(1).replaceAll('.', ',')}',
                  tone: LiftrBadgeTone.brand,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
