import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';

abstract class WeightRepository {
  Future<Result<WeightEntry, Failure>> logWeight({
    required double weightKg,
    required DateTime measuredAt,
    String? notes,
  });

  Future<Result<WeightEntry, Failure>> upsertDailyWeight({
    required double weightKg,
    required DateTime measuredAt,
    String? notes,
  });

  Future<Result<List<WeightEntry>, Failure>> getWeightHistory({
    int limit = 100,
    int offset = 0,
  });

  Future<Result<List<WeightEntry>, Failure>> getWeightEntriesInRange({
    required DateTime start,
    required DateTime end,
  });

  Future<Result<void, Failure>> deleteWeightEntry(String entryId);
}
