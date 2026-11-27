import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_stats.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/weight_repository.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/delete_weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/get_weight_stats.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/log_weight_entry.dart';

class MockWeightRepository extends Mock implements WeightRepository {}

void main() {
  late MockWeightRepository mockRepo;
  late LogWeightEntryUseCase logWeightUseCase;
  late GetWeightStatsUseCase getWeightStatsUseCase;
  late DeleteWeightEntryUseCase deleteWeightUseCase;

  final tEntry = WeightEntry(
    id: 'w-1',
    userId: 'u-1',
    weightKg: 80.0,
    measuredAt: DateTime(2026, 8, 22),
  );

  setUp(() {
    mockRepo = MockWeightRepository();
    logWeightUseCase = LogWeightEntryUseCase(mockRepo);
    getWeightStatsUseCase = GetWeightStatsUseCase(mockRepo);
    deleteWeightUseCase = DeleteWeightEntryUseCase(mockRepo);
  });

  group('LogWeightEntryUseCase', () {
    test('should log weight successfully when valid', () async {
      when(() => mockRepo.logWeight(
            weightKg: 80.0,
            measuredAt: any(named: 'measuredAt'),
            notes: any(named: 'notes'),
          )).thenAnswer((_) async => Success(tEntry));

      final result = await logWeightUseCase.execute(
        weightKg: 80.0,
        measuredAt: DateTime(2026, 8, 22),
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.weightKg, 80.0);
    });

    test('should return ValidationFailure when weight is <= 0 or > 500', () async {
      final resultZero = await logWeightUseCase.execute(
        weightKg: 0,
        measuredAt: DateTime(2026, 8, 22),
      );
      expect(resultZero.isError, isTrue);
      expect((resultZero as Err).failure, isA<ValidationFailure>());

      final resultTooHigh = await logWeightUseCase.execute(
        weightKg: 550,
        measuredAt: DateTime(2026, 8, 22),
      );
      expect(resultTooHigh.isError, isTrue);
      expect((resultTooHigh as Err).failure, isA<ValidationFailure>());

      final resultNaN = await logWeightUseCase.execute(
        weightKg: double.nan,
        measuredAt: DateTime(2026, 8, 22),
      );
      expect(resultNaN.isError, isTrue);
      expect((resultNaN as Err).failure, isA<ValidationFailure>());
    });
  });

  group('GetWeightStatsUseCase', () {
    test('should calculate 7d, 14d, 30d averages and trend correctly', () async {
      final now = DateTime(2026, 8, 22);
      final entries = [
        WeightEntry(id: '1', weightKg: 82.0, measuredAt: now.subtract(const Duration(days: 1))),
        WeightEntry(id: '2', weightKg: 82.0, measuredAt: now.subtract(const Duration(days: 3))),
        WeightEntry(id: '3', weightKg: 80.0, measuredAt: now.subtract(const Duration(days: 9))),
        WeightEntry(id: '4', weightKg: 80.0, measuredAt: now.subtract(const Duration(days: 11))),
      ];

      when(() => mockRepo.getWeightEntriesInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => Success(entries));

      final result = await getWeightStatsUseCase.execute(referenceDate: now);

      expect(result.isSuccess, isTrue);
      final stats = (result as Success).value;
      expect(stats.average7Days, 82.0);
      expect(stats.trend, WeightTrend.gaining); // 82 - 80 = +2kg gaining
      expect(stats.deltaVsPreviousWeekKg, 2.0);
    });

    test('should return WeightTrend.unknown when previous week baseline is missing', () async {
      final now = DateTime(2026, 8, 22);
      final entries = [
        WeightEntry(id: '1', weightKg: 82.0, measuredAt: now.subtract(const Duration(days: 1))),
        WeightEntry(id: '2', weightKg: 82.0, measuredAt: now.subtract(const Duration(days: 3))),
      ];

      when(() => mockRepo.getWeightEntriesInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => Success(entries));

      final result = await getWeightStatsUseCase.execute(referenceDate: now);

      expect(result.isSuccess, isTrue);
      final stats = (result as Success).value;
      expect(stats.average7Days, 82.0);
      expect(stats.average14Days, 82.0);
      expect(stats.trend, WeightTrend.unknown);
      expect(stats.deltaVsPreviousWeekKg, isNull);
    });
  });

  group('DeleteWeightEntryUseCase', () {
    test('should delete entry from repository', () async {
      when(() => mockRepo.deleteWeightEntry('w-1'))
          .thenAnswer((_) async => const Success(null));

      final result = await deleteWeightUseCase.execute('w-1');
      expect(result.isSuccess, isTrue);
    });
  });
}
