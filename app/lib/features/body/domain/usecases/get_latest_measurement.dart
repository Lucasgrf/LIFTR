import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/body_measurement.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/measurement_repository.dart';

class GetLatestMeasurementUseCase {
  const GetLatestMeasurementUseCase(this._repository);

  final MeasurementRepository _repository;

  Future<Result<BodyMeasurement?, Failure>> execute() {
    return _repository.getLatestMeasurement();
  }
}
