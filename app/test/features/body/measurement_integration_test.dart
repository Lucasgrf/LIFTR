import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/data/datasources/measurement_remote_datasource.dart';
import 'package:personal_fitness_os/features/body/data/models/body_measurement_model.dart';
import 'package:personal_fitness_os/features/body/data/repositories/measurement_repository_impl.dart';
import 'package:personal_fitness_os/features/body/domain/entities/body_measurement.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/delete_measurement.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/get_latest_measurement.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/get_measurements.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/log_measurement.dart';

class MockMeasurementRemoteDataSource extends Mock implements MeasurementRemoteDataSource {}

void main() {
  late MockMeasurementRemoteDataSource mockDataSource;
  late MeasurementRepositoryImpl repository;
  late GetMeasurementsUseCase getMeasurementsUseCase;
  late GetLatestMeasurementUseCase getLatestMeasurementUseCase;
  late LogMeasurementUseCase logMeasurementUseCase;
  late DeleteMeasurementUseCase deleteMeasurementUseCase;

  final tModel = BodyMeasurementModel(
    id: 'm-1',
    userId: 'u-1',
    measuredAt: DateTime(2026, 8, 22),
    waist: 82.0,
    chest: 104.0,
  );

  setUp(() {
    mockDataSource = MockMeasurementRemoteDataSource();
    repository = MeasurementRepositoryImpl(mockDataSource);
    getMeasurementsUseCase = GetMeasurementsUseCase(repository);
    getLatestMeasurementUseCase = GetLatestMeasurementUseCase(repository);
    logMeasurementUseCase = LogMeasurementUseCase(repository);
    deleteMeasurementUseCase = DeleteMeasurementUseCase(repository);
    registerFallbackValue(tModel);
  });

  group('Body Measurements Full Integration Flow', () {
    test('should log measurement, fetch latest, list and delete measurement', () async {
      // 1. Log measurement
      when(() => mockDataSource.insertMeasurement(any()))
          .thenAnswer((_) async => tModel);

      final newMeasurement = BodyMeasurement(
        id: '',
        measuredAt: DateTime(2026, 8, 22),
        waist: 82.0,
        chest: 104.0,
      );

      final logResult = await logMeasurementUseCase.execute(newMeasurement);
      expect(logResult.isSuccess, isTrue);
      expect((logResult as Success).value.id, 'm-1');

      // 2. Fetch latest
      when(() => mockDataSource.fetchLatestMeasurement())
          .thenAnswer((_) async => tModel);

      final latestResult = await getLatestMeasurementUseCase.execute();
      expect(latestResult.isSuccess, isTrue);
      expect((latestResult as Success).value?.waist, 82.0);

      // 3. List
      when(() => mockDataSource.fetchMeasurements(limit: any(named: 'limit')))
          .thenAnswer((_) async => [tModel]);

      final listResult = await getMeasurementsUseCase.execute();
      expect(listResult.isSuccess, isTrue);
      expect((listResult as Success).value.length, 1);

      // 4. Delete
      when(() => mockDataSource.deleteMeasurement('m-1'))
          .thenAnswer((_) async {});

      final deleteResult = await deleteMeasurementUseCase.execute('m-1');
      expect(deleteResult.isSuccess, isTrue);
      verify(() => mockDataSource.deleteMeasurement('m-1')).called(1);
    });
  });
}
