import 'package:personal_fitness_os/features/nutrition/data/models/daily_nutrition_model.dart';
import 'package:personal_fitness_os/features/nutrition/data/models/food_model.dart';
import 'package:personal_fitness_os/features/nutrition/data/models/meal_food_model.dart';
import 'package:personal_fitness_os/features/nutrition/data/models/nutrition_goal_model.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class NutritionRemoteDataSource {
  Future<DailyNutritionModel> fetchDailyNutrition(DateTime date);
  Future<NutritionGoalModel?> fetchActiveNutritionGoal();
  Future<NutritionGoalModel> insertNutritionGoal(Map<String, dynamic> data);
  Future<List<FoodModel>> searchFoods(String query);
  Future<FoodModel> insertFood(Map<String, dynamic> data);
  Future<MealFoodModel> insertMealFood({
    required DateTime date,
    required String mealType,
    required String foodId,
    required double quantityGrams,
  });
  Future<void> deleteMealFood(String mealFoodId);
}

class SupabaseNutritionRemoteDataSource implements NutritionRemoteDataSource {
  SupabaseNutritionRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  @override
  Future<DailyNutritionModel> fetchDailyNutrition(DateTime date) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final dateStr = date.toIso8601String().split('T').first;

    var response = await _supabaseClient
        .from('daily_nutrition')
        .select('''
          id,
          user_id,
          date,
          notes,
          meals (
            id,
            daily_nutrition_id,
            name,
            meal_type,
            eaten_at,
            notes,
            created_at,
            meal_foods (
              id,
              meal_id,
              food_id,
              quantity,
              calories,
              protein,
              carbs,
              fat,
              created_at,
              foods (*)
            )
          )
        ''')
        .eq('user_id', user.id)
        .eq('date', dateStr)
        .maybeSingle();

    if (response == null) {
      // Create daily nutrition entry for this date
      final createdDaily = await _supabaseClient
          .from('daily_nutrition')
          .insert({
            'user_id': user.id,
            'date': dateStr,
          })
          .select()
          .single();

      final dailyId = createdDaily['id'] as String;

      // Seed standard 4 meals in a single batch
      final standardMeals = [
        'breakfast',
        'lunch',
        'afternoon_snack',
        'dinner',
      ].map((type) => {
            'daily_nutrition_id': dailyId,
            'meal_type': type,
            'name': Meal.defaultNameForType(type),
          }).toList();

      await _supabaseClient.from('meals').insert(standardMeals);

      // Re-fetch with created meals
      response = await _supabaseClient
          .from('daily_nutrition')
          .select('''
            id,
            user_id,
            date,
            notes,
            meals (
              id,
              daily_nutrition_id,
              name,
              meal_type,
              eaten_at,
              notes,
              created_at,
              meal_foods (
                id,
                meal_id,
                food_id,
                quantity,
                calories,
                protein,
                carbs,
                fat,
                created_at,
                foods (*)
              )
            )
          ''')
          .eq('id', dailyId)
          .single();
    }

    final goalModel = await fetchActiveNutritionGoal();

    return DailyNutritionModel.fromJson(response, goal: goalModel);
  }

  @override
  Future<NutritionGoalModel?> fetchActiveNutritionGoal() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final response = await _supabaseClient
        .from('nutrition_goals')
        .select()
        .eq('user_id', user.id)
        .isFilter('effective_until', null)
        .order('effective_from', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return NutritionGoalModel.fromJson(response);
  }

  @override
  Future<NutritionGoalModel> insertNutritionGoal(Map<String, dynamic> data) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    // Close any existing active goal setting effective_until to yesterday
    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T').first;
    final yesterdayStr =
        now.subtract(const Duration(days: 1)).toIso8601String().split('T').first;

    await _supabaseClient
        .from('nutrition_goals')
        .update({'effective_until': yesterdayStr})
        .eq('user_id', user.id)
        .isFilter('effective_until', null);

    final payload = {
      ...data,
      'user_id': user.id,
      'effective_from': todayStr,
      'effective_until': null,
    };

    final response = await _supabaseClient
        .from('nutrition_goals')
        .insert(payload)
        .select()
        .single();

    return NutritionGoalModel.fromJson(response);
  }

  @override
  Future<List<FoodModel>> searchFoods(String query) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final trimmed = query.trim();

    var filterBuilder = _supabaseClient
        .from('foods')
        .select()
        .or('user_id.is.null,user_id.eq.${user.id}');

    if (trimmed.isNotEmpty) {
      filterBuilder = filterBuilder.ilike('name', '%$trimmed%');
    }

    final response = await filterBuilder.order('name', ascending: true).limit(50);

    return (response as List<dynamic>)
        .map((e) => FoodModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FoodModel> insertFood(Map<String, dynamic> data) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final payload = {
      ...data,
      'user_id': user.id,
      'is_custom': true,
    };

    final response =
        await _supabaseClient.from('foods').insert(payload).select().single();

    return FoodModel.fromJson(response);
  }

  @override
  Future<MealFoodModel> insertMealFood({
    required DateTime date,
    required String mealType,
    required String foodId,
    required double quantityGrams,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final dateStr = date.toIso8601String().split('T').first;

    // 1. Ensure daily_nutrition exists
    var daily = await _supabaseClient
        .from('daily_nutrition')
        .select('id')
        .eq('user_id', user.id)
        .eq('date', dateStr)
        .maybeSingle();

    String dailyId;
    if (daily != null) {
      dailyId = daily['id'] as String;
    } else {
      final createdDaily = await _supabaseClient
          .from('daily_nutrition')
          .insert({
            'user_id': user.id,
            'date': dateStr,
          })
          .select('id')
          .single();
      dailyId = createdDaily['id'] as String;
    }

    // 2. Find or create meal for this mealType
    var meal = await _supabaseClient
        .from('meals')
        .select('id')
        .eq('daily_nutrition_id', dailyId)
        .eq('meal_type', mealType)
        .maybeSingle();

    String mealId;
    if (meal != null) {
      mealId = meal['id'] as String;
    } else {
      final newMeal = await _supabaseClient
          .from('meals')
          .insert({
            'daily_nutrition_id': dailyId,
            'meal_type': mealType,
            'name': Meal.defaultNameForType(mealType),
          })
          .select('id')
          .single();
      mealId = newMeal['id'] as String;
    }

    // 3. Fetch food data to calculate macros
    final foodJson = await _supabaseClient
        .from('foods')
        .select()
        .eq('id', foodId)
        .single();
    final food = FoodModel.fromJson(foodJson);

    final ratio =
        quantityGrams / (food.servingSize > 0 ? food.servingSize : 100.0);
    final calories = food.calories * ratio;
    final protein = food.protein * ratio;
    final carbs = food.carbs * ratio;
    final fat = food.fat * ratio;

    // 4. Insert meal_food
    final response = await _supabaseClient
        .from('meal_foods')
        .insert({
          'meal_id': mealId,
          'food_id': foodId,
          'quantity': quantityGrams,
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
        })
        .select('*, foods (*)')
        .single();

    return MealFoodModel.fromJson(response);
  }

  @override
  Future<void> deleteMealFood(String mealFoodId) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final response = await _supabaseClient
        .from('meal_foods')
        .delete()
        .eq('id', mealFoodId)
        .select('id');

    if ((response as List).isEmpty) {
      throw const PostgrestException(
          message: 'Registro de alimento não encontrado para exclusão.');
    }
  }
}
