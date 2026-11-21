import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/calendar/domain/entities/day_activity_summary.dart';
import 'package:personal_fitness_os/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:personal_fitness_os/features/calendar/presentation/widgets/day_activity_detail_card.dart';

class ActivityCalendarScreen extends ConsumerWidget {
  const ActivityCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final visibleMonth = ref.watch(currentCalendarMonthProvider);
    final selectedDay = ref.watch(selectedCalendarDayProvider);
    final monthDataAsync = ref.watch(monthActivitiesDataProvider);

    final monthTitle = DateFormat('MMMM yyyy', 'pt_BR').format(visibleMonth);
    final capitalizedMonth = monthTitle[0].toUpperCase() + monthTitle.substring(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário de Atividades'),
      ),
      body: monthDataAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, _) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.refresh(monthActivitiesDataProvider),
        ),
        data: (monthData) {
          final selectedSummary = monthData.days.where((d) {
            return d.date.year == selectedDay.year &&
                d.date.month == selectedDay.month &&
                d.date.day == selectedDay.day;
          }).firstOrNull ??
              DayActivitySummary(date: selectedDay);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              // Month Header Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      ref.read(currentCalendarMonthProvider.notifier).state =
                          DateTime(visibleMonth.year, visibleMonth.month - 1, 1);
                    },
                  ),
                  Text(
                    capitalizedMonth,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () {
                      ref.read(currentCalendarMonthProvider.notifier).state =
                          DateTime(visibleMonth.year, visibleMonth.month + 1, 1);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Weekdays Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'].map((day) {
                  return SizedBox(
                    width: 38,
                    child: Center(
                      child: Text(
                        day,
                        style: context.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textTertiary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // Calendar Month Grid
              _buildMonthGrid(context, ref, monthData, visibleMonth, selectedDay),
              const SizedBox(height: 20),

              // Selected Day Inspection Card
              DayActivityDetailCard(summary: selectedSummary),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    WidgetRef ref,
    dynamic monthData,
    DateTime visibleMonth,
    DateTime selectedDay,
  ) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    final firstDayWeekday = DateTime(visibleMonth.year, visibleMonth.month, 1).weekday % 7; // 0 for Sunday
    final daysInMonth = DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final totalCells = firstDayWeekday + daysInMonth;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < firstDayWeekday) {
          return const SizedBox.shrink();
        }

        final dayNumber = index - firstDayWeekday + 1;
        final cellDate = DateTime(visibleMonth.year, visibleMonth.month, dayNumber);
        final isSelected = cellDate.year == selectedDay.year &&
            cellDate.month == selectedDay.month &&
            cellDate.day == selectedDay.day;

        final daySummary = (monthData.days as List<DayActivitySummary>).where((d) {
          return d.date.day == dayNumber;
        }).firstOrNull;

        final hasWorkout = daySummary?.hasWorkout == true;
        final hasWeight = daySummary?.hasWeight == true;

        return GestureDetector(
          onTap: () {
            ref.read(selectedCalendarDayProvider.notifier).state = cellDate;
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.25)
                  : colors.surfaceVariant,
              borderRadius: BorderRadius.circular(context.appRadius.small),
              border: Border.all(
                color: isSelected ? colors.primary : colors.border.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNumber',
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? colors.primary : colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasWorkout)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasWeight)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: fitnessColors.progressMaintain,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
