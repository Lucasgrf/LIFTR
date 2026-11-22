import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';

class LogSetUseCase {
  const LogSetUseCase(this._repository);

  final SessionRepository _repository;

  Future<Result<LoggedSet, Failure>> execute({
    required String sessionExerciseId,
    required int setNumber,
    SetType setType = SetType.working,
    required double weightKg,
    required int repsCompleted,
    int? durationSeconds,
    int? rirActual,
    double? rpeActual,
    int? restSecondsActual,
    ExecutionQuality? executionQuality,
    bool isWarmup = false,
    String? notes,
    List<DropSetEntry> dropSets = const [],
    String? existingSetId,
  }) {
    if (sessionExerciseId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('ID do exercício na sessão não pode ser vazio.')),
      );
    }
    if (repsCompleted < 0) {
      return Future.value(
        const Err(ValidationFailure('O número de repetições não pode ser negativo.')),
      );
    }
    if (durationSeconds != null && durationSeconds < 0) {
      return Future.value(
        const Err(ValidationFailure('A duração não pode ser negativa.')),
      );
    }
    if (weightKg < 0) {
      return Future.value(
        const Err(ValidationFailure('A carga não pode ser negativa.')),
      );
    }

    return _repository.logSet(
      sessionExerciseId: sessionExerciseId.trim(),
      setNumber: setNumber,
      setType: setType,
      weightKg: weightKg,
      repsCompleted: repsCompleted,
      durationSeconds: durationSeconds,
      rirActual: rirActual,
      rpeActual: rpeActual,
      restSecondsActual: restSecondsActual,
      executionQuality: executionQuality,
      isWarmup: isWarmup,
      notes: notes?.trim(),
      dropSets: dropSets,
      existingSetId: existingSetId,
    );
  }
}
