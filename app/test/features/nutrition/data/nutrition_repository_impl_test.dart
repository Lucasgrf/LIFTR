import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/nutrition/data/datasources/nutrition_remote_datasource.dart';
import 'package:personal_fitness_os/features/nutrition/data/models/daily_nutrition_model.dart';
import 'package:personal_fitness_os/features/nutrition/data/models/food_model.dart';
import 'package:personal_fitness_os/features/nutrition/data/models/meal_food_model.dart';
import 'package:personal_fitness_os/features/nutrition/data/models/nutrition_goal_model.dart';
import 'package:personal_fitness_os/features/nutrition/data/repositories/nutrition_repository_impl.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/food.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockNutritionRemoteDataSource extends Mock
    implements NutritionRemoteDataSource {}

void main() {
  late MockNutritionRemoteDataSource mockDataSource;
  late NutritionRepositoryImpl repository;

  const tFoodModel = FoodModel(
    id: 'f-1',
    name: 'Frango Grelhado',
    servingSize: 100.0,
    calories: 165.0,
    protein: 31.0,
    carbs: 0.0,
    fat: 3.6,
  );

  const tGoalModel = NutritionGoalModel(
    id: 'g-1',
    calories: 2500,
    proteinGrams: 180,
    carbsGrams: 280,
    fatGrams: 70,
  );

  const tMealFoodModel = MealFoodModel(
    id: 'mf-1',
    mealId: 'm-1',
    foodId: 'f-1',
    food: tFoodModel,
    quantity: 100.0,
    calories: 165.0,
    protein: 31.0,
    carbs: 0.0,
    fat: 3.6,
  );

  final tDailyModel = DailyNutritionModel(
    id: 'dn-1',
    date: DateTime(2026, 8, 23),
    goal: tGoalModel,
    meals: const [],
  );

  setUp(() {
    mockDataSource = MockNutritionRemoteDataSource();
    repository = NutritionRepositoryImpl(mockDataSource);
  });

  group('getDailyNutrition', () {
    test('should return DailyNutrition on success', () async {
      when(() => mockDataSource.fetchDailyNutrition(any()))
          .thenAnswer((_) async => tDailyModel);

      final result = await repository.getDailyNutrition(DateTime(2026, 8, 23));

      expect(result.isSuccess, isTrue);
      expect((result as Success<DailyNutrition, Failure>).value.id, 'dn-1');
    });

    test('should return AuthFailure on AuthException', () async {
      when(() => mockDataSource.fetchDailyNutrition(any()))
          .thenThrow(const AuthException('Unauthenticated'));

      final result = await repository.getDailyNutrition(DateTime(2026, 8, 23));

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<AuthFailure>());
    });

    test('should return ServerFailure on PostgrestException', () async {
      when(() => mockDataSource.fetchDailyNutrition(any()))
          .thenThrow(const PostgrestException(message: 'DB error'));

      final result = await repository.getDailyNutrition(DateTime(2026, 8, 23));

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ServerFailure>());
    });
  });

  group('getActiveNutritionGoal', () {
    test('should return active goal on success', () async {
      when(() => mockDataSource.fetchActiveNutritionGoal())
          .thenAnswer((_) async => tGoalModel);

      final result = await repository.getActiveNutritionGoal();
      expect(result.isSuccess, isTrue);
      expect((result as Success).value.calories, 2500);
    });
  });

  group('saveNutritionGoal', () {
    test('should save and return goal on success', () async {
      when(() => mockDataSource.insertNutritionGoal(any()))
          .thenAnswer((_) async => tGoalModel);

      final result = await repository.saveNutritionGoal(
        calories: 2500,
        proteinGrams: 180,
        carbsGrams: 280,
        fatGrams: 70,
      );
      expect(result.isSuccess, isTrue);
      expect((result as Success).value.calories, 2500);
    });
  });

  group('searchFoods', () {
    test('should return list of foods on success', () async {
      when(() => mockDataSource.searchFoods('frango'))
          .thenAnswer((_) async => [tFoodModel]);

      final result = await repository.searchFoods('frango');

      expect(result.isSuccess, isTrue);
      expect((result as Success<List<Food>, Failure>).value.length, 1);
    });
  });

  group('createCustomFood', () {
    test('should create and return food on success', () async {
      when(() => mockDataSource.insertFood(any()))
          .thenAnswer((_) async => tFoodModel);

      final result = await repository.createCustomFood(tFoodModel.toDomain());
      expect(result.isSuccess, isTrue);
      expect((result as Success).value.name, 'Frango Grelhado');
    });
  });

  group('addFoodToMeal', () {
    test('should add and return meal food on success', () async {
      when(() => mockDataSource.insertMealFood(
            date: any(named: 'date'),
            mealType: 'lunch',
            foodId: 'f-1',
            quantityGrams: 100.0,
          )).thenAnswer((_) async => tMealFoodModel);

      final result = await repository.addFoodToMeal(
        date: DateTime(2026, 8, 23),
        mealType: 'lunch',
        foodId: 'f-1',
        quantityGrams: 100.0,
      );

      expect(result.isSuccess, isTrue);
    });
  });

  group('removeFoodFromMeal', () {
    test('should succeed when deletion is successful', () async {
      when(() => mockDataSource.deleteMealFood('mf-1'))
          .thenAnswer((_) async => {});

      final result = await repository.removeFoodFromMeal('mf-1');
      expect(result.isSuccess, isTrue);
    });
  });
}
