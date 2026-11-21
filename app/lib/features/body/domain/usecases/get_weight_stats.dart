import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_stats.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/weight_repository.dart';

class GetWeightStatsUseCase {
  const GetWeightStatsUseCase(this._repository);

  final WeightRepository _repository;

  Future<Result<WeightStats, Failure>> execute({DateTime? referenceDate}) async {
    final now = referenceDate ?? DateTime.now();
    final start60DaysAgo = now.subtract(const Duration(days: 60));

    final result = await _repository.getWeightEntriesInRange(
      start: start60DaysAgo,
      end: now,
    );

    if (result is Err<List<WeightEntry>, Failure>) {
      return Err(result.failure);
    }

    final entries = (result as Success<List<WeightEntry>, Failure>).value;

    if (entries.isEmpty) {
      return const Success(WeightStats());
    }

    // Sort descending by measuredAt
    final sorted = List<WeightEntry>.from(entries)
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));

    final latest = sorted.first;

    final cutoff7d = now.subtract(const Duration(days: 7));
    final cutoff14d = now.subtract(const Duration(days: 14));
    final cutoff30d = now.subtract(const Duration(days: 30));

    final entries7d =
        sorted.where((e) => !e.measuredAt.isBefore(cutoff7d)).toList();
    final entries14d =
        sorted.where((e) => !e.measuredAt.isBefore(cutoff14d)).toList();
    final entries30d =
        sorted.where((e) => !e.measuredAt.isBefore(cutoff30d)).toList();
    final entriesPrev7d = sorted
        .where((e) =>
            !e.measuredAt.isBefore(cutoff14d) &&
            e.measuredAt.isBefore(cutoff7d))
        .toList();

    double? avg7d = entries7d.isNotEmpty
        ? entries7d.fold(0.0, (sum, e) => sum + e.weightKg) / entries7d.length
        : null;
    double? avg14d = entries14d.isNotEmpty
        ? entries14d.fold(0.0, (sum, e) => sum + e.weightKg) / entries14d.length
        : null;
    double? avg30d = entries30d.isNotEmpty
        ? entries30d.fold(0.0, (sum, e) => sum + e.weightKg) / entries30d.length
        : null;
    double? avgPrev7d = entriesPrev7d.isNotEmpty
        ? entriesPrev7d.fold(0.0, (sum, e) => sum + e.weightKg) / entriesPrev7d.length
        : null;

    double? delta;
    WeightTrend trend = WeightTrend.unknown;

    if (avg7d != null && avgPrev7d != null) {
      delta = avg7d - avgPrev7d;
      if (delta > 0.2) {
        trend = WeightTrend.gaining;
      } else if (delta < -0.2) {
        trend = WeightTrend.losing;
      } else {
        trend = WeightTrend.maintaining;
      }
    }

    return Success(
      WeightStats(
        latestEntry: latest,
        average7Days: avg7d,
        average14Days: avg14d,
        average30Days: avg30d,
        trend: trend,
        deltaVsPreviousWeekKg: delta,
      ),
    );
  }
}
