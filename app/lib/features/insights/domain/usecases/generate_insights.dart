import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/weight_repository.dart';
import 'package:personal_fitness_os/features/history/domain/repositories/history_repository.dart';
import 'package:personal_fitness_os/features/insights/domain/entities/fitness_insight.dart';
import 'package:personal_fitness_os/features/insights/domain/services/deterministic_insights_engine.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/nutrition_goal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/repositories/nutrition_repository.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

class GenerateInsightsUseCase {
  const GenerateInsightsUseCase({
    required HistoryRepository historyRepository,
    required WeightRepository weightRepository,
    required NutritionRepository nutritionRepository,
    this.engine = const DeterministicInsightsEngine(),
  })  : _historyRepository = historyRepository,
        _weightRepository = weightRepository,
        _nutritionRepository = nutritionRepository;

  final HistoryRepository _historyRepository;
  final WeightRepository _weightRepository;
  final NutritionRepository _nutritionRepository;
  final DeterministicInsightsEngine engine;

  Future<Result<List<FitnessInsight>, Failure>> execute({DateTime? currentDate}) async {
    final now = currentDate ?? DateTime.now();
    final startOfEvaluation = now.subtract(const Duration(days: 30));

    // 1. Fetch sessions
    final sessionsResult = await _historyRepository.getSessionsInRange(
      start: startOfEvaluation,
      end: now,
    );
    final sessions = sessionsResult is Success<List<WorkoutSession>, Failure>
        ? sessionsResult.value
        : <WorkoutSession>[];

    // 2. Fetch weight history
    final weightResult = await _weightRepository.getWeightHistory();
    final weightEntries = weightResult is Success<List<WeightEntry>, Failure>
        ? weightResult.value
        : <WeightEntry>[];

    // 3. Fetch active nutrition goal
    final goalResult = await _nutritionRepository.getActiveNutritionGoal();
    final goal = goalResult is Success<NutritionGoal?, Failure>
        ? goalResult.value
        : null;

    final insights = engine.evaluate(
      sessions: sessions,
      weightHistory: weightEntries,
      nutritionGoal: goal,
      now: now,
    );

    return Success(insights);
  }
}
