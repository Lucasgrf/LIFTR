import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

/// Contract definition for live workout session and set logging operations.
abstract class SessionRepository {
  /// Starts a new live workout session, optionally prepopulated from a prescribed workout.
  Future<Result<WorkoutSession, Failure>> startSession({
    String? workoutId,
    String? workoutName,
    List<SessionExercise>? initialExercises,
  });

  /// Fetches the currently ongoing workout session (status == in_progress), if any.
  Future<Result<WorkoutSession?, Failure>> getActiveSession();

  /// Fetches a specific session by its ID with all exercises and logged sets nested.
  Future<Result<WorkoutSession, Failure>> getSessionById(String id);

  /// Logs or updates a completed set within an active session exercise.
  Future<Result<LoggedSet, Failure>> logSet({
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
  });

  /// Deletes a logged set from a session.
  Future<Result<void, Failure>> deleteLoggedSet(String setId);

  /// Dynamically adds an exercise to an ongoing workout session.
  Future<Result<SessionExercise, Failure>> addExerciseToSession({
    required String sessionId,
    required String exerciseId,
    int sortOrder = 0,
    String? notes,
    int targetRestSeconds = AppConstants.defaultRestSeconds,
    int targetSetsCount = 3,
  });

  /// Replaces the exercise of an active session exercise row, preserving the original exercise ID.
  Future<Result<SessionExercise, Failure>> swapSessionExercise({
    required String sessionExerciseId,
    required String newExerciseId,
    String? replacedExerciseId,
  });

  /// Finalizes the workout session, computing duration, exertion, execution score and mood.
  Future<Result<WorkoutSession, Failure>> finishSession({
    required String sessionId,
    required int durationSeconds,
    double? perceivedExertion,
    int? executionScore,
    Mood? mood,
    String? notes,
  });

  /// Abandons/discards an ongoing workout session.
  Future<Result<void, Failure>> abandonSession(String sessionId);
}
