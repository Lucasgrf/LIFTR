import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';

class AddWorkoutToPlanUseCase {
  const AddWorkoutToPlanUseCase(this._repository);

  final TrainingRepository _repository;

  Future<Result<Workout, Failure>> execute({
    required String trainingPlanId,
    required String name,
    int? dayOfWeek,
    int sortOrder = 0,
    String? notes,
    int? estimatedDurationMinutes,
  }) {
    if (trainingPlanId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O ID do programa não pode ser vazio.')),
      );
    }
    if (name.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O nome do treino é obrigatório.')),
      );
    }
    if (dayOfWeek != null && (dayOfWeek < 0 || dayOfWeek > 6)) {
      return Future.value(
        const Err(ValidationFailure('O dia da semana deve ser entre 0 (Domingo) e 6 (Sábado).')),
      );
    }

    return _repository.addWorkoutToPlan(
      trainingPlanId: trainingPlanId.trim(),
      name: name.trim(),
      dayOfWeek: dayOfWeek,
      sortOrder: sortOrder,
      notes: notes?.trim(),
      estimatedDurationMinutes: estimatedDurationMinutes,
    );
  }
}
