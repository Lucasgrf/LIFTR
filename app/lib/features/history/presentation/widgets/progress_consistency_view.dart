import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
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
      loading: () => const LiftrScreenSkeleton(showHero: false, itemCount: 2),
      error: (err, _) => ErrorStateWidget(
        message: err.toString(),
        onRetry: () => ref.invalidate(historyListProvider),
      ),
      data: (sessions) {
        final now = DateTime.now();
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(radius.large),
                border: Border.all(color: colors.border),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 5.0;
                  final size =
                      ((constraints.maxWidth - (totalWeeks - 1) * gap) /
                              totalWeeks)
                          .clamp(10.0, 22.0);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(totalWeeks, (weekIdx) {
                      return Column(
                        children: List.generate(7, (dayIdx) {
                          final cellDate = startOfGrid.add(
                            Duration(days: weekIdx * 7 + dayIdx),
                          );
                          final daySessions =
                              sessionsByDay[cellDate] ?? const [];
                          final isSelected = cellDate == selectedDay;
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
                                  '${DateFormat('d MMM', 'pt_BR').format(cellDate)}, ${daySessions.length} treinos',
                              button: true,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedDay = cellDate);
                                },
                                child: Container(
                                  width: size,
                                  height: size,
                                  decoration: BoxDecoration(
                                    color: intensity,
                                    borderRadius: BorderRadius.circular(3),
                                    border: isSelected
                                        ? Border.all(
                                            color: colors.textPrimary,
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
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Selected Day Detail Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(radius.medium),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Text(
                    DateFormat("d 'de' MMM", 'pt_BR').format(selectedDay),
                    style: context.textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                      fontFeatures: AppTypography.tabularFeatures,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      selectedSessions.isEmpty
                          ? 'Dia de descanso'
                          : '${selectedSessions.first.workoutName} · ${selectedSessions.first.totalWorkingSetsCount} séries · ${mathMaxOne(selectedSessions.first.durationSeconds ~/ 60)} min',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: colors.textPrimary,
                        fontFeatures: AppTypography.tabularFeatures,
                      ),
                    ),
                  ),
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
    if (sets >= 8) return colors.primary.withValues(alpha: 0.68);
    return colors.primary.withValues(alpha: 0.38);
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
