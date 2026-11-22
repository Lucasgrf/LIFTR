import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/cardio_log.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_comparison_data.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_snapshot.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

/// Pure domain aggregator computing weekly snapshots and daily cardio timelines
/// across both in-session cardio exercises and standalone cardio logs.
class WeeklySnapshotAggregator {
  const WeeklySnapshotAggregator._();

  static WeeklySnapshot aggregateWeek({
    required DateTime weekStart,
    required List<WorkoutSession> sessions,
    required List<CardioLog> standaloneCardio,
  }) {
    final normalizedStart = isoWeekStart(weekStart);
    final normalizedEnd = isoWeekEnd(normalizedStart);
    final endDateOnly = DateTime(
      normalizedStart.year,
      normalizedStart.month,
      normalizedStart.day + 6,
    );

    final weekSessions = sessions.where((s) {
      if (!s.isCompleted) return false;
      final ts = s.completedAt ?? s.startedAt;
      return !ts.isBefore(normalizedStart) && !ts.isAfter(normalizedEnd);
    }).toList();

    final weekCardio = standaloneCardio.where((c) {
      return !c.performedAt.isBefore(normalizedStart) &&
          !c.performedAt.isAfter(normalizedEnd);
    }).toList();

    var inSessionCardioSeconds = 0;
    var trainingDurationSeconds = 0;
    var workingSetsCount = 0;
    var totalVolumeKg = 0.0;
    final rpeValues = <double>[];
    final executionScores = <int>[];

    for (final s in weekSessions) {
      inSessionCardioSeconds += s.totalCardioDurationSeconds;
      trainingDurationSeconds += s.durationSeconds;
      workingSetsCount += s.totalWorkingSetsCount;
      totalVolumeKg += s.totalVolumeKg;
      if (s.perceivedExertion != null) {
        rpeValues.add(s.perceivedExertion!);
      }
      if (s.executionScore != null) {
        executionScores.add(s.executionScore!);
      }
    }

    final standaloneSeconds = weekCardio.fold<int>(
      0,
      (sum, c) => sum + c.durationSeconds,
    );

    final avgRpe = rpeValues.isEmpty
        ? null
        : double.parse(
            (rpeValues.reduce((a, b) => a + b) / rpeValues.length)
                .toStringAsFixed(1),
          );

    final avgExecutionScore = executionScores.isEmpty
        ? null
        : double.parse(
            (executionScores.reduce((a, b) => a + b) / executionScores.length)
                .toStringAsFixed(1),
          );

    return WeeklySnapshot(
      weekStart: normalizedStart,
      weekEnd: endDateOnly,
      workoutsCompleted: weekSessions.length,
      cardioDurationSeconds: inSessionCardioSeconds + standaloneSeconds,
      trainingDurationSeconds: trainingDurationSeconds,
      workingSetsCount: workingSetsCount,
      totalVolumeKg: double.parse(totalVolumeKg.toStringAsFixed(2)),
      avgRpe: avgRpe,
      avgExecutionScore: avgExecutionScore,
      updatedAt: DateTime.now(),
    );
  }

  static List<DailyCardioBreakdown> buildDailyCardioBreakdown({
    required DateTime weekStart,
    required List<WorkoutSession> sessions,
    required List<CardioLog> standaloneCardio,
  }) {
    final normalizedStart = isoWeekStart(weekStart);
    final normalizedEnd = isoWeekEnd(normalizedStart);

    final inSessionByDay = <String, int>{};
    for (final s in sessions) {
      if (!s.isCompleted) continue;
      final ts = s.completedAt ?? s.startedAt;
      if (ts.isBefore(normalizedStart) || ts.isAfter(normalizedEnd)) continue;
      final cardioSec = s.totalCardioDurationSeconds;
      if (cardioSec <= 0) continue;
      final key = isoDateKey(ts);
      inSessionByDay[key] = (inSessionByDay[key] ?? 0) + cardioSec;
    }

    final standaloneByDay = <String, int>{};
    for (final c in standaloneCardio) {
      if (c.performedAt.isBefore(normalizedStart) ||
          c.performedAt.isAfter(normalizedEnd)) {
        continue;
      }
      final key = isoDateKey(c.performedAt);
      standaloneByDay[key] = (standaloneByDay[key] ?? 0) + c.durationSeconds;
    }

    return List.generate(7, (idx) {
      final day = DateTime(
        normalizedStart.year,
        normalizedStart.month,
        normalizedStart.day + idx,
      );
      final key = isoDateKey(day);
      return DailyCardioBreakdown(
        day: day,
        inSessionSeconds: inSessionByDay[key] ?? 0,
        standaloneSeconds: standaloneByDay[key] ?? 0,
      );
    });
  }
}
