import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';

class GetActiveWorkoutSessionUseCase {
  const GetActiveWorkoutSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<Result<WorkoutSession?, Failure>> execute() {
    return _repository.getActiveSession();
  }
}
