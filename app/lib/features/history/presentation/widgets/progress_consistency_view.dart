import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/utils/pt_br_copy_utils.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

class ProgressConsistencyView extends ConsumerStatefulWidget {
  const ProgressConsistencyView({super.key});

  @override
  ConsumerState<ProgressConsistencyView> createState() =>
      _ProgressConsistencyViewState();
}

class _ProgressConsistencyViewState
    extends ConsumerState<ProgressConsistencyView> {
  DateTime? _selectedDay;

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final historyAsync = ref.watch(historyListProvider);

    return historyAsync.when(
      skipLoadingOnRefresh: true,
      skipError: true,
      loading: () => const LiftrScreenSkeleton(showHero: false, itemCount: 2),
      error: (err, st) => ErrorStateWidget(
        message: userFacingMessage(
          err,
          stackTrace: st,
          context: 'ProgressConsistencyView.build',
        ),
        safetyNote: offlineSafetyNoteFor(err),
        onRetry: () => ref.invalidate(historyListProvider),
      ),
      data: (sessions) {
        final now = ref.watch(appClockProvider)();
        final today = _dateOnly(now);
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final monthStart = DateTime(now.year, now.month, 1);

        final sessionsByDay = <DateTime, List<WorkoutSession>>{};
        for (final session in sessions) {
          final day = _dateOnly(session.completedAt ?? session.startedAt);
          sessionsByDay.putIfAbsent(day, () => []).add(session);
        }

        final weekCount = sessions.where((s) {
          final d = _dateOnly(s.completedAt ?? s.startedAt);
          return !d.isBefore(weekStart);
        }).length;

        final monthCount = sessions.where((s) {
          final d = _dateOnly(s.completedAt ?? s.startedAt);
          return !d.isBefore(monthStart);
        }).length;

        // Count active weeks in the last 4 weeks
        var activeWeeks = 0;
        for (int w = 0; w < 4; w++) {
          final start = weekStart.subtract(Duration(days: w * 7));
          final end = start.add(const Duration(days: 7));
          final hasAny = sessions.any((s) {
            final d = _dateOnly(s.completedAt ?? s.startedAt);
            return !d.isBefore(start) && d.isBefore(end);
          });
          if (hasAny) activeWeeks++;
        }

        // Build 12-week (84-day) grid ending on today's week Sunday
        const totalWeeks = 12;
        final endOfGridWeek = weekStart.add(const Duration(days: 6));
        final startOfGrid =
            endOfGridWeek.subtract(const Duration(days: totalWeeks * 7 - 1));

        final selectedDay = _selectedDay ??
            (sessionsByDay.keys.isNotEmpty
                ? (sessionsByDay.keys.toList()..sort()).last
                : today);
        final selectedSessions = sessionsByDay[selectedDay] ?? const [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    count: weekCount,
                    label: 'treinos esta semana',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    count: monthCount,
                    label: 'treinos este mês',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              activeWeeks > 0
                  ? 'Você manteve sua fila girando em $activeWeeks das últimas 4 semanas. Descanso também faz parte do processo.'
                  : 'Cada sessão conta. Sua fila aguarda no seu ritmo, sem punições por dias de descanso.',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),

            // 12-week Heatmap
            Semantics(
              container: true,
              explicitChildNodes: true,
              label: 'Mapa de consistência das últimas 12 semanas',
              child: AppCard(
                variant: AppCardVariant.subtle,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 5.0;
                        const weekdayWidth = 18.0;
                        const weekdayGap = 6.0;
                        final gridMaxWidth =
                            (constraints.maxWidth - weekdayWidth - weekdayGap)
                                .clamp(120.0, double.infinity);
                        final size =
                            ((gridMaxWidth - (totalWeeks - 1) * gap) /
                                    totalWeeks)
                                .clamp(9.0, 22.0);
                        final gridWidth =
                            totalWeeks * size + (totalWeeks - 1) * gap;

                        const weekdayInitials = [
                          'S',
                          'T',
                          'Q',
                          'Q',
                          'S',
                          'S',
                          'D',
                        ];

                        final monthLabels = <(int, String)>[];
                        int? lastMonth;
                        int? lastLabelWeek;
                        for (int w = 0; w < totalWeeks; w++) {
                          final weekDate =
                              startOfGrid.add(Duration(days: w * 7));
                          if (lastMonth != weekDate.month) {
                            lastMonth = weekDate.month;
                            if (lastLabelWeek == null ||
                                w - lastLabelWeek >= 2) {
                              final rawMonth = ptBrDateFormat('MMM')
                                  .format(weekDate)
                                  .replaceAll('.', '');
                              final label = rawMonth.isNotEmpty
                                  ? rawMonth[0].toUpperCase() +
                                      rawMonth.substring(1)
                                  : rawMonth;
                              monthLabels.add((w, label));
                              lastLabelWeek = w;
                            }
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: weekdayWidth + weekdayGap,
                                bottom: 6,
                              ),
                              child: SizedBox(
                                width: gridWidth,
                                height: 18,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    for (final entry in monthLabels)
                                      Positioned(
                                        left: entry.$1 * (size + gap),
                                        top: 0,
                                        child: Text(
                                          entry.$2,
                                          maxLines: 1,
                                          softWrap: false,
                                          style: context.textTheme.labelSmall
                                              ?.copyWith(
                                            color: colors.textTertiary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: weekdayWidth,
                                  child: Column(
                                    children: List.generate(7, (dayIdx) {
                                      return Container(
                                        height: size,
                                        margin: EdgeInsets.only(
                                          bottom: dayIdx < 6 ? gap : 0,
                                        ),
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          weekdayInitials[dayIdx],
                                          maxLines: 1,
                                          softWrap: false,
                                          style: context.textTheme.labelSmall
                                              ?.copyWith(
                                            color: colors.textTertiary,
                                            height: 1.0,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                const SizedBox(width: weekdayGap),
                                SizedBox(
                                  width: gridWidth,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children:
                                        List.generate(totalWeeks, (weekIdx) {
                                      return Column(
                                        children: List.generate(7, (dayIdx) {
                                          final cellDate = startOfGrid.add(
                                            Duration(days: weekIdx * 7 + dayIdx),
                                          );
                                          final daySessions =
                                              sessionsByDay[cellDate] ??
                                                  const [];
                                          final isSelected =
                                              cellDate == selectedDay;
                                          final intensity = _cellColor(
                                            context,
                                            daySessions,
                                          );

                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: dayIdx < 6 ? gap : 0,
                                            ),
                                            child: Semantics(
                                              label:
                                                  '${ptBrDateFormat('d MMM').format(cellDate)}, ${pluralize(daySessions.length, 'treino', 'treinos')}',
                                              button: true,
                                              selected: isSelected,
                                              child: GestureDetector(
                                                onTap: () {
                                                  HapticFeedback
                                                      .selectionClick();
                                                  setState(
                                                    () =>
                                                        _selectedDay = cellDate,
                                                  );
                                                },
                                                child: Container(
                                                  width: size,
                                                  height: size,
                                                  decoration: BoxDecoration(
                                                    color: intensity,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      radius.xs,
                                                    ),
                                                    border: isSelected
                                                        ? Border.all(
                                                            color: colors
                                                                .textPrimary,
                                                            width: 1.5,
                                                          )
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Menos',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                        SizedBox(width: context.appSpacing.space8),
                        for (final swatchColor in [
                          colors.surfaceElevated,
                          colors.primary.withValues(alpha: 0.28),
                          colors.primary.withValues(alpha: 0.60),
                          colors.primary,
                        ]) ...[
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: swatchColor,
                              borderRadius: BorderRadius.circular(radius.xs),
                            ),
                          ),
                          SizedBox(width: context.appSpacing.space4),
                        ],
                        SizedBox(width: context.appSpacing.space2),
                        Text(
                          'Mais',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.appSpacing.space12),

            // Selected Day Detail Strip
            if (selectedSessions.isEmpty)
              AppCard(
                borderRadius: radius.medium,
                constraints: const BoxConstraints(minHeight: 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    Text(
                      ptBrDateFormat("d 'de' MMM").format(selectedDay),
                      style: context.textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontFeatures: AppTypography.tabularFeatures,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        'Dia de descanso',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              AppCard(
                borderRadius: radius.medium,
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        children: [
                          Text(
                            ptBrDateFormat("d 'de' MMM")
                                .format(selectedDay),
                            style: context.textTheme.labelMedium?.copyWith(
                              color: colors.textSecondary,
                              fontFeatures: AppTypography.tabularFeatures,
                            ),
                          ),
                          if (selectedSessions.length > 1)
                            Text(
                              pluralize(
                                selectedSessions.length,
                                'sessão',
                                'sessões',
                              ),
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.textTertiary,
                                fontFeatures: AppTypography.tabularFeatures,
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (int i = 0; i < selectedSessions.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: colors.borderSubtle,
                        ),
                      InkWell(
                        onTap: () => context.push(
                          '/session/${selectedSessions[i].id}/summary',
                        ),
                        borderRadius: i == selectedSessions.length - 1
                            ? BorderRadius.vertical(
                                bottom: Radius.circular(radius.medium),
                              )
                            : BorderRadius.zero,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${selectedSessions[i].workoutName} · '
                                    '${selectedSessions[i].totalWorkingSetsCount} séries · '
                                    '${mathMaxOne(selectedSessions[i].durationSeconds ~/ 60)} min',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.labelMedium
                                        ?.copyWith(
                                      color: colors.textPrimary,
                                      fontFeatures:
                                          AppTypography.tabularFeatures,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: colors.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  int mathMaxOne(int val) => val < 1 ? 1 : val;

  Color _cellColor(BuildContext context, List<WorkoutSession> daySessions) {
    final colors = context.appColors;
    if (daySessions.isEmpty) return colors.surfaceElevated;
    final sets = daySessions.fold<int>(
      0,
      (sum, s) => sum + s.totalWorkingSetsCount,
    );
    if (sets >= 14) return colors.primary;
    if (sets >= 8) return colors.primary.withValues(alpha: 0.60);
    return colors.primary.withValues(alpha: 0.28);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.count,
    required this.label,
  });

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: context.textTheme.displayMedium?.copyWith(
              fontFeatures: AppTypography.tabularFeatures,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
