import 'package:personal_fitness_os/features/training/data/models/set_template_model.dart';
import 'package:personal_fitness_os/features/training/data/models/training_plan_model.dart';
import 'package:personal_fitness_os/features/training/data/models/workout_exercise_model.dart';
import 'package:personal_fitness_os/features/training/data/models/workout_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class TrainingRemoteDataSource {
  Future<List<TrainingPlanModel>> fetchTrainingPlans();
  Future<TrainingPlanModel?> fetchActiveTrainingPlan();
  Future<TrainingPlanModel> fetchTrainingPlanById(String id);
  Future<TrainingPlanModel> insertTrainingPlan(Map<String, dynamic> data);
  Future<TrainingPlanModel> setActivePlan(String planId);
  Future<WorkoutModel> insertWorkout(Map<String, dynamic> data);
  Future<WorkoutExerciseModel> insertWorkoutExercise(Map<String, dynamic> data);
  Future<List<SetTemplateModel>> setExerciseTemplates(
    String workoutExerciseId,
    List<Map<String, dynamic>> templates,
  );
  Future<void> reorderWorkoutExercises(
    String workoutId,
    List<String> orderedIds,
  );
  Future<void> reorderPlanWorkouts(
    String trainingPlanId,
    List<String> orderedIds,
  );
  Future<void> softDeleteTrainingPlan(String planId);
  Future<void> deleteWorkout(String workoutId);
  Future<void> deleteWorkoutExercise(String workoutExerciseId);
}

class SupabaseTrainingRemoteDataSource implements TrainingRemoteDataSource {
  SupabaseTrainingRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  static const _nestedQuery = '''
    *,
    workouts (
      *,
      workout_exercises (
        *,
        exercises!workout_exercises_exercise_id_fkey (*),
        set_templates (*)
      )
    )
  ''';

  @override
  Future<List<TrainingPlanModel>> fetchTrainingPlans() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return const [];

    final response = await _supabaseClient
        .from('training_plans')
        .select(_nestedQuery)
        .eq('user_id', user.id)
        .filter('deleted_at', 'is', null)
        .order('is_active', ascending: false)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => TrainingPlanModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TrainingPlanModel?> fetchActiveTrainingPlan() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return null;

    final response = await _supabaseClient
        .from('training_plans')
        .select(_nestedQuery)
        .eq('user_id', user.id)
        .filter('deleted_at', 'is', null)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return TrainingPlanModel.fromJson(response);
  }

  @override
  Future<TrainingPlanModel> fetchTrainingPlanById(String id) async {
    final response = await _supabaseClient
        .from('training_plans')
        .select(_nestedQuery)
        .eq('id', id)
        .filter('deleted_at', 'is', null)
        .single();

    return TrainingPlanModel.fromJson(response);
  }

  @override
  Future<TrainingPlanModel> insertTrainingPlan(Map<String, dynamic> data) async {
    final user = _supabaseClient.auth.currentUser;
    final payload = {
      ...data,
      if (user != null) 'user_id': user.id,
    };

    final response = await _supabaseClient
        .from('training_plans')
        .insert(payload)
        .select(_nestedQuery)
        .single();

    return TrainingPlanModel.fromJson(response);
  }

  @override
  Future<TrainingPlanModel> setActivePlan(String planId) async {
    final user = _supabaseClient.auth.currentUser;
    if (user != null) {
      // Deactivate all user plans
      await _supabaseClient
          .from('training_plans')
          .update({'is_active': false})
          .eq('user_id', user.id);
    }

    // Activate the selected plan
    final response = await _supabaseClient
        .from('training_plans')
        .update({'is_active': true})
        .eq('id', planId)
        .select(_nestedQuery)
        .single();

    return TrainingPlanModel.fromJson(response);
  }

  @override
  Future<WorkoutModel> insertWorkout(Map<String, dynamic> data) async {
    final response = await _supabaseClient
        .from('workouts')
        .insert(data)
        .select('*, workout_exercises(*, exercises!workout_exercises_exercise_id_fkey(*), set_templates(*))')
        .single();

    return WorkoutModel.fromJson(response);
  }

  @override
  Future<WorkoutExerciseModel> insertWorkoutExercise(Map<String, dynamic> data) async {
    final response = await _supabaseClient
        .from('workout_exercises')
        .insert(data)
        .select('*, exercises!workout_exercises_exercise_id_fkey(*), set_templates(*)')
        .single();

    return WorkoutExerciseModel.fromJson(response);
  }

  @override
  Future<List<SetTemplateModel>> setExerciseTemplates(
    String workoutExerciseId,
    List<Map<String, dynamic>> templates,
  ) async {
    // 1. Delete existing templates for this exercise
    await _supabaseClient
        .from('set_templates')
        .delete()
        .eq('workout_exercise_id', workoutExerciseId);

    // 2. Insert new templates
    if (templates.isEmpty) return [];

    final response = await _supabaseClient
        .from('set_templates')
        .insert(templates)
        .select()
        .order('set_number', ascending: true);

    return (response as List<dynamic>)
        .map((json) => SetTemplateModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> reorderWorkoutExercises(
    String workoutId,
    List<String> orderedIds,
  ) async {
    for (var i = 0; i < orderedIds.length; i++) {
      await _supabaseClient
          .from('workout_exercises')
          .update({'sort_order': i})
          .eq('id', orderedIds[i])
          .eq('workout_id', workoutId);
    }
  }

  @override
  Future<void> reorderPlanWorkouts(
    String trainingPlanId,
    List<String> orderedIds,
  ) async {
    for (var i = 0; i < orderedIds.length; i++) {
      await _supabaseClient
          .from('workouts')
          .update({'sort_order': i})
          .eq('id', orderedIds[i])
          .eq('training_plan_id', trainingPlanId);
    }
  }

  @override
  Future<void> softDeleteTrainingPlan(String planId) async {
    await _supabaseClient
        .from('training_plans')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', planId);
  }

  @override
  Future<void> deleteWorkout(String workoutId) async {
    await _supabaseClient
        .from('workouts')
        .delete()
        .eq('id', workoutId);
  }

  @override
  Future<void> deleteWorkoutExercise(String workoutExerciseId) async {
    await _supabaseClient
        .from('workout_exercises')
        .delete()
        .eq('id', workoutExerciseId);
  }
}
