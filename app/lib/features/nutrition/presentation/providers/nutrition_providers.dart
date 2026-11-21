import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/features/nutrition/data/datasources/nutrition_remote_datasource.dart';
import 'package:personal_fitness_os/features/nutrition/data/repositories/nutrition_repository_impl.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/nutrition_goal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/repositories/nutrition_repository.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/add_food_to_meal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/create_custom_food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/get_active_nutrition_goal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/get_daily_nutrition.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/remove_food_from_meal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/save_nutrition_goal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/usecases/search_foods.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';

final nutritionRemoteDataSourceProvider =
    Provider<NutritionRemoteDataSource>((ref) {
  return SupabaseNutritionRemoteDataSource(ref.watch(supabaseClientProvider));
});

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepositoryImpl(ref.watch(nutritionRemoteDataSourceProvider));
});

final getDailyNutritionUseCaseProvider =
    Provider<GetDailyNutritionUseCase>((ref) {
  return GetDailyNutritionUseCase(ref.watch(nutritionRepositoryProvider));
});

final getActiveNutritionGoalUseCaseProvider =
    Provider<GetActiveNutritionGoalUseCase>((ref) {
  return GetActiveNutritionGoalUseCase(ref.watch(nutritionRepositoryProvider));
});

final saveNutritionGoalUseCaseProvider =
    Provider<SaveNutritionGoalUseCase>((ref) {
  return SaveNutritionGoalUseCase(ref.watch(nutritionRepositoryProvider));
});

final searchFoodsUseCaseProvider = Provider<SearchFoodsUseCase>((ref) {
  return SearchFoodsUseCase(ref.watch(nutritionRepositoryProvider));
});

final createCustomFoodUseCaseProvider =
    Provider<CreateCustomFoodUseCase>((ref) {
  return CreateCustomFoodUseCase(ref.watch(nutritionRepositoryProvider));
});

final addFoodToMealUseCaseProvider = Provider<AddFoodToMealUseCase>((ref) {
  return AddFoodToMealUseCase(ref.watch(nutritionRepositoryProvider));
});

final removeFoodFromMealUseCaseProvider =
    Provider<RemoveFoodFromMealUseCase>((ref) {
  return RemoveFoodFromMealUseCase(ref.watch(nutritionRepositoryProvider));
});

final selectedNutritionDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final dailyNutritionProvider =
    FutureProvider.autoDispose<DailyNutrition>((ref) async {
  final date = ref.watch(selectedNutritionDateProvider);
  final useCase = ref.watch(getDailyNutritionUseCaseProvider);
  final result = await useCase.execute(date);

  return result.fold(
    (daily) => daily,
    (failure) => throw failure,
  );
});

final activeNutritionGoalProvider =
    FutureProvider.autoDispose<NutritionGoal?>((ref) async {
  final useCase = ref.watch(getActiveNutritionGoalUseCaseProvider);
  final result = await useCase.execute();

  return result.fold(
    (goal) => goal,
    (failure) => throw failure,
  );
});

final foodSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

final foodSearchResultsProvider =
    FutureProvider.autoDispose<List<Food>>((ref) async {
  final query = ref.watch(foodSearchQueryProvider);
  if (query.trim().isNotEmpty) {
    var disposed = false;
    ref.onDispose(() => disposed = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (disposed) {
      return const [];
    }
  }
  final useCase = ref.watch(searchFoodsUseCaseProvider);
  final result = await useCase.execute(query);

  return result.fold(
    (foods) => foods,
    (failure) => throw failure,
  );
});
