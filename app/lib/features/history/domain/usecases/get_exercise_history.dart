import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/history/domain/entities/exercise_history_record.dart';
import 'package:personal_fitness_os/features/history/domain/repositories/history_repository.dart';

class GetExerciseHistoryUseCase {
  const GetExerciseHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  Future<Result<List<ExerciseHistoryRecord>, Failure>> execute(
    String exerciseId, {
    int limit = 30,
  }) {
    if (exerciseId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('ID do exercício é obrigatório.')),
      );
    }
    if (limit <= 0) {
      return Future.value(
        const Err(ValidationFailure('Limite de registros deve ser maior que zero.')),
      );
    }
    return _repository.getExerciseHistory(exerciseId, limit: limit);
  }
}
