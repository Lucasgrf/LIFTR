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
    final historiesResult = await _repository.getRecentExercisePerformances(
      exerciseId,
      limit: ProgressionEngine.requiredCeilingHitsForIncrease,
    );

    if (historiesResult is Err<List<ExercisePerformanceHistory>, Failure>) {
      return Err(historiesResult.failure);
    }

    final histories =
        (historiesResult as Success<List<ExercisePerformanceHistory>, Failure>)
            .value;

    if (histories.isEmpty || histories.first.loggedSets.isEmpty) {
      return Success(
        ProgressionRecommendation(
          type: ProgressionType.maintain,
          suggestedWeightKg: 0.0,
          weightDeltaKg: 0.0,
          rationale:
              'Primeira vez executando este exercício. Defina uma carga confortável para iniciar.',
          previousSummary: null,
          targetRepsMin: targetRepsMin,
          targetRepsMax: targetRepsMax,
          targetRir: targetRir,
          requiredCeilingHits: ProgressionEngine.requiredCeilingHitsForIncrease,
        ),
      );
    }

    final recommendation = engine.evaluate(
      history: histories.first,
      previousHistories: histories.skip(1).toList(),
      targetRepsMin: targetRepsMin,
      targetRepsMax: targetRepsMax,
      targetRir: targetRir,
      equipment: equipment,
    );

    return Success(recommendation);
  }
}
