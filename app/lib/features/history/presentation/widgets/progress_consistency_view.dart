import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
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
  DateTime? _visibleMonth;

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final sessionsAsync = ref.watch(historyListProvider);

    return sessionsAsync.when(
      skipLoadingOnRefresh: true,
      skipError: true,
      loading: () => const LiftrScreenSkeleton(showHero: false, itemCount: 2),
      error: (error, stackTrace) => ErrorStateWidget(
        message: userFacingMessage(
          error,
          stackTrace: stackTrace,
          context: 'ProgressConsistencyView.build',
        ),
        safetyNote: offlineSafetyNoteFor(error),
        onRetry: () => ref.invalidate(historyListProvider),
      ),
      data: (sessions) {
        final now = ref.watch(appClockProvider)();
        final today = _dateOnly(now);
        final visibleMonth = _visibleMonth ?? DateTime(now.year, now.month);
        final monthStart = DateTime(visibleMonth.year, visibleMonth.month);
        final daysInMonth = DateUtils.getDaysInMonth(
          visibleMonth.year,
          visibleMonth.month,
        );
        final offset = monthStart.weekday - 1;
        final cellCount = ((offset + daysInMonth + 6) ~/ 7) * 7;

        final sessionsByDay = <DateTime, List<WorkoutSession>>{};
        for (final session in sessions) {
          final date = _dateOnly(session.completedAt ?? session.startedAt);
          sessionsByDay.putIfAbsent(date, () => []).add(session);
        }

        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekCount = sessions.where((session) {
          final date = _dateOnly(session.completedAt ?? session.startedAt);
          return !date.isBefore(weekStart);
        }).length;
        final monthCount = sessions.where((session) {
          final date = _dateOnly(session.completedAt ?? session.startedAt);
          return date.year == visibleMonth.year &&
              date.month == visibleMonth.month;
        }).length;

        final selectedDay = _selectedDay ?? today;
        final selectedSessions = sessionsByDay[selectedDay] ?? const [];
        final monthName = _capitalize(
          ptBrDateFormat('MMMM').format(monthStart),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$weekCount ${weekCount == 1 ? 'treino' : 'treinos'} esta semana, $monthCount em $monthName.',
              style: context.textTheme.titleMedium?.copyWith(
                fontFeatures: AppTypography.tabularFeatures,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A fila gira no seu ritmo. Descanso também faz parte do processo.',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              variant: AppCardVariant.subtle,
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _MonthButton(
                        label: 'Mês anterior',
                        icon: Icons.chevron_left_rounded,
                        onPressed: () => setState(() {
                          _visibleMonth = DateTime(
                            visibleMonth.year,
                            visibleMonth.month - 1,
                          );
                        }),
                      ),
                      Expanded(
                        child: Text(
                          monthName,
                          textAlign: TextAlign.center,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _MonthButton(
                        label: 'Próximo mês',
                        icon: Icons.chevron_right_rounded,
                        onPressed:
                            monthStart.year == now.year &&
                                monthStart.month == now.month
                            ? null
                            : () => setState(() {
                                _visibleMonth = DateTime(
                                  visibleMonth.year,
                                  visibleMonth.month + 1,
                                );
                              }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final calendarWidth = constraints.maxWidth < 336
                          ? 336.0
                          : constraints.maxWidth;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: calendarWidth,
                          child: Column(
                            children: [
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
                                itemCount: cellCount,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 7,
                                      mainAxisExtent: 50,
                                    ),
                                itemBuilder: (context, index) {
                                  final dayNumber = index - offset + 1;
                                  if (dayNumber < 1 ||
                                      dayNumber > daysInMonth) {
                                    return const SizedBox.shrink();
                                  }
                                  final date = DateTime(
                                    visibleMonth.year,
                                    visibleMonth.month,
                                    dayNumber,
                                  );
                                  final daySessions =
                                      sessionsByDay[date] ?? const [];
                                  final selected = date == selectedDay;
                                  final initials = daySessions.isEmpty
                                      ? null
                                      : _initials(
                                          daySessions.first.workoutName,
                                        );
                                  final background = daySessions.isEmpty
                                      ? Colors.transparent
                                      : colors.surfaceElevated;

                                  return Semantics(
                                    label: daySessions.isEmpty
                                        ? '${ptBrDateFormat("d 'de' MMMM").format(date)}, descanso'
                                        : '${ptBrDateFormat("d 'de' MMMM").format(date)}, ${daySessions.length} ${daySessions.length == 1 ? 'treino' : 'treinos'}: ${daySessions.map((session) => session.workoutName).join(', ')}',
                                    button: true,
                                    selected: selected,
                                    child: Padding(
                                      padding: const EdgeInsets.all(1),
                                      child: Material(
                                        color: background,
                                        borderRadius: BorderRadius.circular(
                                          radius.xs,
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setState(() => _selectedDay = date);
                                          },
                                          borderRadius: BorderRadius.circular(
                                            radius.xs,
                                          ),
                                          child: Container(
                                            constraints: const BoxConstraints(
                                              minWidth: 48,
                                              minHeight: 48,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    radius.xs,
                                                  ),
                                              border: selected
                                                  ? Border.all(
                                                      color: colors.textPrimary,
                                                      width: 1.5,
                                                    )
                                                  : null,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '$dayNumber',
                                                  style: context
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: colors
                                                            .textSecondary,
                                                        fontFeatures:
                                                            AppTypography
                                                                .tabularFeatures,
                                                      ),
                                                ),
                                                if (initials != null)
                                                  Text(
                                                    initials,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.clip,
                                                    style: context
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          color: colors.success,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                              ],
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
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SelectedDayDetails(day: selectedDay, sessions: selectedSessions),
          ],
        );
      },
    );
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

class _MonthButton extends StatelessWidget {
  const _MonthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    child: IconButton(
      onPressed: onPressed,
      tooltip: label,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      icon: Icon(icon),
    ),
  );
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: SizedBox(
      height: 32,
      child: Center(
        child: Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.appColors.textTertiary,
          ),
        ),
      ),
    ),
  );
}

class _SelectedDayDetails extends StatelessWidget {
  const _SelectedDayDetails({required this.day, required this.sessions});

  final DateTime day;
  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final dateLabel = ptBrDateFormat("d 'de' MMM").format(day);

    if (sessions.isEmpty) {
      return AppCard(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 4,
          children: [
            Text(
              dateLabel,
              style: context.textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
                fontFeatures: AppTypography.tabularFeatures,
              ),
            ),
            Text('Dia de descanso', style: context.textTheme.labelMedium),
          ],
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 4,
              children: [
                Text(
                  dateLabel,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontFeatures: AppTypography.tabularFeatures,
                  ),
                ),
                if (sessions.length > 1)
                  Text(
                    pluralize(sessions.length, 'sessão', 'sessões'),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                      fontFeatures: AppTypography.tabularFeatures,
                    ),
                  ),
              ],
            ),
          ),
          for (int index = 0; index < sessions.length; index++) ...[
            if (index > 0) Divider(height: 1, color: colors.divider),
            InkWell(
              onTap: () =>
                  context.push('/session/${sessions[index].id}/summary'),
              borderRadius: index == sessions.length - 1
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
                          '${sessions[index].workoutName} · '
                          '${sessions[index].totalWorkingSetsCount} séries · '
                          '${_atLeastOneMinute(sessions[index].durationSeconds ~/ 60)} min',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelMedium?.copyWith(
                            color: colors.textPrimary,
                            fontFeatures: AppTypography.tabularFeatures,
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
    );
  }

  int _atLeastOneMinute(int minutes) => minutes < 1 ? 1 : minutes;
}
