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
}
