import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';

/// Contract definition for training plan and workout data operations.
abstract class TrainingRepository {
  /// Fetches all training plans for the authenticated user.
  Future<Result<List<TrainingPlan>, Failure>> getTrainingPlans();

  /// Fetches the currently active training plan.
  Future<Result<TrainingPlan?, Failure>> getActiveTrainingPlan();

  /// Fetches a training plan by its ID, with all workouts and exercises nested.
  Future<Result<TrainingPlan, Failure>> getTrainingPlanById(String id);

  /// Creates a new training plan.
  Future<Result<TrainingPlan, Failure>> createTrainingPlan({
    required String name,
    String? description,
    bool isActive = false,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Sets a specific training plan as active, deactivating any previously active plan.
  Future<Result<TrainingPlan, Failure>> setActiveTrainingPlan(String planId);

  /// Adds a new workout to a training plan.
  Future<Result<Workout, Failure>> addWorkoutToPlan({
    required String trainingPlanId,
    required String name,
    int? dayOfWeek,
    int sortOrder = 0,
    String? notes,
    int? estimatedDurationMinutes,
  });

  /// Adds an exercise from the library into a workout.
  Future<Result<WorkoutExercise, Failure>> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
    int sortOrder = 0,
    String? notes,
    List<SetTemplate>? initialSetTemplates,
  });

  /// Updates all set templates for a workout exercise.
  Future<Result<List<SetTemplate>, Failure>> configureSetTemplates({
    required String workoutExerciseId,
    required List<SetTemplate> setTemplates,
  });

  /// Reorders the exercises in a workout based on the given ordered list of IDs.
  Future<Result<void, Failure>> reorderWorkoutExercises({
    required String workoutId,
    required List<String> orderedWorkoutExerciseIds,
  });

  /// Soft deletes a training plan.
  Future<Result<void, Failure>> deleteTrainingPlan(String planId);

  /// Deletes a workout within a plan.
  Future<Result<void, Failure>> deleteWorkout(String workoutId);

  /// Deletes an exercise from a workout.
  Future<Result<void, Failure>> deleteWorkoutExercise(String workoutExerciseId);
}
