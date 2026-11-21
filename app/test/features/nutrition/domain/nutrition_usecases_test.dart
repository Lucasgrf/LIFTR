import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal_food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/nutrition_goal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/repositories/nutrition_repository.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/add_food_to_meal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/create_custom_food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/get_active_nutrition_goal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/get_daily_nutrition.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/remove_food_from_meal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/save_nutrition_goal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/search_foods.dart';

class MockNutritionRepository extends Mock implements NutritionRepository {}

void main() {
  late MockNutritionRepository mockRepo;
  late GetDailyNutritionUseCase getDailyNutritionUseCase;
  late GetActiveNutritionGoalUseCase getActiveGoalUseCase;
  late SaveNutritionGoalUseCase saveGoalUseCase;
  late SearchFoodsUseCase searchFoodsUseCase;
  late CreateCustomFoodUseCase createCustomFoodUseCase;
  late AddFoodToMealUseCase addFoodUseCase;
  late RemoveFoodFromMealUseCase removeFoodUseCase;

  const tFood = Food(
    id: 'f-1',
    name: 'Peito de Frango Grelhado',
    servingSize: 100.0,
    calories: 165.0,
    protein: 31.0,
    carbs: 0.0,
    fat: 3.6,
  );

  const tGoal = NutritionGoal(
    id: 'g-1',
    calories: 2500,
    proteinGrams: 180,
    carbsGrams: 280,
    fatGrams: 70,
  );

  final tMealFood = const MealFood(
    id: 'mf-1',
    mealId: 'm-1',
    foodId: 'f-1',
    food: tFood,
    quantityGrams: 150.0,
    calories: 247.5,
    protein: 46.5,
    carbs: 0.0,
    fat: 5.4,
  );

  final tMeal = Meal(
    id: 'm-1',
    dailyNutritionId: 'dn-1',
    name: 'Almoço',
    mealType: 'lunch',
    foods: [tMealFood],
  );

  final tDaily = DailyNutrition(
    id: 'dn-1',
    date: DateTime(2026, 8, 23),
    goal: tGoal,
    meals: [tMeal],
  );

  setUpAll(() {
    registerFallbackValue(tFood);
    registerFallbackValue(DateTime(2026, 8, 23));
  });

  setUp(() {
    mockRepo = MockNutritionRepository();
    getDailyNutritionUseCase = GetDailyNutritionUseCase(mockRepo);
    getActiveGoalUseCase = GetActiveNutritionGoalUseCase(mockRepo);
    saveGoalUseCase = SaveNutritionGoalUseCase(mockRepo);
    searchFoodsUseCase = SearchFoodsUseCase(mockRepo);
    createCustomFoodUseCase = CreateCustomFoodUseCase(mockRepo);
    addFoodUseCase = AddFoodToMealUseCase(mockRepo);
    removeFoodUseCase = RemoveFoodFromMealUseCase(mockRepo);
  });

  group('GetDailyNutritionUseCase', () {
    test('should return DailyNutrition with correct totals', () async {
      when(() => mockRepo.getDailyNutrition(any()))
          .thenAnswer((_) async => Success(tDaily));

      final result = await getDailyNutritionUseCase.execute(DateTime(2026, 8, 23));

      expect(result.isSuccess, isTrue);
      final daily = (result as Success).value;
      expect(daily.totalCalories, 247.5);
      expect(daily.totalProtein, 46.5);
      expect(daily.remainingCalories, 2500 - 247.5);
    });
  });

  group('GetActiveNutritionGoalUseCase', () {
    test('should return active goal from repository', () async {
      when(() => mockRepo.getActiveNutritionGoal())
          .thenAnswer((_) async => const Success(tGoal));

      final result = await getActiveGoalUseCase.execute();

      expect(result.isSuccess, isTrue);
      expect((result as Success).value, tGoal);
    });
  });

  group('SaveNutritionGoalUseCase', () {
    test('should save valid goal successfully', () async {
      when(() => mockRepo.saveNutritionGoal(
            calories: 2500,
            proteinGrams: 180,
            carbsGrams: 280,
            fatGrams: 70,
          )).thenAnswer((_) async => const Success(tGoal));

      final result = await saveGoalUseCase.execute(
        calories: 2500,
        proteinGrams: 180,
        carbsGrams: 280,
        fatGrams: 70,
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.calories, 2500);
    });

    test('should return ValidationFailure when calories or macros are invalid', () async {
      final invalidCal = await saveGoalUseCase.execute(
        calories: 0,
        proteinGrams: 150,
        carbsGrams: 200,
        fatGrams: 50,
      );
      expect(invalidCal.isError, isTrue);
      expect((invalidCal as Err).failure, isA<ValidationFailure>());

      final invalidMacro = await saveGoalUseCase.execute(
        calories: 2000,
        proteinGrams: -10,
        carbsGrams: 200,
        fatGrams: 50,
      );
      expect(invalidMacro.isError, isTrue);
      expect((invalidMacro as Err).failure, isA<ValidationFailure>());
    });
  });

  group('SearchFoodsUseCase', () {
    test('should return foods list from repository', () async {
      when(() => mockRepo.searchFoods('frango'))
          .thenAnswer((_) async => const Success([tFood]));

      final result = await searchFoodsUseCase.execute('frango');

      expect(result.isSuccess, isTrue);
      expect((result as Success).value, [tFood]);
    });
  });

  group('CreateCustomFoodUseCase', () {
    test('should create custom food successfully', () async {
      when(() => mockRepo.createCustomFood(any()))
          .thenAnswer((_) async => const Success(tFood));

      final result = await createCustomFoodUseCase.execute(tFood);
      expect(result.isSuccess, isTrue);
    });

    test('should reject empty name, invalid calories or negative macros', () async {
      final emptyName = await createCustomFoodUseCase.execute(
        tFood.copyWith(name: '   '),
      );
      expect(emptyName.isError, isTrue);
      expect((emptyName as Err).failure, isA<ValidationFailure>());

      final invalidCal = await createCustomFoodUseCase.execute(
        tFood.copyWith(calories: -5),
      );
      expect(invalidCal.isError, isTrue);
      expect((invalidCal as Err).failure, isA<ValidationFailure>());

      final invalidProtein = await createCustomFoodUseCase.execute(
        tFood.copyWith(protein: -1),
      );
      expect(invalidProtein.isError, isTrue);
      expect((invalidProtein as Err).failure, isA<ValidationFailure>());

      final nanFat = await createCustomFoodUseCase.execute(
        tFood.copyWith(fat: double.nan),
      );
      expect(nanFat.isError, isTrue);
      expect((nanFat as Err).failure, isA<ValidationFailure>());
    });
  });

  group('AddFoodToMealUseCase', () {
    test('should add food to meal with valid quantity', () async {
      when(() => mockRepo.addFoodToMeal(
            date: any(named: 'date'),
            mealType: 'lunch',
            foodId: 'f-1',
            quantityGrams: 150.0,
          )).thenAnswer((_) async => Success(tMealFood));

      final result = await addFoodUseCase.execute(
        date: DateTime(2026, 8, 23),
        mealType: 'lunch',
        foodId: 'f-1',
        quantityGrams: 150.0,
      );

      expect(result.isSuccess, isTrue);
    });

    test('should reject invalid quantity (<= 0 or > 5000 or NaN)', () async {
      final resultZero = await addFoodUseCase.execute(
        date: DateTime(2026, 8, 23),
        mealType: 'lunch',
        foodId: 'f-1',
        quantityGrams: 0,
      );
      expect(resultZero.isError, isTrue);
      expect((resultZero as Err).failure, isA<ValidationFailure>());

      final resultTooHigh = await addFoodUseCase.execute(
        date: DateTime(2026, 8, 23),
        mealType: 'lunch',
        foodId: 'f-1',
        quantityGrams: 5500,
      );
      expect(resultTooHigh.isError, isTrue);
      expect((resultTooHigh as Err).failure, isA<ValidationFailure>());

      final resultNaN = await addFoodUseCase.execute(
        date: DateTime(2026, 8, 23),
        mealType: 'lunch',
        foodId: 'f-1',
        quantityGrams: double.nan,
      );
      expect(resultNaN.isError, isTrue);
      expect((resultNaN as Err).failure, isA<ValidationFailure>());
    });
  });

  group('RemoveFoodFromMealUseCase', () {
    test('should delete meal food item', () async {
      when(() => mockRepo.removeFoodFromMeal('mf-1'))
          .thenAnswer((_) async => const Success(null));

      final result = await removeFoodUseCase.execute('mf-1');
      expect(result.isSuccess, isTrue);
    });
  });
}
