import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/widgets/charts/calorie_macro_history_chart.dart';
import 'package:personal_fitness_os/core/widgets/charts/exercise_load_progression_chart.dart';
import 'package:personal_fitness_os/core/widgets/charts/weight_evolution_chart.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/history/domain/entities/exercise_history_record.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal_food.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  final tEntries = [
    WeightEntry(
      id: 'we-1',
      weightKg: 85.0,
      measuredAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    WeightEntry(
      id: 'we-2',
      weightKg: 84.2,
      measuredAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    WeightEntry(
      id: 'we-3',
      weightKg: 83.5,
      measuredAt: DateTime.now(),
    ),
  ];

  final tRecords = [
    ExerciseHistoryRecord(
      sessionId: 's-1',
      sessionName: 'Treino A',
      date: DateTime.now().subtract(const Duration(days: 7)),
      setsCount: 3,
      topWeightKg: 80.0,
      topReps: 10,
      bestEstimated1Rm: 106.7,
    ),
    ExerciseHistoryRecord(
      sessionId: 's-2',
      sessionName: 'Treino A',
      date: DateTime.now(),
      setsCount: 4,
      topWeightKg: 85.0,
      topReps: 8,
      bestEstimated1Rm: 107.6,
    ),
  ];

  final tNutritionHistory = [
    DailyNutrition(
      id: 'dn-1',
      date: DateTime.now().subtract(const Duration(days: 1)),
      meals: [
        Meal(
          id: 'm-1',
          dailyNutritionId: 'dn-1',
          name: 'Almoço',
          mealType: 'lunch',
          foods: const [
            MealFood(
              id: 'mf-1',
              mealId: 'm-1',
              foodId: 'f-1',
              quantityGrams: 100,
              calories: 2400.0,
              protein: 180,
              carbs: 280,
              fat: 70,
            ),
          ],
        ),
      ],
    ),
    DailyNutrition(
      id: 'dn-2',
      date: DateTime.now(),
      meals: [
        Meal(
          id: 'm-2',
          dailyNutritionId: 'dn-2',
          name: 'Almoço',
          mealType: 'lunch',
          foods: const [
            MealFood(
              id: 'mf-2',
              mealId: 'm-2',
              foodId: 'f-1',
              quantityGrams: 100,
              calories: 2500.0,
              protein: 180,
              carbs: 280,
              fat: 70,
            ),
          ],
        ),
      ],
    ),
  ];

  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('WeightEvolutionChart Widget Test', () {
    testWidgets('should render chart and period chips', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          WeightEvolutionChart(entries: tEntries),
        ),
      );

      expect(find.text('EVOLUÇÃO DO PESO'), findsOneWidget);
      expect(find.text('30d'), findsOneWidget);
      expect(find.text('60d'), findsOneWidget);
      expect(find.text('90d'), findsOneWidget);
    });

    testWidgets('should render fallback when fewer than 2 entries', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const WeightEvolutionChart(entries: []),
        ),
      );

      expect(find.text('Registre pelo menos 2 pesagens no período para visualizar o gráfico.'), findsOneWidget);
    });
  });

  group('ExerciseLoadProgressionChart Widget Test', () {
    testWidgets('should render chart and legend items', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          ExerciseLoadProgressionChart(records: tRecords),
        ),
      );

      expect(find.text('PROGRESSÃO DE CARGA'), findsOneWidget);
      expect(find.text('Carga máx'), findsOneWidget);
      expect(find.text('1RM est'), findsOneWidget);
    });
  });

  group('CalorieMacroHistoryChart Widget Test', () {
    testWidgets('should render calorie chart', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          CalorieMacroHistoryChart(
            history: tNutritionHistory,
            targetCalories: 2500.0,
          ),
        ),
      );

      expect(find.text('CONSUMO CALÓRICO (7 DIAS)'), findsOneWidget);
      expect(find.text('Meta: 2500 kcal'), findsOneWidget);
    });
  });
}
