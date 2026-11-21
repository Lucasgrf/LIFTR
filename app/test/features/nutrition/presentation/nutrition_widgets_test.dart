import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal_food.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/nutrition_goal.dart';
import 'package:personal_fitness_os/features/nutrition/presentation/widgets/calorie_macro_target_card.dart';
import 'package:personal_fitness_os/features/nutrition/presentation/widgets/macro_progress_bar.dart';
import 'package:personal_fitness_os/features/nutrition/presentation/widgets/meal_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

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

  Widget createWidgetUnderTest(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('MacroProgressBar Widget Test', () {
    testWidgets('should render label and consumed vs target grams', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const MacroProgressBar(
            label: 'Proteína',
            consumedGrams: 120.0,
            targetGrams: 180,
            color: Colors.red,
          ),
        ),
      );

      expect(find.text('Proteína'), findsOneWidget);
      expect(find.text('120 / 180g'), findsOneWidget);
    });
  });

  group('CalorieMacroTargetCard Widget Test', () {
    testWidgets('should render calories consumed, remaining and goal and macros', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          CalorieMacroTargetCard(dailyNutrition: tDaily),
        ),
      );

      expect(find.text('RESUMO NUTRICIONAL'), findsOneWidget);
      expect(find.text('248 kcal'), findsOneWidget);
      expect(find.text('2500 kcal'), findsOneWidget);
      expect(find.text('Proteína'), findsOneWidget);
      expect(find.text('Carboidratos'), findsOneWidget);
      expect(find.text('Gorduras'), findsOneWidget);
    });
  });

  group('MealCard Widget Test', () {
    testWidgets('should render meal name, calories and logged foods list', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          MealCard(
            meal: tMeal,
            onAddFood: () {},
            onRemoveFood: (_) {},
          ),
        ),
      );

      expect(find.text('Almoço'), findsOneWidget);
      expect(find.text('Peito de Frango Grelhado'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });
}
