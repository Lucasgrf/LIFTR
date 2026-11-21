import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/progression_recommendation.dart';

/// Pure Domain Service implementing the Double Progression and Auto-Regulation rules.
class ProgressionEngine {
  const ProgressionEngine();

  static double defaultWeightIncrement(String? equipment) {
    if (equipment == null) return 2.5;
    final eq = equipment.toLowerCase();
    switch (eq) {
      case 'barbell':
      case 'smithmachine':
      case 'smith_machine':
        return 2.5;
      case 'dumbbell':
      case 'kettlebell':
        return 2.0;
      case 'machine':
      case 'cable':
        return 2.5;
      case 'bodyweight':
      case 'band':
        return 1.0;
      default:
        return 2.5;
    }
  }

  ProgressionRecommendation evaluate({
    required ExercisePerformanceHistory history,
    required int targetRepsMin,
    required int targetRepsMax,
    int targetRir = 2,
    String? equipment,
  }) {
    final workingSets = history.workingSets;

    if (workingSets.isEmpty) {
      return ProgressionRecommendation(
        type: ProgressionType.maintain,
        suggestedWeightKg: 0.0,
        weightDeltaKg: 0.0,
        rationale: 'Nenhum histórico anterior para este exercício.',
        previousSummary: history.summaryString,
        targetRepsMin: targetRepsMin,
        targetRepsMax: targetRepsMax,
        targetRir: targetRir,
      );
    }

    final baseWeight = history.maxWeightKg;
    final allHitMaxReps =
        workingSets.every((s) => s.repsCompleted >= targetRepsMax);
    final allHitMinReps =
        workingSets.every((s) => s.repsCompleted >= targetRepsMin);
    final hasPoorExecution =
        workingSets.any((s) => s.executionQuality == ExecutionQuality.poor);
    final setsBelowMin =
        workingSets.where((s) => s.repsCompleted < targetRepsMin).length;

    // 1. Top of the repetition range achieved on all working sets
    if (allHitMaxReps) {
      if (hasPoorExecution) {
        return ProgressionRecommendation(
          type: ProgressionType.maintain,
          suggestedWeightKg: baseWeight,
          weightDeltaKg: 0.0,
          rationale:
              '⚠️ Topo da faixa ($targetRepsMax reps) atingido, mas a execução técnica precisa melhorar antes de subir a carga.',
          previousSummary: history.summaryString,
          targetRepsMin: targetRepsMin,
          targetRepsMax: targetRepsMax,
          targetRir: targetRir,
        );
      }

      final minRirThreshold = (targetRir - 1).clamp(0, 5);
      final allMeetRirThreshold = workingSets
          .every((s) => (s.rirActual ?? targetRir) >= minRirThreshold);

      if (!allMeetRirThreshold) {
        return ProgressionRecommendation(
          type: ProgressionType.maintain,
          suggestedWeightKg: baseWeight,
          weightDeltaKg: 0.0,
          rationale:
              '⚠️ Topo da faixa atingido no limite de esforço (RIR abaixo da meta). Mantenha a carga mais uma sessão para consolidar.',
          previousSummary: history.summaryString,
          targetRepsMin: targetRepsMin,
          targetRepsMax: targetRepsMax,
          targetRir: targetRir,
        );
      }

      final delta = defaultWeightIncrement(equipment);
      final newWeight = baseWeight + delta;

      return ProgressionRecommendation(
        type: ProgressionType.increase,
        suggestedWeightKg: newWeight,
        weightDeltaKg: delta,
        rationale:
            '🎯 Meta atingida! Todas as séries bateram o topo da faixa ($targetRepsMax reps) com boa execução. Suba para ${newWeight.toStringAsFixed(1)} kg (+${delta.toStringAsFixed(1)} kg).',
        previousSummary: history.summaryString,
        targetRepsMin: targetRepsMin,
        targetRepsMax: targetRepsMax,
        targetRir: targetRir,
      );
    }

    // 2. Inside the target repetition range (progress reps first)
    if (allHitMinReps) {
      return ProgressionRecommendation(
        type: ProgressionType.maintain,
        suggestedWeightKg: baseWeight,
        weightDeltaKg: 0.0,
        rationale:
            '💪 Dentro da faixa alvo ($targetRepsMin-$targetRepsMax reps). Mantenha ${baseWeight.toStringAsFixed(1)} kg e busque mais repetições até atingir $targetRepsMax reps em todas as séries.',
        previousSummary: history.summaryString,
        targetRepsMin: targetRepsMin,
        targetRepsMax: targetRepsMax,
        targetRir: targetRir,
      );
    }

    // 3. Below the minimum repetition range
    final hasFailedSetWithPoorForm = workingSets.any(
      (s) => (s.rirActual != null && s.rirActual! <= 0) && s.executionQuality == ExecutionQuality.poor,
    );

    if (setsBelowMin >= 2 || hasFailedSetWithPoorForm) {
      final rawSuggested = (baseWeight * 0.9).clamp(0.0, double.infinity);
      final roundedSuggested = ((rawSuggested * 2).round() / 2).toDouble();

      return ProgressionRecommendation(
        type: ProgressionType.decrease,
        suggestedWeightKg: roundedSuggested,
        weightDeltaKg: -(baseWeight - roundedSuggested),
        rationale:
            '📉 Dificuldade excessiva ou queda abaixo de $targetRepsMin reps. Reduza para ${roundedSuggested.toStringAsFixed(1)} kg para restaurar o volume e a técnica.',
        previousSummary: history.summaryString,
        targetRepsMin: targetRepsMin,
        targetRepsMax: targetRepsMax,
        targetRir: targetRir,
      );
    }

    // 4. Default maintain for isolated minor drop
    return ProgressionRecommendation(
      type: ProgressionType.maintain,
      suggestedWeightKg: baseWeight,
      weightDeltaKg: 0.0,
      rationale:
          '→ Mantenha a carga de ${baseWeight.toStringAsFixed(1)} kg e foque em atingir ao menos $targetRepsMin reps em todas as séries.',
      previousSummary: history.summaryString,
      targetRepsMin: targetRepsMin,
      targetRepsMax: targetRepsMax,
      targetRir: targetRir,
    );
  }
}
