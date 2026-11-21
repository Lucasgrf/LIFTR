import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/body_measurement.dart';

abstract class MeasurementRepository {
  Future<Result<List<BodyMeasurement>, Failure>> getMeasurements({
    int limit = 50,
  });

  Future<Result<BodyMeasurement?, Failure>> getLatestMeasurement();

  Future<Result<BodyMeasurement, Failure>> logMeasurement(
    BodyMeasurement measurement,
  );

  Future<Result<void, Failure>> deleteMeasurement(String id);
}
