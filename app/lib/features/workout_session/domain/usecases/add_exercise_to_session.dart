import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';

class AddExerciseToSessionUseCase {
  const AddExerciseToSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<Result<SessionExercise, Failure>> execute({
    required String sessionId,
    required String exerciseId,
    int sortOrder = 0,
    String? notes,
    int targetRestSeconds = AppConstants.defaultRestSeconds,
    int targetSetsCount = 3,
  }) {
    if (sessionId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O ID da sessão não pode ser vazio.')),
      );
    }
    if (exerciseId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O ID do exercício não pode ser vazio.')),
      );
    }

    return _repository.addExerciseToSession(
      sessionId: sessionId.trim(),
      exerciseId: exerciseId.trim(),
      sortOrder: sortOrder,
      notes: notes?.trim(),
      targetRestSeconds: targetRestSeconds,
      targetSetsCount: targetSetsCount,
    );
  }
}
