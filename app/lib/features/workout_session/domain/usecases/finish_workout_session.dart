import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';

class FinishWorkoutSessionUseCase {
  const FinishWorkoutSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<Result<WorkoutSession, Failure>> execute({
    required String sessionId,
    required int durationSeconds,
    double? perceivedExertion,
    Mood? mood,
    String? notes,
  }) {
    if (sessionId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O ID da sessão não pode ser vazio.')),
      );
    }
    if (durationSeconds < 0) {
      return Future.value(
        const Err(ValidationFailure('A duração não pode ser negativa.')),
      );
    }

    return _repository.finishSession(
      sessionId: sessionId.trim(),
      durationSeconds: durationSeconds,
      perceivedExertion: perceivedExertion,
      mood: mood,
      notes: notes?.trim(),
    );
  }
}
