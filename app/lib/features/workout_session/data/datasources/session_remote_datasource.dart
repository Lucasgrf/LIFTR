import 'package:personal_fitness_os/features/workout_session/data/models/logged_set_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/session_exercise_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/workout_session_model.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
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
  Future<LoggedSetModel> updateLoggedSet(String setId, Map<String, dynamic> data);
  Future<void> deleteLoggedSet(String setId);
  Future<WorkoutSessionModel> updateSession(
    String sessionId,
    Map<String, dynamic> data,
  );
}

class SupabaseSessionRemoteDataSource implements SessionRemoteDataSource {
  SupabaseSessionRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  static const _nestedQuery = '''
    *,
    workouts (
      name,
      workout_exercises (
        id,
        exercise_id,
        sort_order,
        set_templates (*)
      )
    ),
    workout_session_exercises (
      *,
      exercises!workout_session_exercises_exercise_id_fkey (*),
      logged_sets (*)
    )
  ''';

  bool _isMissingColumnError(PostgrestException e, String columnHint) {
    final msg = '${e.code ?? ''} ${e.message} ${e.details ?? ''}'.toLowerCase();
    return msg.contains('pgrst204') ||
        msg.contains('42703') ||
        msg.contains(columnHint.toLowerCase());
  }

  Map<String, dynamic> _fallbackDropsPayload(Map<String, dynamic> data) {
    final rawDrops = data['drop_sets'];
    final drops = <DropSetEntry>[];
    if (rawDrops is List) {
      for (final item in rawDrops) {
        if (item is Map) {
          drops.add(DropSetEntry.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final cleanNotes = LoggedSetModel.extractDropsFromNotes(
      data['notes'] as String?,
    ).cleanNotes;
    final encodedNotes = LoggedSetModel.attachDropsMarkerToNotes(
      cleanNotes,
      drops,
    );
    return {
      ...data,
      if (encodedNotes != null) 'notes': encodedNotes else 'notes': null,
    }..remove('drop_sets');
  }

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
  Future<SessionExerciseModel> insertSessionExercise(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabaseClient
          .from('workout_session_exercises')
          .insert(data)
          .select(
            '*, exercises!workout_session_exercises_exercise_id_fkey(*), logged_sets(*)',
          )
          .single();

      return SessionExerciseModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (!_isMissingColumnError(e, 'target_')) rethrow;
      final stripped = Map<String, dynamic>.from(data)
        ..remove('target_sets_count')
        ..remove('target_reps_min')
        ..remove('target_reps_max')
        ..remove('target_rir')
        ..remove('target_rest_seconds');
      final response = await _supabaseClient
          .from('workout_session_exercises')
          .insert(stripped)
          .select(
            '*, exercises!workout_session_exercises_exercise_id_fkey(*), logged_sets(*)',
          )
          .single();
      return SessionExerciseModel.fromJson(response);
    }
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
        .select(
          '*, exercises!workout_session_exercises_exercise_id_fkey(*), logged_sets(*)',
        )
        .single();

    return SessionExerciseModel.fromJson(response);
  }

  @override
  Future<LoggedSetModel> insertLoggedSet(Map<String, dynamic> data) async {
    try {
      final response = await _supabaseClient
          .from('logged_sets')
          .insert(data)
          .select()
          .single();

      return LoggedSetModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (!data.containsKey('drop_sets') ||
          !_isMissingColumnError(e, 'drop_sets')) {
        rethrow;
      }
      final fallback = _fallbackDropsPayload(data);
      final response = await _supabaseClient
          .from('logged_sets')
          .insert(fallback)
          .select()
          .single();
      return LoggedSetModel.fromJson(response);
    }
  }

  @override
  Future<LoggedSetModel> updateLoggedSet(
    String setId,
    Map<String, dynamic> data,
  ) async {
    final updatePayload = Map<String, dynamic>.from(data)..remove('id');
    try {
      final response = await _supabaseClient
          .from('logged_sets')
          .update(updatePayload)
          .eq('id', setId)
          .select()
          .single();

      return LoggedSetModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (!updatePayload.containsKey('drop_sets') ||
          !_isMissingColumnError(e, 'drop_sets')) {
        rethrow;
      }
      final fallback = _fallbackDropsPayload(updatePayload);
      final response = await _supabaseClient
          .from('logged_sets')
          .update(fallback)
          .eq('id', setId)
          .select()
          .single();
      return LoggedSetModel.fromJson(response);
    }
  }

  @override
  Future<void> deleteLoggedSet(String setId) async {
    await _supabaseClient.from('logged_sets').delete().eq('id', setId);
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
