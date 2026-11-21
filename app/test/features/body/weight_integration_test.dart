import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/data/datasources/weight_remote_datasource.dart';
import 'package:personal_fitness_os/features/body/data/models/weight_entry_model.dart';
import 'package:personal_fitness_os/features/body/data/repositories/weight_repository_impl.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_stats.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/delete_weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/get_weight_history.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/get_weight_stats.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/log_weight_entry.dart';

class MockWeightRemoteDataSource extends Mock
    implements WeightRemoteDataSource {}

void main() {
  late MockWeightRemoteDataSource mockDataSource;
  late WeightRepositoryImpl repository;
  late LogWeightEntryUseCase logWeightUseCase;
  late GetWeightHistoryUseCase getHistoryUseCase;
  late GetWeightStatsUseCase getStatsUseCase;
  late DeleteWeightEntryUseCase deleteWeightUseCase;

  setUp(() {
    mockDataSource = MockWeightRemoteDataSource();
    repository = WeightRepositoryImpl(mockDataSource);

    logWeightUseCase = LogWeightEntryUseCase(repository);
    getHistoryUseCase = GetWeightHistoryUseCase(repository);
    getStatsUseCase = GetWeightStatsUseCase(repository);
    deleteWeightUseCase = DeleteWeightEntryUseCase(repository);
  });

  group('Weight Tracking End-to-End Integration Flow', () {
    test('should log weight entry, retrieve history, calculate moving averages & trend and delete entry', () async {
      final now = DateTime(2026, 8, 22);

      // 1. Log a new weight entry
      final tModel1 = WeightEntryModel(
        id: 'w-1',
        userId: 'u-1',
        weight: 82.0,
        measuredAt: now,
        notes: 'Pela manhã',
      );

      when(() => mockDataSource.insertWeightEntry(any()))
          .thenAnswer((_) async => tModel1);

      final logResult = await logWeightUseCase.execute(
        weightKg: 82.0,
        measuredAt: now,
        notes: 'Pela manhã',
      );

      expect(logResult.isSuccess, isTrue);
      final logged = (logResult as Success<WeightEntry, dynamic>).value;
      expect(logged.weightKg, 82.0);

      // 2. Fetch history and stats
      final tModel2 = WeightEntryModel(
        id: 'w-2',
        userId: 'u-1',
        weight: 80.0,
        measuredAt: now.subtract(const Duration(days: 10)),
      );

      when(() => mockDataSource.fetchWeightHistory(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => [tModel1, tModel2]);

      when(() => mockDataSource.fetchWeightEntriesInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => [tModel2, tModel1]);

      final historyResult = await getHistoryUseCase.execute();
      expect(historyResult.isSuccess, isTrue);
      final historyList = (historyResult as Success<List<WeightEntry>, dynamic>).value;
      expect(historyList.length, 2);

      final statsResult = await getStatsUseCase.execute(referenceDate: now);
      expect(statsResult.isSuccess, isTrue);
      final stats = (statsResult as Success<WeightStats, dynamic>).value;
      expect(stats.currentWeightKg, 82.0);
      expect(stats.average7Days, 82.0);
      expect(stats.trend, WeightTrend.gaining);

      // 3. Delete weight entry
      when(() => mockDataSource.deleteWeightEntry('w-1'))
          .thenAnswer((_) async => {});

      final deleteResult = await deleteWeightUseCase.execute('w-1');
      expect(deleteResult.isSuccess, isTrue);
    });
  });
}
