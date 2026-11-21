import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/nutrition/data/datasources/nutrition_remote_datasource.dart';
import 'package:personal_fitness_os/features/nutrition/data/models/daily_nutrition_model.dart';
import 'package:personal_fitness_os/features/nutrition/data/models/food_model.dart';
import 'package:personal_fitness_os/features/nutrition/data/models/meal_food_model.dart';
import 'package:personal_fitness_os/features/nutrition/data/models/meal_model.dart';
import 'package:personal_fitness_os/features/nutrition/data/models/nutrition_goal_model.dart';
import 'package:personal_fitness_os/features/nutrition/data/repositories/nutrition_repository_impl.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal_food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/nutrition_goal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/add_food_to_meal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/create_custom_food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/get_daily_nutrition.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/remove_food_from_meal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/save_nutrition_goal.dart';

class MockNutritionRemoteDataSource extends Mock
    implements NutritionRemoteDataSource {}

void main() {
  late MockNutritionRemoteDataSource mockDataSource;
  late NutritionRepositoryImpl repository;
  late SaveNutritionGoalUseCase saveGoalUseCase;
  late CreateCustomFoodUseCase createCustomFoodUseCase;
  late AddFoodToMealUseCase addFoodUseCase;
  late GetDailyNutritionUseCase getDailyUseCase;
  late RemoveFoodFromMealUseCase removeFoodUseCase;

  const tGoalModel = NutritionGoalModel(
    id: 'g-1',
    calories: 2500,
    proteinGrams: 180,
    carbsGrams: 280,
    fatGrams: 70,
  );

  const tFoodModel = FoodModel(
    id: 'f-oats',
    name: 'Aveia em Flocos',
    servingSize: 100.0,
    calories: 350.0,
    protein: 14.0,
    carbs: 60.0,
    fat: 7.0,
  );

  const tMealFoodModel = MealFoodModel(
    id: 'mf-1',
    mealId: 'm-breakfast',
    foodId: 'f-oats',
    food: tFoodModel,
    quantity: 80.0,
    calories: 280.0,
    protein: 11.2,
    carbs: 48.0,
    fat: 5.6,
  );

  final tMealModel = MealModel(
    id: 'm-breakfast',
    dailyNutritionId: 'dn-1',
    name: 'Café da Manhã',
    mealType: 'breakfast',
    foods: const [tMealFoodModel],
  );

  final tDailyModel = DailyNutritionModel(
    id: 'dn-1',
    date: DateTime(2026, 8, 23),
    goal: tGoalModel,
    meals: [tMealModel],
  );

  setUp(() {
    mockDataSource = MockNutritionRemoteDataSource();
    repository = NutritionRepositoryImpl(mockDataSource);

    saveGoalUseCase = SaveNutritionGoalUseCase(repository);
    createCustomFoodUseCase = CreateCustomFoodUseCase(repository);
    addFoodUseCase = AddFoodToMealUseCase(repository);
    getDailyUseCase = GetDailyNutritionUseCase(repository);
    removeFoodUseCase = RemoveFoodFromMealUseCase(repository);
  });

  group('Nutrition End-to-End Integration Flow', () {
    test('should save goal, create food, add to meal, compute daily totals and remove food', () async {
      final today = DateTime(2026, 8, 23);

      // 1. Save nutrition goal
      when(() => mockDataSource.insertNutritionGoal(any()))
          .thenAnswer((_) async => tGoalModel);

      final goalResult = await saveGoalUseCase.execute(
        calories: 2500,
        proteinGrams: 180,
        carbsGrams: 280,
        fatGrams: 70,
      );

      expect(goalResult.isSuccess, isTrue);
      final goal = (goalResult as Success<NutritionGoal, dynamic>).value;
      expect(goal.calories, 2500);

      // 2. Create custom food
      when(() => mockDataSource.insertFood(any()))
          .thenAnswer((_) async => tFoodModel);

      final createFoodResult = await createCustomFoodUseCase.execute(
        tFoodModel.toDomain(),
      );

      expect(createFoodResult.isSuccess, isTrue);
      final food = (createFoodResult as Success<Food, dynamic>).value;
      expect(food.name, 'Aveia em Flocos');

      // 3. Add food to breakfast meal
      when(() => mockDataSource.insertMealFood(
            date: any(named: 'date'),
            mealType: 'breakfast',
            foodId: 'f-oats',
            quantityGrams: 80.0,
          )).thenAnswer((_) async => tMealFoodModel);

      final addResult = await addFoodUseCase.execute(
        date: today,
        mealType: 'breakfast',
        foodId: 'f-oats',
        quantityGrams: 80.0,
      );

      expect(addResult.isSuccess, isTrue);
      final mealFood = (addResult as Success<MealFood, dynamic>).value;
      expect(mealFood.calories, 280.0);

      // 4. Get daily nutrition aggregate
      when(() => mockDataSource.fetchDailyNutrition(any()))
          .thenAnswer((_) async => tDailyModel);

      final dailyResult = await getDailyUseCase.execute(today);
      expect(dailyResult.isSuccess, isTrue);
      final daily = (dailyResult as Success<DailyNutrition, dynamic>).value;
      expect(daily.totalCalories, 280.0);
      expect(daily.remainingCalories, 2500 - 280.0);
      expect(daily.totalProtein, 11.2);

      // 5. Remove food from meal
      when(() => mockDataSource.deleteMealFood('mf-1'))
          .thenAnswer((_) async => {});

      final removeResult = await removeFoodUseCase.execute('mf-1');
      expect(removeResult.isSuccess, isTrue);
    });
  });
}
