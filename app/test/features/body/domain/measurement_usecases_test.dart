import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/body_measurement.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/measurement_repository.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/delete_measurement.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/get_latest_measurement.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/get_measurements.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/log_measurement.dart';

class MockMeasurementRepository extends Mock implements MeasurementRepository {}

void main() {
  late MockMeasurementRepository mockRepo;

  final tMeasurement = BodyMeasurement(
    id: 'm-1',
    userId: 'u-1',
    measuredAt: DateTime(2026, 8, 22),
    waist: 82.0,
    chest: 104.0,
    armRight: 38.5,
  );

  setUp(() {
    mockRepo = MockMeasurementRepository();
    registerFallbackValue(tMeasurement);
  });

  group('GetMeasurementsUseCase', () {
    test('should return list of measurements when repository succeeds', () async {
      when(() => mockRepo.getMeasurements(limit: any(named: 'limit')))
          .thenAnswer((_) async => Success([tMeasurement]));

      final useCase = GetMeasurementsUseCase(mockRepo);
      final result = await useCase.execute(limit: 20);

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.length, 1);
    });

    test('should return ValidationFailure when limit <= 0', () async {
      final useCase = GetMeasurementsUseCase(mockRepo);
      final result = await useCase.execute(limit: 0);

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });
  });

  group('GetLatestMeasurementUseCase', () {
    test('should return latest measurement', () async {
      when(() => mockRepo.getLatestMeasurement())
          .thenAnswer((_) async => Success(tMeasurement));

      final useCase = GetLatestMeasurementUseCase(mockRepo);
      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      expect((result as Success).value?.id, 'm-1');
    });
  });

  group('LogMeasurementUseCase', () {
    test('should log measurement when valid', () async {
      when(() => mockRepo.logMeasurement(any()))
          .thenAnswer((_) async => Success(tMeasurement));

      final useCase = LogMeasurementUseCase(mockRepo);
      final result = await useCase.execute(tMeasurement);

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.waist, 82.0);
    });

    test('should return ValidationFailure when all values are null', () async {
      final emptyMeasurement = BodyMeasurement(
        id: 'm-2',
        measuredAt: DateTime.now(),
      );

      final useCase = LogMeasurementUseCase(mockRepo);
      final result = await useCase.execute(emptyMeasurement);

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });
  });

  group('DeleteMeasurementUseCase', () {
    test('should delete measurement when id is non-empty', () async {
      when(() => mockRepo.deleteMeasurement('m-1'))
          .thenAnswer((_) async => const Success(null));

      final useCase = DeleteMeasurementUseCase(mockRepo);
      final result = await useCase.execute('m-1');

      expect(result.isSuccess, isTrue);
    });

    test('should return ValidationFailure when id is empty', () async {
      final useCase = DeleteMeasurementUseCase(mockRepo);
      final result = await useCase.execute('');

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });
  });
}
