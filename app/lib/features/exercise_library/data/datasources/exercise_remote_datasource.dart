import 'package:personal_fitness_os/features/exercise_library/data/models/exercise_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ExerciseRemoteDataSource {
  Future<List<ExerciseModel>> fetchExercises();
  Future<ExerciseModel> fetchExerciseById(String id);
  Future<ExerciseModel> insertCustomExercise(Map<String, dynamic> data);
  Future<ExerciseModel> updateExerciseNotes(String exerciseId, String notes);
  Future<void> softDeleteExercise(String id);
}

class SupabaseExerciseRemoteDataSource implements ExerciseRemoteDataSource {
  SupabaseExerciseRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  @override
  Future<List<ExerciseModel>> fetchExercises() async {
    final response = await _supabaseClient
        .from('exercises')
        .select()
        .filter('deleted_at', 'is', null)
        .order('name', ascending: true);

    return (response as List<dynamic>)
        .map((json) => ExerciseModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ExerciseModel> fetchExerciseById(String id) async {
    final response = await _supabaseClient
        .from('exercises')
        .select()
        .eq('id', id)
        .filter('deleted_at', 'is', null)
        .single();

    return ExerciseModel.fromJson(response);
  }

  @override
  Future<ExerciseModel> insertCustomExercise(Map<String, dynamic> data) async {
    final user = _supabaseClient.auth.currentUser;
    final payload = {
      ...data,
      'is_custom': true,
      if (user != null) 'user_id': user.id,
    };

    final response = await _supabaseClient
        .from('exercises')
        .insert(payload)
        .select()
        .single();

    return ExerciseModel.fromJson(response);
  }

  @override
  Future<ExerciseModel> updateExerciseNotes(String exerciseId, String notes) async {
    final response = await _supabaseClient
        .from('exercises')
        .update({'personal_notes': notes})
        .eq('id', exerciseId)
        .select()
        .single();

    return ExerciseModel.fromJson(response);
  }

  @override
  Future<void> softDeleteExercise(String id) async {
    await _supabaseClient
        .from('exercises')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
