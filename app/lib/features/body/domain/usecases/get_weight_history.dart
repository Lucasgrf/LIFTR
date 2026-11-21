import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/weight_repository.dart';

class GetWeightHistoryUseCase {
  const GetWeightHistoryUseCase(this._repository);

  final WeightRepository _repository;

  Future<Result<List<WeightEntry>, Failure>> execute({
    int limit = 100,
    int offset = 0,
  }) {
    return _repository.getWeightHistory(
      limit: limit,
      offset: offset,
    );
  }
}
