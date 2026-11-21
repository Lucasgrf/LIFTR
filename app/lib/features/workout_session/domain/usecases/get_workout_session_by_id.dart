import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';

class GetWorkoutSessionByIdUseCase {
  const GetWorkoutSessionByIdUseCase(this._repository);

  final SessionRepository _repository;

  Future<Result<WorkoutSession, Failure>> execute(String id) {
    if (id.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O ID da sessão não pode ser vazio.')),
      );
    }
    return _repository.getSessionById(id);
  }
}
