import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';

class StartWorkoutSessionUseCase {
  const StartWorkoutSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<Result<WorkoutSession, Failure>> execute({
    String? workoutId,
    String? workoutName,
    List<SessionExercise>? initialExercises,
  }) {
    return _repository.startSession(
      workoutId: workoutId,
      workoutName: workoutName,
      initialExercises: initialExercises,
    );
  }
}
