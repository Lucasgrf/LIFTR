import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';

class ConfigureSetTemplatesUseCase {
  const ConfigureSetTemplatesUseCase(this._repository);

  final TrainingRepository _repository;

  Future<Result<List<SetTemplate>, Failure>> execute({
    required String workoutExerciseId,
    required List<SetTemplate> setTemplates,
  }) {
    if (workoutExerciseId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('O ID do exercício no treino não pode ser vazio.')),
      );
    }
    if (setTemplates.isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Deve haver ao menos 1 série configurada.')),
      );
    }

    return _repository.configureSetTemplates(
      workoutExerciseId: workoutExerciseId.trim(),
      setTemplates: setTemplates,
    );
  }
}
