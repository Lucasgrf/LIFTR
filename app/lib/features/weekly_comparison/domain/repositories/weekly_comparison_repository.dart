import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/cardio_log.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_comparison_data.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_snapshot.dart';

abstract class WeeklyComparisonRepository {
  Future<Result<WeeklyComparisonData, Failure>> getWeeklyComparison({
    DateTime? referenceDate,
    int historyWeeks = 8,
  });

  Future<Result<CardioLog, Failure>> logStandaloneCardio({
    required String modality,
    required int durationSeconds,
    DateTime? performedAt,
    String? notes,
  });

  Future<Result<void, Failure>> deleteStandaloneCardio(String id);

  Future<Result<WeeklySnapshot, Failure>> syncWeekSnapshot(
    DateTime referenceDate,
  );
}
