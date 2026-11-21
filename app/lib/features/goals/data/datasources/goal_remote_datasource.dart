import 'package:personal_fitness_os/features/goals/data/models/goal_checkpoint_model.dart';
import 'package:personal_fitness_os/features/goals/data/models/goal_model.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class GoalRemoteDataSource {
  Future<List<GoalModel>> fetchGoals({GoalStatus? status});
  Future<GoalModel> fetchGoalById(String goalId);
  Future<GoalModel> insertGoal(Map<String, dynamic> data);
  Future<GoalModel> updateGoalStatus(String goalId, String status);
  Future<GoalCheckpointModel> insertGoalCheckpoint({
    required String goalId,
    required double value,
    String? notes,
    DateTime? recordedAt,
  });
  Future<void> deleteGoal(String goalId);
}

class SupabaseGoalRemoteDataSource implements GoalRemoteDataSource {
  SupabaseGoalRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  @override
  Future<List<GoalModel>> fetchGoals({GoalStatus? status}) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    var query = _supabaseClient
        .from('goals')
        .select('*, goal_checkpoints (*)')
        .eq('user_id', user.id);

    if (status != null) {
      query = query.eq('status', status.name);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => GoalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GoalModel> fetchGoalById(String goalId) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final response = await _supabaseClient
        .from('goals')
        .select('*, goal_checkpoints (*)')
        .eq('id', goalId)
        .eq('user_id', user.id)
        .single();

    return GoalModel.fromJson(response);
  }

  @override
  Future<GoalModel> insertGoal(Map<String, dynamic> data) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final payload = {
      ...data,
      'user_id': user.id,
    };

    final response = await _supabaseClient
        .from('goals')
        .insert(payload)
        .select('*, goal_checkpoints (*)')
        .single();

    return GoalModel.fromJson(response);
  }

  @override
  Future<GoalModel> updateGoalStatus(String goalId, String status) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final payload = {
      'status': status,
      'completed_at': status == 'completed'
          ? DateTime.now().toIso8601String()
          : null,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabaseClient
        .from('goals')
        .update(payload)
        .eq('id', goalId)
        .eq('user_id', user.id)
        .select('*, goal_checkpoints (*)')
        .single();

    return GoalModel.fromJson(response);
  }

  @override
  Future<GoalCheckpointModel> insertGoalCheckpoint({
    required String goalId,
    required double value,
    String? notes,
    DateTime? recordedAt,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final checkpointPayload = {
      'goal_id': goalId,
      'value': value,
      'recorded_at': (recordedAt ?? DateTime.now()).toIso8601String(),
      if (notes != null) 'notes': notes,
    };

    final response = await _supabaseClient
        .from('goal_checkpoints')
        .insert(checkpointPayload)
        .select()
        .single();

    // Update current_value on goals table
    await _supabaseClient
        .from('goals')
        .update({
          'current_value': value,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', goalId)
        .eq('user_id', user.id);

    return GoalCheckpointModel.fromJson(response);
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final response = await _supabaseClient
        .from('goals')
        .delete()
        .eq('id', goalId)
        .eq('user_id', user.id)
        .select('id');

    if ((response as List).isEmpty) {
      throw const PostgrestException(
          message: 'Meta não encontrada para exclusão.');
    }
  }
}
