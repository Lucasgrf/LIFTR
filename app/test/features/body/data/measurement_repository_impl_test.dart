import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/data/datasources/measurement_remote_datasource.dart';
import 'package:personal_fitness_os/features/body/data/models/body_measurement_model.dart';
import 'package:personal_fitness_os/features/body/data/repositories/measurement_repository_impl.dart';
import 'package:personal_fitness_os/features/body/domain/entities/body_measurement.dart';

class MockMeasurementRemoteDataSource extends Mock implements MeasurementRemoteDataSource {}

void main() {
  late MockMeasurementRemoteDataSource mockDataSource;
  late MeasurementRepositoryImpl repository;

  final tModel = BodyMeasurementModel(
    id: 'm-1',
    userId: 'u-1',
    measuredAt: DateTime(2026, 8, 22),
    waist: 80.5,
    chest: 102.0,
  );

  final tMeasurement = tModel.toDomain();

  setUp(() {
    mockDataSource = MockMeasurementRemoteDataSource();
    repository = MeasurementRepositoryImpl(mockDataSource);
    registerFallbackValue(tModel);
  });

  group('MeasurementRepositoryImpl', () {
    test('getMeasurements should return domain list when datasource succeeds', () async {
      when(() => mockDataSource.fetchMeasurements(limit: any(named: 'limit')))
          .thenAnswer((_) async => [tModel]);

      final result = await repository.getMeasurements();
      expect(result.isSuccess, isTrue);
      expect((result as Success).value.length, 1);
      expect((result as Success).value.first.waist, 80.5);
    });

    test('getLatestMeasurement should return single entity', () async {
      when(() => mockDataSource.fetchLatestMeasurement())
          .thenAnswer((_) async => tModel);

      final result = await repository.getLatestMeasurement();
      expect(result.isSuccess, isTrue);
      expect((result as Success).value?.chest, 102.0);
    });

    test('logMeasurement should insert and return domain entity', () async {
      when(() => mockDataSource.insertMeasurement(any()))
          .thenAnswer((_) async => tModel);

      final result = await repository.logMeasurement(tMeasurement);
      expect(result.isSuccess, isTrue);
      expect((result as Success).value.id, 'm-1');
    });

    test('deleteMeasurement should call remote datasource', () async {
      when(() => mockDataSource.deleteMeasurement('m-1'))
          .thenAnswer((_) async {});

      final result = await repository.deleteMeasurement('m-1');
      expect(result.isSuccess, isTrue);
      verify(() => mockDataSource.deleteMeasurement('m-1')).called(1);
    });

    test('should return UnexpectedFailure on generic exception', () async {
      when(() => mockDataSource.fetchMeasurements(limit: any(named: 'limit')))
          .thenThrow(Exception('DB error'));

      final result = await repository.getMeasurements();
      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<UnexpectedFailure>());
    });
  });
}
