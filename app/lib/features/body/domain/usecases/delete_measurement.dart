import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/measurement_repository.dart';

class DeleteMeasurementUseCase {
  const DeleteMeasurementUseCase(this._repository);

  final MeasurementRepository _repository;

  Future<Result<void, Failure>> execute(String id) {
    if (id.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('ID da medição inválido.')),
      );
    }
    return _repository.deleteMeasurement(id);
  }
}
