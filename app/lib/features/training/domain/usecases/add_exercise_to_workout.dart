import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';

class AddExerciseToWorkoutUseCase {
  const AddExerciseToWorkoutUseCase(this._repository);

  final TrainingRepository _repository;

  Future<Result<WorkoutExercise, Failure>> execute({
    required String workoutId,
    required String exerciseId,
    int sortOrder = 0,
    String? notes,
    List<SetTemplate>? initialSetTemplates,
  }) {
    if (workoutId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O ID do treino não pode ser vazio.')),
      );
    }
    if (exerciseId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O ID do exercício não pode ser vazio.')),
      );
    }

    return _repository.addExerciseToWorkout(
      workoutId: workoutId.trim(),
      exerciseId: exerciseId.trim(),
      sortOrder: sortOrder,
      notes: notes?.trim(),
      initialSetTemplates: initialSetTemplates,
    );
  }
}
