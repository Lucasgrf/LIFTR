import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';

class SwapSessionExerciseUseCase {
  const SwapSessionExerciseUseCase(this._repository);

  final SessionRepository _repository;

  Future<Result<SessionExercise, Failure>> execute({
    required String sessionExerciseId,
    required String newExerciseId,
    String? replacedExerciseId,
  }) {
    if (sessionExerciseId.trim().isEmpty) {
      return Future.value(
        const Err(
          ValidationFailure('O ID do exercício da sessão não pode ser vazio.'),
        ),
      );
    }
    if (newExerciseId.trim().isEmpty) {
      return Future.value(
        const Err(
          ValidationFailure('O ID do novo exercício não pode ser vazio.'),
        ),
      );
    }

    return _repository.swapSessionExercise(
      sessionExerciseId: sessionExerciseId.trim(),
      newExerciseId: newExerciseId.trim(),
      replacedExerciseId: replacedExerciseId?.trim(),
    );
  }
}
