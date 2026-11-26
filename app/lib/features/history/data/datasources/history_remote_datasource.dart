import 'package:personal_fitness_os/features/history/domain/entities/exercise_history_record.dart';
import 'package:personal_fitness_os/features/history/domain/entities/history_event_type.dart';
import 'package:personal_fitness_os/features/history/domain/entities/timeline_event.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/workout_session_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class HistoryRemoteDataSource {
  Future<List<WorkoutSessionModel>> fetchCompletedSessions({
    int limit = 50,
    int offset = 0,
  });

  Future<List<WorkoutSessionModel>> fetchSessionsInRange({
    required DateTime start,
    required DateTime end,
  });

  Future<List<TimelineEvent>> fetchUnifiedTimeline({
    HistoryEventType? type,
    DateTime? start,
    DateTime? end,
    int limit = 50,
  });

  Future<List<ExerciseHistoryRecord>> fetchExerciseHistory(
    String exerciseId, {
    int limit = 30,
  });
}

class SupabaseHistoryRemoteDataSource implements HistoryRemoteDataSource {
  SupabaseHistoryRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  static const _nestedQuery = '''
    *,
    workouts (name),
    workout_session_exercises (
      *,
      exercises!workout_session_exercises_exercise_id_fkey (*),
      logged_sets (*)
    )
  ''';

  @override
  Future<List<WorkoutSessionModel>> fetchCompletedSessions({
    int limit = 50,
    int offset = 0,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final response = await _supabaseClient
        .from('workout_sessions')
        .select(_nestedQuery)
        .eq('user_id', user.id)
        .eq('status', 'completed')
        .order('completed_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List<dynamic>)
        .map((e) => WorkoutSessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<WorkoutSessionModel>> fetchSessionsInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final response = await _supabaseClient
        .from('workout_sessions')
        .select(_nestedQuery)
        .eq('user_id', user.id)
        .eq('status', 'completed')
        .gte('completed_at', start.toIso8601String())
        .lte('completed_at', end.toIso8601String())
        .order('completed_at', ascending: true);

    return (response as List<dynamic>)
        .map((e) => WorkoutSessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TimelineEvent>> fetchUnifiedTimeline({
    HistoryEventType? type,
    DateTime? start,
    DateTime? end,
    int limit = 50,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final events = <TimelineEvent>[];

    // 1. Workout sessions
    if (type == null || type == HistoryEventType.workout) {
      var query = _supabaseClient
          .from('workout_sessions')
          .select('id, workout_name, workouts(name), duration_seconds, started_at, completed_at, workout_session_exercises(id)')
          .eq('user_id', user.id)
          .eq('status', 'completed');

      if (start != null) {
        query = query.gte('completed_at', start.toIso8601String());
      }
      if (end != null) {
        query = query.lte('completed_at', end.toIso8601String());
      }

      final sessionsRes = await query.order('completed_at', ascending: false).limit(limit);
      for (final row in sessionsRes as List<dynamic>) {
        final data = row as Map<String, dynamic>;
        final ts = DateTime.parse(
          (data['completed_at'] ?? data['started_at']) as String,
        );
        String name = data['workout_name'] as String? ?? 'Treino Avulso';
        if (data['workouts'] != null && data['workouts'] is Map<String, dynamic>) {
          name = data['workouts']['name'] as String? ?? name;
        }
        final duration = (data['duration_seconds'] as int?) ?? 0;
        final exercisesCount = (data['workout_session_exercises'] as List<dynamic>?)?.length ?? 0;

        events.add(
          TimelineEvent(
            id: 'ws-${data['id']}',
            type: HistoryEventType.workout,
            timestamp: ts,
            title: name,
            subtitle: '$exercisesCount exercícios • ${duration ~/ 60} min',
            referenceId: data['id'] as String,
            metadata: {'durationSeconds': duration},
          ),
        );
      }
    }

    // 2. Weight entries
    if (type == null || type == HistoryEventType.weight) {
      var query = _supabaseClient
          .from('weight_entries')
          .select('id, weight, measured_at, notes')
          .eq('user_id', user.id);

      if (start != null) {
        query = query.gte('measured_at', start.toIso8601String());
      }
      if (end != null) {
        query = query.lte('measured_at', end.toIso8601String());
      }

      final weightRes = await query.order('measured_at', ascending: false).limit(limit);
      for (final row in weightRes as List<dynamic>) {
        final data = row as Map<String, dynamic>;
        final ts = DateTime.parse(data['measured_at'] as String);
        final weight = (data['weight'] as num).toDouble();
        final notes = data['notes'] as String?;

        events.add(
          TimelineEvent(
            id: 'we-${data['id']}',
            type: HistoryEventType.weight,
            timestamp: ts,
            title: 'Pesagem: ${weight.toStringAsFixed(1)} kg',
            subtitle: notes != null && notes.isNotEmpty ? notes : 'Registro corporal',
            referenceId: data['id'] as String,
            metadata: {'weightKg': weight},
          ),
        );
      }
    }

    // 3. Daily nutrition
    if (type == null || type == HistoryEventType.nutrition) {
      var query = _supabaseClient
          .from('daily_nutrition')
          .select('id, date, total_calories, total_protein, total_carbs, total_fat')
          .eq('user_id', user.id);

      if (start != null) {
        query = query.gte('date', start.toIso8601String().split('T').first);
      }
      if (end != null) {
        query = query.lte('date', end.toIso8601String().split('T').first);
      }

      final nutritionRes = await query.order('date', ascending: false).limit(limit);
      for (final row in nutritionRes as List<dynamic>) {
        final data = row as Map<String, dynamic>;
        final ts = DateTime.parse(data['date'] as String);
        final cals = (data['total_calories'] as num?)?.toDouble() ?? 0.0;
        final p = (data['total_protein'] as num?)?.toDouble() ?? 0.0;
        final c = (data['total_carbs'] as num?)?.toDouble() ?? 0.0;
        final f = (data['total_fat'] as num?)?.toDouble() ?? 0.0;

        events.add(
          TimelineEvent(
            id: 'dn-${data['id']}',
            type: HistoryEventType.nutrition,
            timestamp: ts,
            title: 'Nutrição: ${cals.round()} kcal',
            subtitle: '${p.round()}P • ${c.round()}C • ${f.round()}G',
            referenceId: data['id'] as String,
            metadata: {'calories': cals, 'protein': p, 'carbs': c, 'fat': f},
          ),
        );
      }
    }

    // 4. Goal checkpoints
    if (type == null || type == HistoryEventType.goalCheckpoint) {
      var query = _supabaseClient
          .from('goal_checkpoints')
          .select('id, goal_id, value, recorded_at, notes, goals!inner(title, unit, user_id)')
          .eq('goals.user_id', user.id);

      if (start != null) {
        query = query.gte('recorded_at', start.toIso8601String());
      }
      if (end != null) {
        query = query.lte('recorded_at', end.toIso8601String());
      }

      final cpRes = await query.order('recorded_at', ascending: false).limit(limit);
      for (final row in cpRes as List<dynamic>) {
        final data = row as Map<String, dynamic>;
        final ts = DateTime.parse(data['recorded_at'] as String);
        final val = (data['value'] as num).toDouble();
        final goalsMap = data['goals'] as Map<String, dynamic>? ?? {};
        final goalTitle = goalsMap['title'] as String? ?? 'Meta';
        final goalUnit = goalsMap['unit'] as String? ?? '';
        final notes = data['notes'] as String?;

        events.add(
          TimelineEvent(
            id: 'gc-${data['id']}',
            type: HistoryEventType.goalCheckpoint,
            timestamp: ts,
            title: 'Check-in: ${val.toStringAsFixed(1)} $goalUnit'.trim(),
            subtitle: notes != null && notes.isNotEmpty
                ? 'Meta: $goalTitle • $notes'
                : 'Meta: $goalTitle',
            referenceId: data['goal_id'] as String,
            metadata: {'value': val},
          ),
        );
      }
    }

    // Sort descending by timestamp and take limit
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (events.length > limit) {
      return events.sublist(0, limit);
    }
    return events;
  }

  @override
  Future<List<ExerciseHistoryRecord>> fetchExerciseHistory(
    String exerciseId, {
    int limit = 30,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final response = await _supabaseClient
        .from('workout_session_exercises')
        .select('''
          id,
          exercise_id,
          workout_sessions!inner (
            id,
            workout_name,
            started_at,
            completed_at,
            status,
            user_id,
            workouts (name)
          ),
          logged_sets (
            id,
            set_type,
            weight_kg,
            reps_completed,
            rir_actual
          )
        ''')
        .eq('exercise_id', exerciseId)
        .eq('workout_sessions.user_id', user.id)
        .eq('workout_sessions.status', 'completed')
        .order('workout_sessions(completed_at)', ascending: false)
        .limit(limit);

    final records = <ExerciseHistoryRecord>[];

    for (final row in response as List<dynamic>) {
      final data = row as Map<String, dynamic>;
      final sessionMap = data['workout_sessions'] as Map<String, dynamic>;
      final setsList = (data['logged_sets'] as List<dynamic>?) ?? [];

      String sessionName = sessionMap['workout_name'] as String? ?? 'Treino Avulso';
      if (sessionMap['workouts'] != null && sessionMap['workouts'] is Map<String, dynamic>) {
        sessionName = sessionMap['workouts']['name'] as String? ?? sessionName;
      }

      final date = DateTime.parse(
        (sessionMap['completed_at'] ?? sessionMap['started_at']) as String,
      );

      double maxWeight = 0.0;
      int maxReps = 0;
      double max1Rm = 0.0;

      for (final s in setsList) {
        final setMap = s as Map<String, dynamic>;
        final w = (setMap['weight_kg'] as num?)?.toDouble() ?? 0.0;
        final r = (setMap['reps_completed'] as int?) ?? 0;
        if (w > maxWeight) maxWeight = w;
        if (r > maxReps) maxReps = r;

        final estimated1Rm = w * (1.0 + r / 30.0);
        if (estimated1Rm > max1Rm) max1Rm = estimated1Rm;
      }

      records.add(
        ExerciseHistoryRecord(
          sessionId: sessionMap['id'] as String,
          sessionName: sessionName,
          date: date,
          setsCount: setsList.length,
          topWeightKg: maxWeight,
          topReps: maxReps,
          bestEstimated1Rm: max1Rm,
        ),
      );
    }

    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }
}
