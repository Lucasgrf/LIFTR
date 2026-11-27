import 'package:personal_fitness_os/features/body/data/models/weight_entry_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class WeightRemoteDataSource {
  Future<WeightEntryModel> insertWeightEntry(Map<String, dynamic> data);
  Future<WeightEntryModel> updateWeightEntry(
    String id,
    Map<String, dynamic> data,
  );
  Future<List<WeightEntryModel>> fetchWeightHistory({
    int limit = 100,
    int offset = 0,
  });
  Future<List<WeightEntryModel>> fetchWeightEntriesInRange({
    required DateTime start,
    required DateTime end,
  });
  Future<void> deleteWeightEntry(String id);
}

class SupabaseWeightRemoteDataSource implements WeightRemoteDataSource {
  SupabaseWeightRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  @override
  Future<WeightEntryModel> insertWeightEntry(Map<String, dynamic> data) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final payload = {
      ...data,
      'user_id': user.id,
    };

    final response = await _supabaseClient
        .from('weight_entries')
        .insert(payload)
        .select()
        .single();

    return WeightEntryModel.fromJson(response);
  }

  @override
  Future<WeightEntryModel> updateWeightEntry(
    String id,
    Map<String, dynamic> data,
  ) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final response = await _supabaseClient
        .from('weight_entries')
        .update(data)
        .eq('id', id)
        .eq('user_id', user.id)
        .select()
        .single();

    return WeightEntryModel.fromJson(response);
  }

  @override
  Future<List<WeightEntryModel>> fetchWeightHistory({
    int limit = 100,
    int offset = 0,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final response = await _supabaseClient
        .from('weight_entries')
        .select()
        .eq('user_id', user.id)
        .order('measured_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List<dynamic>)
        .map((e) => WeightEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<WeightEntryModel>> fetchWeightEntriesInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final response = await _supabaseClient
        .from('weight_entries')
        .select()
        .eq('user_id', user.id)
        .gte('measured_at', start.toIso8601String())
        .lte('measured_at', end.toIso8601String())
        .order('measured_at', ascending: true);

    return (response as List<dynamic>)
        .map((e) => WeightEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> deleteWeightEntry(String id) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    await _supabaseClient
        .from('weight_entries')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }
}
