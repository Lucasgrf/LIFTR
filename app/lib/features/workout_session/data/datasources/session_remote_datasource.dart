import 'package:personal_fitness_os/features/workout_session/data/models/logged_set_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/session_exercise_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/workout_session_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SessionRemoteDataSource {
  Future<WorkoutSessionModel?> fetchActiveSession();
  Future<WorkoutSessionModel> fetchSessionById(String id);
  Future<WorkoutSessionModel> insertSession(Map<String, dynamic> data);
  Future<SessionExerciseModel> insertSessionExercise(Map<String, dynamic> data);
  Future<SessionExerciseModel> updateSessionExercise(
    String sessionExerciseId,
    Map<String, dynamic> data,
  );
  Future<LoggedSetModel> insertLoggedSet(Map<String, dynamic> data);
  Future<void> deleteLoggedSet(String setId);
  Future<WorkoutSessionModel> updateSession(String sessionId, Map<String, dynamic> data);
}

class SupabaseSessionRemoteDataSource implements SessionRemoteDataSource {
  SupabaseSessionRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  static const _nestedQuery = '''
    *,
    workouts (name),
    workout_session_exercises (
      *,
      exercises (*),
      logged_sets (*)
    )
  ''';

  @override
  Future<WorkoutSessionModel?> fetchActiveSession() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return null;

    final response = await _supabaseClient
        .from('workout_sessions')
        .select(_nestedQuery)
        .eq('user_id', user.id)
        .eq('status', 'in_progress')
        .order('started_at', ascending: false)
        .maybeSingle();

    if (response == null) return null;
    return WorkoutSessionModel.fromJson(response);
  }

  @override
  Future<WorkoutSessionModel> fetchSessionById(String id) async {
    final response = await _supabaseClient
        .from('workout_sessions')
        .select(_nestedQuery)
        .eq('id', id)
        .single();

    return WorkoutSessionModel.fromJson(response);
  }

  @override
  Future<WorkoutSessionModel> insertSession(Map<String, dynamic> data) async {
    final user = _supabaseClient.auth.currentUser;
    final payload = {
      ...data,
      if (user != null) 'user_id': user.id,
    };

    final response = await _supabaseClient
        .from('workout_sessions')
        .insert(payload)
        .select(_nestedQuery)
        .single();

    return WorkoutSessionModel.fromJson(response);
  }

  @override
  Future<SessionExerciseModel> insertSessionExercise(Map<String, dynamic> data) async {
    final response = await _supabaseClient
        .from('workout_session_exercises')
        .insert(data)
        .select('*, exercises(*), logged_sets(*)')
        .single();

    return SessionExerciseModel.fromJson(response);
  }

  @override
  Future<SessionExerciseModel> updateSessionExercise(
    String sessionExerciseId,
    Map<String, dynamic> data,
  ) async {
    final response = await _supabaseClient
        .from('workout_session_exercises')
        .update(data)
        .eq('id', sessionExerciseId)
        .select('*, exercises(*), logged_sets(*)')
        .single();

    return SessionExerciseModel.fromJson(response);
  }

  @override
  Future<LoggedSetModel> insertLoggedSet(Map<String, dynamic> data) async {
    final response = await _supabaseClient
        .from('logged_sets')
        .insert(data)
        .select()
        .single();

    return LoggedSetModel.fromJson(response);
  }

  @override
  Future<void> deleteLoggedSet(String setId) async {
    await _supabaseClient
        .from('logged_sets')
        .delete()
        .eq('id', setId);
  }

  @override
  Future<WorkoutSessionModel> updateSession(
    String sessionId,
    Map<String, dynamic> data,
  ) async {
    final response = await _supabaseClient
        .from('workout_sessions')
        .update(data)
        .eq('id', sessionId)
        .select(_nestedQuery)
        .single();

    return WorkoutSessionModel.fromJson(response);
  }
}
