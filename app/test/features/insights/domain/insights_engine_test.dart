import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/insights/domain/entities/fitness_insight.dart';
import 'package:personal_fitness_os/features/insights/domain/services/deterministic_insights_engine.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/nutrition_goal.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

void main() {
  const engine = DeterministicInsightsEngine();
  final now = DateTime(2026, 8, 23, 12, 0);

  group('DeterministicInsightsEngine', () {
    test('should trigger high fatigue alert when recent RPE >= 8.8', () {
      final sessions = [
        WorkoutSession(
          id: 's-1',
          userId: 'u-1',
          startedAt: now.subtract(const Duration(days: 1)),
          completedAt: now.subtract(const Duration(days: 1)),
          perceivedExertion: 9.5,
          status: SessionStatus.completed,
        ),
        WorkoutSession(
          id: 's-2',
          userId: 'u-1',
          startedAt: now.subtract(const Duration(days: 2)),
          completedAt: now.subtract(const Duration(days: 2)),
          perceivedExertion: 9.0,
          status: SessionStatus.completed,
        ),
        WorkoutSession(
          id: 's-3',
          userId: 'u-1',
          startedAt: now.subtract(const Duration(days: 4)),
          completedAt: now.subtract(const Duration(days: 4)),
          perceivedExertion: 9.0,
          status: SessionStatus.completed,
        ),
      ];

      final insights = engine.evaluate(
        sessions: sessions,
        weightHistory: [],
        now: now,
      );

      expect(insights.any((i) => i.category == InsightCategory.fatigue), isTrue);
      expect(insights.firstWhere((i) => i.category == InsightCategory.fatigue).severity, InsightSeverity.alert);
    });

    test('should trigger consistency celebration when >= 4 workouts completed in last 7 days', () {
      final sessions = List.generate(4, (i) {
        return WorkoutSession(
          id: 's-$i',
          userId: 'u-1',
          startedAt: now.subtract(Duration(days: i + 1)),
          completedAt: now.subtract(Duration(days: i + 1)),
          status: SessionStatus.completed,
        );
      });

      final insights = engine.evaluate(
        sessions: sessions,
        weightHistory: [],
        now: now,
      );

      expect(insights.any((i) => i.category == InsightCategory.consistency), isTrue);
    });

    test('should trigger weight vs nutrition warning when weight is rising in cutting goal', () {
      final weights = [
        WeightEntry(id: 'w-1', weightKg: 80.0, measuredAt: now.subtract(const Duration(days: 10))),
        WeightEntry(id: 'w-2', weightKg: 80.2, measuredAt: now.subtract(const Duration(days: 8))),
        WeightEntry(id: 'w-3', weightKg: 81.5, measuredAt: now.subtract(const Duration(days: 3))),
        WeightEntry(id: 'w-4', weightKg: 81.8, measuredAt: now.subtract(const Duration(days: 1))),
      ];

      final goal = NutritionGoal(
        id: 'g-1',
        userId: 'u-1',
        calories: 1800,
        proteinGrams: 160,
        carbsGrams: 180,
        fatGrams: 50,
      );

      final insights = engine.evaluate(
        sessions: [],
        weightHistory: weights,
        nutritionGoal: goal,
        now: now,
      );

      expect(insights.any((i) => i.category == InsightCategory.nutrition), isTrue);
    });
  });
}
