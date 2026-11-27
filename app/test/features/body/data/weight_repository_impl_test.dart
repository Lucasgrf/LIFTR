import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/data/datasources/weight_remote_datasource.dart';
import 'package:personal_fitness_os/features/body/data/models/weight_entry_model.dart';
import 'package:personal_fitness_os/features/body/data/repositories/weight_repository_impl.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockWeightRemoteDataSource extends Mock
    implements WeightRemoteDataSource {}

void main() {
  late MockWeightRemoteDataSource mockDataSource;
  late WeightRepositoryImpl repository;

  final tModel = WeightEntryModel(
    id: 'w-1',
    userId: 'u-1',
    weight: 80.0,
    measuredAt: DateTime(2026, 8, 22),
  );

  setUp(() {
    mockDataSource = MockWeightRemoteDataSource();
    repository = WeightRepositoryImpl(mockDataSource);
  });

  group('logWeight', () {
    test('should return WeightEntry on success', () async {
      when(() => mockDataSource.insertWeightEntry(any()))
          .thenAnswer((_) async => tModel);

      final result = await repository.logWeight(
        weightKg: 80.0,
        measuredAt: DateTime(2026, 8, 22),
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success<WeightEntry, Failure>).value.weightKg, 80.0);
    });

    test('should return AuthFailure on AuthException', () async {
      when(() => mockDataSource.insertWeightEntry(any()))
          .thenThrow(const AuthException('Unauthenticated'));

      final result = await repository.logWeight(
        weightKg: 80.0,
        measuredAt: DateTime(2026, 8, 22),
      );

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<AuthFailure>());
    });

    test('should return ServerFailure on PostgrestException', () async {
      when(() => mockDataSource.insertWeightEntry(any()))
          .thenThrow(const PostgrestException(message: 'DB error'));

      final result = await repository.logWeight(
        weightKg: 80.0,
        measuredAt: DateTime(2026, 8, 22),
      );

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ServerFailure>());
    });
  });

  group('getWeightHistory', () {
    test('should return list of WeightEntry on success', () async {
      when(() => mockDataSource.fetchWeightHistory(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => [tModel]);

      final result = await repository.getWeightHistory();

      expect(result.isSuccess, isTrue);
      expect((result as Success<List<WeightEntry>, Failure>).value.length, 1);
    });
  });

  group('deleteWeightEntry', () {
    test('should succeed when deletion is successful', () async {
      when(() => mockDataSource.deleteWeightEntry('w-1'))
          .thenAnswer((_) async => {});

      final result = await repository.deleteWeightEntry('w-1');
      expect(result.isSuccess, isTrue);
    });
  });

  group('upsertDailyWeight', () {
    test('inserts a new entry when no weight exists for the same day',
        () async {
      final today = DateTime(2026, 8, 22, 10, 30);
      when(() => mockDataSource.fetchWeightEntriesInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => const []);
      when(() => mockDataSource.insertWeightEntry(any()))
          .thenAnswer((_) async => tModel);

      final result = await repository.upsertDailyWeight(
        weightKg: 80.0,
        measuredAt: today,
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockDataSource.insertWeightEntry(any())).called(1);
      verifyNever(() => mockDataSource.updateWeightEntry(any(), any()));
    });

    test('updates existing entry without creating duplicate on the same day',
        () async {
      final todayEvening = DateTime(2026, 8, 22, 20, 0);
      final updatedModel = WeightEntryModel(
        id: 'w-1',
        userId: 'u-1',
        weight: 79.4,
        measuredAt: todayEvening,
      );
      when(() => mockDataSource.fetchWeightEntriesInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => [tModel]);
      when(() => mockDataSource.updateWeightEntry('w-1', any()))
          .thenAnswer((_) async => updatedModel);

      final result = await repository.upsertDailyWeight(
        weightKg: 79.4,
        measuredAt: todayEvening,
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success<WeightEntry, Failure>).value.weightKg, 79.4);
      verify(() => mockDataSource.updateWeightEntry('w-1', any())).called(1);
      verifyNever(() => mockDataSource.insertWeightEntry(any()));
    });

    test('computes day boundaries in device local timezone and passes UTC bounds',
        () async {
      final inputUtc = DateTime.utc(2026, 8, 22, 23, 30);
      final expectedLocal = inputUtc.toLocal();
      final expectedStart =
          DateTime(expectedLocal.year, expectedLocal.month, expectedLocal.day)
              .toUtc();
      final expectedEnd = DateTime(
        expectedLocal.year,
        expectedLocal.month,
        expectedLocal.day,
        23,
        59,
        59,
        999,
      ).toUtc();

      when(() => mockDataSource.fetchWeightEntriesInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => const []);
      when(() => mockDataSource.insertWeightEntry(any()))
          .thenAnswer((_) async => tModel);

      await repository.upsertDailyWeight(
        weightKg: 81.2,
        measuredAt: inputUtc,
      );

      final captured = verify(() => mockDataSource.fetchWeightEntriesInRange(
            start: captureAny(named: 'start'),
            end: captureAny(named: 'end'),
          )).captured;
      final queriedStart = captured[0] as DateTime;
      final queriedEnd = captured[1] as DateTime;
      expect(queriedStart.isUtc, isTrue);
      expect(queriedEnd.isUtc, isTrue);
      expect(queriedStart, expectedStart);
      expect(queriedEnd, expectedEnd);
    });
  });
}
