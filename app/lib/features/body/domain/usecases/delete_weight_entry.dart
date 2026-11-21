import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/weight_repository.dart';

class DeleteWeightEntryUseCase {
  const DeleteWeightEntryUseCase(this._repository);

  final WeightRepository _repository;

  Future<Result<void, Failure>> execute(String entryId) {
    return _repository.deleteWeightEntry(entryId);
  }
}
