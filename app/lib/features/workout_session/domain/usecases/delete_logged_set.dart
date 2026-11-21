import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';

class DeleteLoggedSetUseCase {
  const DeleteLoggedSetUseCase(this._repository);

  final SessionRepository _repository;

  Future<Result<void, Failure>> execute(String setId) {
    if (setId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O ID da série não pode ser vazio.')),
      );
    }
    return _repository.deleteLoggedSet(setId.trim());
  }
}
