import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/weight_repository.dart';

class LogWeightEntryUseCase {
  const LogWeightEntryUseCase(this._repository);

  final WeightRepository _repository;

  Future<Result<WeightEntry, Failure>> execute({
    required double weightKg,
    required DateTime measuredAt,
    String? notes,
  }) {
    if (!weightKg.isFinite || weightKg <= 0 || weightKg > 500) {
      return Future.value(
        const Err(ValidationFailure('Peso inválido. Informe um valor entre 1 e 500 kg.')),
      );
    }

    return _repository.logWeight(
      weightKg: weightKg,
      measuredAt: measuredAt,
      notes: notes,
    );
  }
}
