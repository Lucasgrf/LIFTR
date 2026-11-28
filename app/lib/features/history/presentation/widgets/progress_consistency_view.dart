import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

class ProgressConsistencyView extends ConsumerStatefulWidget {
  const ProgressConsistencyView({super.key});

  @override
  ConsumerState<ProgressConsistencyView> createState() =>
      _ProgressConsistencyViewState();
}

class _ProgressConsistencyViewState
    extends ConsumerState<ProgressConsistencyView> {
  DateTime? _visibleMonth;
  DateTime? _selectedDate;

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sessionsAsync = ref.watch(historyListProvider);
    final activePlan = ref.watch(activeTrainingPlanProvider);

    return sessionsAsync.when(
      skipLoadingOnRefresh: sessionsAsync.hasValue,
      skipError: sessionsAsync.hasValue,
      loading: () => const LiftrScreenSkeleton(showHero: false, itemCount: 2),
      error: (error, stack) => ErrorStateWidget(
        message: userFacingMessage(
          error,
          stackTrace: stack,
          context: 'ProgressConsistencyView.build',
        ),
        safetyNote: offlineSafetyNoteFor(error),
        onRetry: () => ref.invalidate(historyListProvider),
      ),
      data: (sessions) {
        final now = ref.watch(appClockProvider)();
        final today = _dateOnly(now);
        final month = _visibleMonth ?? DateTime(now.year, now.month);
        final monthStart = DateTime(month.year, month.month);
        final monthName = _capitalize(
          ptBrDateFormat('MMMM').format(monthStart),
        );
        final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
        final offset = monthStart.weekday - 1;
        final weeks = ((offset + daysInMonth + 6) ~/ 7);

        final sessionsByDay = <DateTime, List<WorkoutSession>>{};
        for (final session in sessions) {
          final date = _dateOnly(session.completedAt ?? session.startedAt);
          sessionsByDay.putIfAbsent(date, () => []).add(session);
        }

        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekCount = sessions.where((session) {
          final date = _dateOnly(session.completedAt ?? session.startedAt);
          return !date.isBefore(weekStart) && !date.isAfter(today);
        }).length;
        final monthCount = sessions.where((session) {
          final date = _dateOnly(session.completedAt ?? session.startedAt);
          return date.year == month.year && date.month == month.month;
        }).length;
        final completedWeeks = activePlan == null || activePlan.workouts.isEmpty
            ? 0
            : List<int>.generate(4, (index) {
                final start = weekStart.subtract(Duration(days: 7 * index));
                final end = start.add(const Duration(days: 7));
                final workouts = sessions
                    .where((session) {
                      final date = _dateOnly(
                        session.completedAt ?? session.startedAt,
                      );
                      return !date.isBefore(start) && date.isBefore(end);
                    })
                    .map((session) => session.workoutId)
                    .whereType<String>()
                    .toSet();
                return workouts.length >= activePlan.workouts.length ? 1 : 0;
              }).fold<int>(0, (sum, value) => sum + value);
        final canAdvance = monthStart.isBefore(DateTime(now.year, now.month));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              '$weekCount ${weekCount == 1 ? 'treino' : 'treinos'} esta semana, $monthCount em ${monthName.toLowerCase()}.',
              style: context.textTheme.titleLarge?.copyWith(
                fontFeatures: AppTypography.tabularFeatures,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              activePlan == null || activePlan.workouts.isEmpty
                  ? 'Os dias de descanso também contam.'
                  : 'O baralho deu a volta completa em $completedWeeks das últimas 4 semanas. Dia de descanso também conta.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity > 0) {
                  setState(() {
                    _visibleMonth = DateTime(month.year, month.month - 1);
                  });
                } else if (velocity < 0 && canAdvance) {
                  setState(() {
                    _visibleMonth = DateTime(month.year, month.month + 1);
                  });
                }
              },
              child: Semantics(
                label: 'Calendário de $monthName com $monthCount treinos',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(monthName, style: context.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        _WeekdayLabel('seg'),
                        _WeekdayLabel('ter'),
                        _WeekdayLabel('qua'),
                        _WeekdayLabel('qui'),
                        _WeekdayLabel('sex'),
                        _WeekdayLabel('sáb'),
                        _WeekdayLabel('dom'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: weeks * 7,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisExtent: 48,
                          ),
                      itemBuilder: (context, index) {
                        final dayNumber = index - offset + 1;
                        if (dayNumber < 1 || dayNumber > daysInMonth) {
                          return const SizedBox.shrink();
                        }
                        final date = DateTime(
                          month.year,
                          month.month,
                          dayNumber,
                        );
                        final isToday = date == today;
                        final isSelected = date == (_selectedDate ?? today);
                        final isFuture = date.isAfter(today);
                        final completed = sessionsByDay[date] ?? const [];
                        final initials = completed.isEmpty
                            ? null
                            : _initials(completed.first.workoutName);

                        return Semantics(
                          container: true,
                          excludeSemantics: true,
                          label: completed.isEmpty
                              ? '${ptBrDateFormat("d 'de' MMMM").format(date)}, descanso'
                              : '${ptBrDateFormat("d 'de' MMMM").format(date)}, ${completed.map((session) => session.workoutName).join(', ')} feito',
                          button: true,
                          selected: isSelected,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() => _selectedDate = date);
                              if (completed.isNotEmpty) {
                                _openDay(context, date, completed);
                              }
                            },
                            child: Center(
                              child: initials != null
                                  ? Transform.rotate(
                                      angle: _rotationFor(date),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: colors.danger,
                                            width: 2,
                                          ),
                                        ),
                                        child: Text(
                                          initials,
                                          style: context.textTheme.labelSmall
                                              ?.copyWith(
                                                color: colors.danger,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 40,
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: isSelected
                                          ? BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: colors.textPrimary,
                                                width: 1.5,
                                              ),
                                            )
                                          : null,
                                      child: Text(
                                        '$dayNumber',
                                        style: context.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: isFuture
                                                  ? colors.textTertiary
                                                  : colors.textPrimary,
                                              fontFeatures:
                                                  AppTypography.tabularFeatures,
                                              fontWeight: isToday
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openDay(
    BuildContext context,
    DateTime date,
    List<WorkoutSession> sessions,
  ) {
    showLiftrSheet<void>(
      context: context,
      title: ptBrDateFormat("EEEE, d 'de' MMMM").format(date),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final session in sessions)
            ListTile(
              title: Text(session.workoutName),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/session/${session.id}/summary'),
            ),
        ],
      ),
    );
  }

  double _rotationFor(DateTime date) {
    const angles = <double>[-.105, .087, -.052, .07];
    return angles[date.day % angles.length];
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'FT';
    if (words.length == 1) return words.first.characters.take(2).toString();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: SizedBox(
      height: 18,
      child: Center(
        child: Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
      ),
    ),
  );
}
