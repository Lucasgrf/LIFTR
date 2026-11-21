import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/weight_repository.dart';
import 'package:personal_fitness_os/features/calendar/domain/entities/day_activity_summary.dart';
import 'package:personal_fitness_os/features/calendar/domain/entities/month_activity_data.dart';
import 'package:personal_fitness_os/features/history/domain/repositories/history_repository.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

class GetMonthActivitiesUseCase {
  const GetMonthActivitiesUseCase({
    required HistoryRepository historyRepository,
    required WeightRepository weightRepository,
  })  : _historyRepository = historyRepository,
        _weightRepository = weightRepository;

  final HistoryRepository _historyRepository;
  final WeightRepository _weightRepository;

  Future<Result<MonthActivityData, Failure>> execute({
    required int year,
    required int month,
  }) async {
    final startOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final endOfMonth = DateTime(year, month, daysInMonth, 23, 59, 59, 999);

    // 1. Fetch completed workout sessions in range
    final sessionsResult = await _historyRepository.getSessionsInRange(
      start: startOfMonth,
      end: endOfMonth,
    );
    if (sessionsResult is Err<List<WorkoutSession>, Failure>) {
      return Err(sessionsResult.failure);
    }
    final sessions = (sessionsResult as Success<List<WorkoutSession>, Failure>).value;

    // 2. Fetch weight entries
    final weightResult = await _weightRepository.getWeightHistory();
    List<WeightEntry> weightEntries = const [];
    if (weightResult is Success<List<WeightEntry>, Failure>) {
      weightEntries = weightResult.value.where((w) {
        return w.measuredAt.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
            w.measuredAt.isBefore(endOfMonth.add(const Duration(seconds: 1)));
      }).toList();
    }

    // 3. Build day summaries for each day of the month
    final daySummaries = List.generate(daysInMonth, (index) {
      final dayNumber = index + 1;
      final dayDate = DateTime(year, month, dayNumber);

      final sessionOnDay = sessions.where((s) {
        final date = s.completedAt ?? s.startedAt;
        return date.year == year && date.month == month && date.day == dayNumber;
      }).firstOrNull;

      final weightOnDay = weightEntries.where((w) {
        return w.measuredAt.year == year &&
            w.measuredAt.month == month &&
            w.measuredAt.day == dayNumber;
      }).firstOrNull;

      return DayActivitySummary(
        date: dayDate,
        workoutSession: sessionOnDay,
        weightEntry: weightOnDay,
      );
    });

    return Success(
      MonthActivityData(
        year: year,
        month: month,
        days: daySummaries,
      ),
    );
  }
}
