import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/progression_recommendation.dart';
import 'package:personal_fitness_os/features/progression/domain/repositories/progression_repository.dart';
import 'package:personal_fitness_os/features/progression/domain/services/progression_engine.dart';

class CalculateProgressionUseCase {
  const CalculateProgressionUseCase({
    required ProgressionRepository repository,
    this.engine = const ProgressionEngine(),
  }) : _repository = repository;

  final ProgressionRepository _repository;
  final ProgressionEngine engine;

  Future<Result<ProgressionRecommendation, Failure>> execute({
    required String exerciseId,
    required int targetRepsMin,
    required int targetRepsMax,
    int targetRir = 2,
    String? equipment,
  }) async {
    final historyResult = await _repository.getLastExercisePerformance(exerciseId);

    if (historyResult is Err<ExercisePerformanceHistory?, Failure>) {
      return Err(historyResult.failure);
    }

    final history = (historyResult as Success<ExercisePerformanceHistory?, Failure>).value;

    if (history == null || history.loggedSets.isEmpty) {
      return Success(
        ProgressionRecommendation(
          type: ProgressionType.maintain,
          suggestedWeightKg: 0.0,
          weightDeltaKg: 0.0,
          rationale: 'Primeira vez executando este exercício. Defina uma carga confortável para iniciar.',
          previousSummary: null,
          targetRepsMin: targetRepsMin,
          targetRepsMax: targetRepsMax,
          targetRir: targetRir,
        ),
      );
    }

    final recommendation = engine.evaluate(
      history: history,
      targetRepsMin: targetRepsMin,
      targetRepsMax: targetRepsMax,
      targetRir: targetRir,
      equipment: equipment,
    );

    return Success(recommendation);
  }
}
