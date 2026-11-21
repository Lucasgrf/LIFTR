import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';

/// Contract definition for exercise data operations.
abstract class ExerciseRepository {
  /// Fetches all active exercises (global exercises + user-created exercises).
  Future<Result<List<Exercise>, Failure>> getExercises();

  /// Fetches a single exercise by its unique identifier.
  Future<Result<Exercise, Failure>> getExerciseById(String id);

  /// Creates a custom exercise belonging to the authenticated user.
  Future<Result<Exercise, Failure>> createCustomExercise({
    required String name,
    required String primaryMuscleGroup,
    List<String>? secondaryMuscles,
    String? equipment,
    String? movementPattern,
    String? instructions,
    String? commonMistakes,
    String? videoUrl,
    String? personalNotes,
  });

  /// Updates personal notes for an exercise.
  Future<Result<Exercise, Failure>> updateExerciseNotes({
    required String exerciseId,
    required String notes,
  });

  /// Soft deletes a user's custom exercise.
  Future<Result<void, Failure>> deleteCustomExercise(String id);
}
