import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';

class RestoreLoggedSetUseCase {
  const RestoreLoggedSetUseCase(this._repository);

  final SessionRepository _repository;

  Future<Result<LoggedSet, Failure>> execute(LoggedSet set) {
    if (set.id.trim().isEmpty || set.sessionExerciseId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Série inválida para restauração.')),
      );
    }
    return _repository.restoreLoggedSet(set);
  }
}
