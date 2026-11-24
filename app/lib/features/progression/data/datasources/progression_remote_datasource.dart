import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/logged_set_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProgressionRemoteDataSource {
  Future<ExercisePerformanceHistory?> fetchLastExercisePerformance(
    String exerciseId,
  );

  Future<List<ExercisePerformanceHistory>> fetchRecentExercisePerformances(
    String exerciseId, {
    int limit = 2,
  });
}

class SupabaseProgressionRemoteDataSource
    implements ProgressionRemoteDataSource {
  SupabaseProgressionRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  @override
  Future<ExercisePerformanceHistory?> fetchLastExercisePerformance(
    String exerciseId,
  ) async {
    final recent = await fetchRecentExercisePerformances(exerciseId, limit: 1);
    return recent.isEmpty ? null : recent.first;
  }

  @override
  Future<List<ExercisePerformanceHistory>> fetchRecentExercisePerformances(
    String exerciseId, {
    int limit = 2,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final response = await _supabaseClient
        .from('workout_session_exercises')
        .select('''
          id,
          session_id,
          exercise_id,
          workout_sessions!inner (
            id,
            user_id,
            workout_id,
            status,
            completed_at,
            started_at,
            workouts (name)
          ),
          logged_sets (*)
        ''')
        .eq('exercise_id', exerciseId)
        .eq('workout_sessions.user_id', user.id)
        .eq('workout_sessions.status', 'completed')
        .order('completed_at', referencedTable: 'workout_sessions', ascending: false)
        .limit(limit + 8);

    final rows = response as List<dynamic>;
    final results = <ExercisePerformanceHistory>[];

    for (final rawRow in rows) {
      final row = rawRow as Map<String, dynamic>;
      final sessionMap = row['workout_sessions'] as Map<String, dynamic>?;
      final workoutMap = sessionMap?['workouts'] as Map<String, dynamic>?;
      final workoutName = workoutMap?['name'] as String? ?? 'Treino';
      final completedAtStr = sessionMap?['completed_at'] as String? ??
          sessionMap?['started_at'] as String?;
      final date = completedAtStr != null
          ? DateTime.parse(completedAtStr)
          : DateTime.now();

      final setsJson = (row['logged_sets'] as List<dynamic>?) ?? [];
      final sets = setsJson
          .map((s) => LoggedSetModel.fromJson(s as Map<String, dynamic>).toDomain())
          .toList();

      final history = ExercisePerformanceHistory(
        exerciseId: exerciseId,
        workoutSessionId: row['session_id'] as String? ?? '',
        workoutName: workoutName,
        date: date,
        loggedSets: sets,
      );
      if (history.workingSets.isEmpty) continue;

      results.add(history);
    }

    results.sort((a, b) => b.date.compareTo(a.date));
    return results.take(limit).toList();
  }
}
