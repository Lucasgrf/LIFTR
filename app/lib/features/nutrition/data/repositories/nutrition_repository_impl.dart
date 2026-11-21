import 'dart:io';

import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/nutrition/data/datasources/nutrition_remote_datasource.dart';
import 'package:personal_fitness_os/features/nutrition/data/models/food_model.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal_food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/nutrition_goal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/repositories/nutrition_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NutritionRepositoryImpl implements NutritionRepository {
  const NutritionRepositoryImpl(this._remoteDataSource);

  final NutritionRemoteDataSource _remoteDataSource;

  Future<Result<T, Failure>> _guard<T>(
    Future<T> Function() call,
    String fallbackMessage,
  ) async {
    try {
      final data = await call();
      return Success(data);
    } on AuthException catch (e, stack) {
      return Err(AuthFailure(e.message, stack));
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (_, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (_, stack) {
      return Err(UnexpectedFailure(fallbackMessage, stack));
    }
  }

  @override
  Future<Result<DailyNutrition, Failure>> getDailyNutrition(DateTime date) {
    return _guard(
      () async {
        final model = await _remoteDataSource.fetchDailyNutrition(date);
        return model.toDomain();
      },
      'Erro ao carregar dados de nutrição.',
    );
  }

  @override
  Future<Result<NutritionGoal?, Failure>> getActiveNutritionGoal() {
    return _guard(
      () async {
        final model = await _remoteDataSource.fetchActiveNutritionGoal();
        return model?.toDomain();
      },
      'Erro ao buscar meta nutricional.',
    );
  }

  @override
  Future<Result<NutritionGoal, Failure>> saveNutritionGoal({
    required int calories,
    required int proteinGrams,
    required int carbsGrams,
    required int fatGrams,
    String? notes,
  }) {
    return _guard(
      () async {
        final model = await _remoteDataSource.insertNutritionGoal({
          'calories': calories,
          'protein_grams': proteinGrams,
          'carbs_grams': carbsGrams,
          'fat_grams': fatGrams,
          if (notes != null) 'notes': notes,
        });
        return model.toDomain();
      },
      'Erro ao salvar meta nutricional.',
    );
  }

  @override
  Future<Result<List<Food>, Failure>> searchFoods(String query) {
    return _guard(
      () async {
        final models = await _remoteDataSource.searchFoods(query);
        return models.map((m) => m.toDomain()).toList();
      },
      'Erro ao buscar alimentos.',
    );
  }

  @override
  Future<Result<Food, Failure>> createCustomFood(Food food) {
    return _guard(
      () async {
        final model = await _remoteDataSource.insertFood(
          FoodModel.fromDomain(food).toJson(),
        );
        return model.toDomain();
      },
      'Erro ao cadastrar alimento.',
    );
  }

  @override
  Future<Result<MealFood, Failure>> addFoodToMeal({
    required DateTime date,
    required String mealType,
    required String foodId,
    required double quantityGrams,
  }) {
    return _guard(
      () async {
        final model = await _remoteDataSource.insertMealFood(
          date: date,
          mealType: mealType,
          foodId: foodId,
          quantityGrams: quantityGrams,
        );
        return model.toDomain();
      },
      'Erro ao adicionar alimento à refeição.',
    );
  }

  @override
  Future<Result<void, Failure>> removeFoodFromMeal(String mealFoodId) {
    return _guard(
      () async {
        await _remoteDataSource.deleteMealFood(mealFoodId);
      },
      'Erro ao remover alimento da refeição.',
    );
  }
}
