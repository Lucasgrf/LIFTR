import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/body_measurement.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/measurement_repository.dart';

class GetMeasurementsUseCase {
  const GetMeasurementsUseCase(this._repository);

  final MeasurementRepository _repository;

  Future<Result<List<BodyMeasurement>, Failure>> execute({int limit = 50}) {
    if (limit <= 0) {
      return Future.value(
        const Err(ValidationFailure('Limite deve ser maior que zero.')),
      );
    }
    return _repository.getMeasurements(limit: limit);
  }
}
