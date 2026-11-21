import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/history/domain/entities/exercise_history_record.dart';
import 'package:personal_fitness_os/features/history/domain/entities/history_event_type.dart';
import 'package:personal_fitness_os/features/history/domain/entities/timeline_event.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

/// Contract definition for historical workout sessions, timeline aggregation and exercise progression.
abstract class HistoryRepository {
  /// Fetches paginated completed workout sessions ordered by completed_at desc.
  Future<Result<List<WorkoutSession>, Failure>> getCompletedSessions({
    int limit = 50,
    int offset = 0,
  });

  /// Fetches completed workout sessions within a specific date range.
  Future<Result<List<WorkoutSession>, Failure>> getSessionsInRange({
    required DateTime start,
    required DateTime end,
  });

  /// Fetches a unified chronological timeline across workouts, weight, nutrition, and goals.
  Future<Result<List<TimelineEvent>, Failure>> getUnifiedTimeline({
    HistoryEventType? type,
    DateTime? start,
    DateTime? end,
    int limit = 50,
  });

  /// Fetches historical session records for a specific exercise.
  Future<Result<List<ExerciseHistoryRecord>, Failure>> getExerciseHistory(
    String exerciseId, {
    int limit = 30,
  });
}
