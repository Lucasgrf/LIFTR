import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/weight_repository.dart';
import 'package:personal_fitness_os/features/history/domain/repositories/history_repository.dart';
import 'package:personal_fitness_os/features/insights/domain/entities/fitness_insight.dart';
import 'package:personal_fitness_os/features/insights/domain/usecases/generate_insights.dart';
import 'package:personal_fitness_os/features/nutrition/domain/repositories/nutrition_repository.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}
class MockWeightRepository extends Mock implements WeightRepository {}
class MockNutritionRepository extends Mock implements NutritionRepository {}

void main() {
  late MockHistoryRepository mockHistoryRepo;
  late MockWeightRepository mockWeightRepo;
  late MockNutritionRepository mockNutritionRepo;
  late GenerateInsightsUseCase generateInsightsUseCase;

  final now = DateTime(2026, 8, 23, 10, 0);

  setUp(() {
    mockHistoryRepo = MockHistoryRepository();
    mockWeightRepo = MockWeightRepository();
    mockNutritionRepo = MockNutritionRepository();

    generateInsightsUseCase = GenerateInsightsUseCase(
      historyRepository: mockHistoryRepo,
      weightRepository: mockWeightRepo,
      nutritionRepository: mockNutritionRepo,
    );
  });

  group('Insights Engine Full Integration Flow', () {
    test('should generate consistency streak insight when >= 4 sessions completed', () async {
      final sessions = List.generate(4, (i) {
        return WorkoutSession(
          id: 's-$i',
          userId: 'u-1',
          startedAt: now.subtract(Duration(days: i + 1)),
          completedAt: now.subtract(Duration(days: i + 1)),
          status: SessionStatus.completed,
        );
      });

      when(() => mockHistoryRepo.getSessionsInRange(start: any(named: 'start'), end: any(named: 'end')))
          .thenAnswer((_) async => Success(sessions));
      when(() => mockWeightRepo.getWeightHistory())
          .thenAnswer((_) async => const Success([]));
      when(() => mockNutritionRepo.getActiveNutritionGoal())
          .thenAnswer((_) async => const Success(null));

      final result = await generateInsightsUseCase.execute(currentDate: now);

      expect(result.isSuccess, isTrue);
      final insights = (result as Success<List<FitnessInsight>, dynamic>).value;
      expect(insights.any((i) => i.category == InsightCategory.consistency), isTrue);
      expect(insights.first.title, 'Excelente consistência!');
    });
  });
}
