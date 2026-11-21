import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/body_measurement.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/measurement_repository.dart';

class LogMeasurementUseCase {
  const LogMeasurementUseCase(this._repository);

  final MeasurementRepository _repository;

  Future<Result<BodyMeasurement, Failure>> execute(BodyMeasurement measurement) {
    // Validate that at least one measurement is provided
    final hasAny = measurement.waist != null ||
        measurement.chest != null ||
        measurement.armLeft != null ||
        measurement.armRight != null ||
        measurement.thighLeft != null ||
        measurement.thighRight != null ||
        measurement.calfLeft != null ||
        measurement.calfRight != null ||
        measurement.hip != null ||
        measurement.shoulder != null ||
        measurement.neck != null ||
        measurement.forearmLeft != null ||
        measurement.forearmRight != null;

    if (!hasAny) {
      return Future.value(
        const Err(ValidationFailure('Informe pelo menos uma medida corporal.')),
      );
    }

    return _repository.logMeasurement(measurement);
  }
}
