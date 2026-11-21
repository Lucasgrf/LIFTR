import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';

abstract class ProgressionRepository {
  /// Fetches the last completed workout session performance for a given exercise.
  Future<Result<ExercisePerformanceHistory?, Failure>> getLastExercisePerformance(
    String exerciseId,
  );
}
