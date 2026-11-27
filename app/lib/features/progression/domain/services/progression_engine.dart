import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/utils/pt_br_copy_utils.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/progression_recommendation.dart';

/// Pure Domain Service implementing the Double Progression and Auto-Regulation rules.
class ProgressionEngine {
  const ProgressionEngine();

  /// Number of consecutive qualifying sessions hitting the rep ceiling
  /// required before unlocking a load increase.
  static const int requiredCeilingHitsForIncrease = 2;

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

  /// Returns `true` when all working sets in [session] hit at least
  /// [targetRepsMax] with acceptable form and within the RIR threshold.
  static bool didSessionHitCeiling(
    ExercisePerformanceHistory session, {
    required int targetRepsMax,
    int targetRir = 2,
  }) {
    final workingSets = session.workingSets;
    if (workingSets.isEmpty) return false;
    final allHitMax =
        workingSets.every((s) => s.repsCompleted >= targetRepsMax);
    if (!allHitMax) return false;
    final hasPoorExecution =
        workingSets.any((s) => s.executionQuality == ExecutionQuality.poor);
    if (hasPoorExecution) return false;
    final minRirThreshold = (targetRir - 1).clamp(0, 5);
    return workingSets
        .every((s) => (s.rirActual ?? targetRir) >= minRirThreshold);
  }

  ProgressionRecommendation evaluate({
    required ExercisePerformanceHistory history,
    required int targetRepsMin,
    required int targetRepsMax,
    int targetRir = 2,
    String? equipment,
    List<ExercisePerformanceHistory> previousHistories = const [],
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
        requiredCeilingHits: requiredCeilingHitsForIncrease,
        previousWorkingSets: const [],
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
              'Topo da faixa ($targetRepsMax reps) atingido, mas a execução técnica precisa melhorar antes de subir a carga.',
          previousSummary: history.summaryString,
          targetRepsMin: targetRepsMin,
          targetRepsMax: targetRepsMax,
          targetRir: targetRir,
          requiredCeilingHits: requiredCeilingHitsForIncrease,
          previousWorkingSets: workingSets,
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
              'Topo da faixa atingido no limite de esforço (RIR abaixo da meta). Mantenha a carga mais uma sessão para consolidar.',
          previousSummary: history.summaryString,
          targetRepsMin: targetRepsMin,
          targetRepsMax: targetRepsMax,
          targetRir: targetRir,
          requiredCeilingHits: requiredCeilingHitsForIncrease,
          previousWorkingSets: workingSets,
        );
      }

      var consecutiveCeilingHits = 1;
      for (final prev in previousHistories) {
        if (prev.workoutSessionId == history.workoutSessionId) continue;
        if (prev.workingSets.isNotEmpty &&
            prev.maxWeightKg >= baseWeight - 0.01 &&
            didSessionHitCeiling(
              prev,
              targetRepsMax: targetRepsMax,
              targetRir: targetRir,
            )) {
          consecutiveCeilingHits++;
        } else {
          break;
        }
      }

      if (consecutiveCeilingHits < requiredCeilingHitsForIncrease) {
        return ProgressionRecommendation(
          type: ProgressionType.maintain,
          suggestedWeightKg: baseWeight,
          weightDeltaKg: 0.0,
          consecutiveCeilingHits: consecutiveCeilingHits,
          requiredCeilingHits: requiredCeilingHitsForIncrease,
          previousWorkingSets: workingSets,
          rationale:
              'Topo da faixa (${pluralize(targetRepsMax, 'rep', 'reps')}) atingido $consecutiveCeilingHits/$requiredCeilingHitsForIncrease vezes com ${formatWeightKgPtBr(baseWeight)}. Repita o topo na próxima sessão para confirmar a subida de carga.',
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
        consecutiveCeilingHits: consecutiveCeilingHits,
        requiredCeilingHits: requiredCeilingHitsForIncrease,
        previousWorkingSets: workingSets,
        rationale:
            'Meta consolidada ($consecutiveCeilingHits/$requiredCeilingHitsForIncrease)! Todas as séries bateram o topo ($targetRepsMax reps) em $requiredCeilingHitsForIncrease sessões seguidas com boa execução. Suba para ${formatWeightKgPtBr(newWeight)} (+${formatWeightKgPtBr(delta)}).',
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
        requiredCeilingHits: requiredCeilingHitsForIncrease,
        previousWorkingSets: workingSets,
        rationale:
            'Dentro da faixa alvo ($targetRepsMin-$targetRepsMax reps). Mantenha ${formatWeightKgPtBr(baseWeight)} e busque mais repetições até atingir $targetRepsMax reps em todas as séries.',
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
        requiredCeilingHits: requiredCeilingHitsForIncrease,
        previousWorkingSets: workingSets,
        rationale:
            'Dificuldade excessiva ou queda abaixo de $targetRepsMin reps. Reduza para ${formatWeightKgPtBr(roundedSuggested)} para restaurar o volume e a técnica.',
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
      requiredCeilingHits: requiredCeilingHitsForIncrease,
      previousWorkingSets: workingSets,
      rationale:
          'Mantenha a carga de ${formatWeightKgPtBr(baseWeight)} e foque em atingir ao menos $targetRepsMin reps em todas as séries.',
      previousSummary: history.summaryString,
      targetRepsMin: targetRepsMin,
      targetRepsMax: targetRepsMax,
      targetRir: targetRir,
    );
  }
}
