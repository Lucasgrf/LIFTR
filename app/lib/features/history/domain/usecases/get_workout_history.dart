import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/history/domain/repositories/history_repository.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

class GetWorkoutHistoryUseCase {
  const GetWorkoutHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  Future<Result<List<WorkoutSession>, Failure>> execute({
    int limit = 50,
    int offset = 0,
  }) {
    return _repository.getCompletedSessions(
      limit: limit,
      offset: offset,
    );
  }
}
