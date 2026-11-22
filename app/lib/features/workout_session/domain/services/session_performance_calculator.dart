import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

enum RpeEstimationSource {
  rirBased,
  loadAndCompletionBased,
  cardioOnly,
  empty,
}

@immutable
class SessionPerformanceSummary {
  const SessionPerformanceSummary({
    required this.autoRpe,
    required this.executionScore,
    required this.scoreLabel,
    required this.rationale,
    required this.rpeSource,
    this.averageRir,
    required this.completedStrengthSets,
    required this.targetStrengthSets,
    required this.cardioMinutesLogged,
    required this.exercisesWithLoadUp,
    required this.exercisesWithLoadMaintained,
    required this.exercisesWithLoadDrop,
    required this.setsBelowMinReps,
  });

  final double autoRpe;
  final int executionScore;
  final String scoreLabel;
  final String rationale;
  final RpeEstimationSource rpeSource;
  final double? averageRir;
  final int completedStrengthSets;
  final int targetStrengthSets;
  final int cardioMinutesLogged;
  final int exercisesWithLoadUp;
  final int exercisesWithLoadMaintained;
  final int exercisesWithLoadDrop;
  final int setsBelowMinReps;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionPerformanceSummary &&
        other.autoRpe == autoRpe &&
        other.executionScore == executionScore &&
        other.scoreLabel == scoreLabel &&
        other.rationale == rationale &&
        other.rpeSource == rpeSource &&
        other.averageRir == averageRir &&
        other.completedStrengthSets == completedStrengthSets &&
        other.targetStrengthSets == targetStrengthSets &&
        other.cardioMinutesLogged == cardioMinutesLogged &&
        other.exercisesWithLoadUp == exercisesWithLoadUp &&
        other.exercisesWithLoadMaintained == exercisesWithLoadMaintained &&
        other.exercisesWithLoadDrop == exercisesWithLoadDrop &&
        other.setsBelowMinReps == setsBelowMinReps;
  }

  @override
  int get hashCode => Object.hash(
        autoRpe,
        executionScore,
        scoreLabel,
        rationale,
        rpeSource,
        averageRir,
        completedStrengthSets,
        targetStrengthSets,
        cardioMinutesLogged,
        exercisesWithLoadUp,
        exercisesWithLoadMaintained,
        exercisesWithLoadDrop,
        setsBelowMinReps,
      );
}

/// Computes automatic Session RPE and objective Execution Score (0–100%)
/// from logged sets, previous exercise weights, and target ranges.
class SessionPerformanceCalculator {
  const SessionPerformanceCalculator._();

  static SessionPerformanceSummary evaluate(
    WorkoutSession session, {
    Map<String, double> previousMaxWeightByExerciseId = const {},
  }) {
    final strengthExercises =
        session.exercises.where((e) => !e.isCardio).toList();
    final cardioExercises =
        session.exercises.where((e) => e.isCardio).toList();

    final completedStrengthSetsList = <LoggedSet>[];
    var targetStrengthSets = 0;

    for (final se in strengthExercises) {
      targetStrengthSets += se.targetSetsCount;
      completedStrengthSetsList.addAll(se.sets.where((s) => s.isWorkingSet));
    }

    final cardioDurationSeconds = session.totalCardioDurationSeconds;
    final cardioMinutesLogged = (cardioDurationSeconds / 60).round();

    if (completedStrengthSetsList.isEmpty && cardioDurationSeconds <= 0) {
      return SessionPerformanceSummary(
        autoRpe: 5.0,
        executionScore: 0,
        scoreLabel: 'Sem séries registradas',
        rationale: 'Registre séries ou cardio para calcular o desempenho.',
        rpeSource: RpeEstimationSource.empty,
        averageRir: null,
        completedStrengthSets: 0,
        targetStrengthSets: targetStrengthSets,
        cardioMinutesLogged: 0,
        exercisesWithLoadUp: 0,
        exercisesWithLoadMaintained: 0,
        exercisesWithLoadDrop: 0,
        setsBelowMinReps: 0,
      );
    }

    // 1. Completion ratio across all prescribed exercises
    final completionRatios = <double>[];
    for (final se in strengthExercises) {
      final workingCount = se.sets.where((s) => s.isWorkingSet).length;
      final ratio =
          (workingCount / math.max(1, se.targetSetsCount)).clamp(0.0, 1.0);
      completionRatios.add(ratio);
    }
    for (final se in cardioExercises) {
      final targetMinSec = math.max(1, se.targetRepsMin) * 60;
      final ratio =
          (se.totalCardioDurationSeconds / targetMinSec).clamp(0.0, 1.0);
      completionRatios.add(ratio);
    }
    final completionRatio = completionRatios.isEmpty
        ? 0.0
        : completionRatios.reduce((a, b) => a + b) / completionRatios.length;

    // 2. Load adherence / progression ratio (strength exercises only)
    var exercisesWithLoadUp = 0;
    var exercisesWithLoadMaintained = 0;
    var exercisesWithLoadDrop = 0;
    final loadRatios = <double>[];

    for (final se in strengthExercises) {
      final working = se.sets.where((s) => s.isWorkingSet).toList();
      if (working.isEmpty) {
        loadRatios.add(0.0);
        continue;
      }

      final sessionMaxWeight = working.fold<double>(
        0.0,
        (maxVal, s) => s.weightKg > maxVal ? s.weightKg : maxVal,
      );
      final prevWeight = previousMaxWeightByExerciseId[se.exerciseId];

      if (prevWeight == null || prevWeight <= 0) {
        loadRatios.add(1.0);
      } else if (sessionMaxWeight > prevWeight + 0.01) {
        exercisesWithLoadUp++;
        loadRatios.add(1.0);
      } else if (sessionMaxWeight >= prevWeight - 0.01) {
        exercisesWithLoadMaintained++;
        loadRatios.add(1.0);
      } else {
        exercisesWithLoadDrop++;
        loadRatios.add((sessionMaxWeight / prevWeight).clamp(0.0, 0.80));
      }
    }

    final loadRatio = loadRatios.isEmpty
        ? 1.0
        : loadRatios.reduce((a, b) => a + b) / loadRatios.length;

    // 3. Rep range & cardio target-duration adherence
    var setsBelowMinReps = 0;
    final targetScores = <double>[];

    for (final se in strengthExercises) {
      final working = se.sets.where((s) => s.isWorkingSet);
      for (final s in working) {
        if (s.repsCompleted >= se.targetRepsMax) {
          targetScores.add(1.0);
        } else if (s.repsCompleted >= se.targetRepsMin) {
          targetScores.add(0.92);
        } else {
          setsBelowMinReps++;
          final ratio =
              ((s.repsCompleted / math.max(1, se.targetRepsMin)) * 0.65)
                  .clamp(0.0, 0.65);
          targetScores.add(ratio);
        }
      }
    }

    for (final se in cardioExercises) {
      if (se.totalCardioDurationSeconds <= 0) continue;
      final mins = se.totalCardioDurationSeconds / 60.0;
      if (mins >= se.targetRepsMax) {
        targetScores.add(1.0);
      } else if (mins >= se.targetRepsMin) {
        targetScores.add(0.92);
      } else {
        final ratio =
            ((mins / math.max(1, se.targetRepsMin)) * 0.65).clamp(0.0, 0.65);
        targetScores.add(ratio);
      }
    }

    final targetRatio = targetScores.isEmpty
        ? 0.0
        : targetScores.reduce((a, b) => a + b) / targetScores.length;

    // 4. Execution Score (0–100)
    final double rawExecutionScore;
    if (strengthExercises.isNotEmpty) {
      rawExecutionScore =
          (completionRatio * 40.0) + (loadRatio * 30.0) + (targetRatio * 30.0);
    } else {
      rawExecutionScore = (completionRatio * 60.0) + (targetRatio * 40.0);
    }
    final executionScore = rawExecutionScore.round().clamp(0, 100);

    // 5. Auto-RPE (5.0–10.0, 0.5 steps)
    final rirValues = completedStrengthSetsList
        .where((s) => s.rirActual != null)
        .map((s) => s.rirActual!)
        .toList();
    final hasDropSets = completedStrengthSetsList.any(
      (s) => s.setType == SetType.dropSet || s.dropSets.isNotEmpty,
    );

    final double autoRpe;
    final RpeEstimationSource rpeSource;
    double? averageRir;

    if (strengthExercises.isEmpty || completedStrengthSetsList.isEmpty) {
      rpeSource = RpeEstimationSource.cardioOnly;
      if (completionRatio >= 1.0) {
        autoRpe = 7.0;
      } else if (completionRatio >= 0.7) {
        autoRpe = 6.0;
      } else {
        autoRpe = 5.5;
      }
    } else if (rirValues.isNotEmpty) {
      rpeSource = RpeEstimationSource.rirBased;
      averageRir = rirValues.reduce((a, b) => a + b) / rirValues.length;
      var rpe = 10.0 - averageRir;
      if (hasDropSets) {
        rpe += 0.3;
      }
      if (rirValues.where((r) => r == 0).length >= 2) {
        rpe += 0.2;
      }
      autoRpe = _roundHalf(rpe.clamp(5.0, 10.0));
    } else {
      rpeSource = RpeEstimationSource.loadAndCompletionBased;
      final loggedStrengthExercises = strengthExercises
          .where((se) => se.sets.any((s) => s.isWorkingSet))
          .toList();
      final base = loggedStrengthExercises.isEmpty
          ? 8.0
          : loggedStrengthExercises
                  .map((se) => (10.0 - se.targetRir).clamp(6.0, 9.5))
                  .reduce((a, b) => a + b) /
              loggedStrengthExercises.length;

      var rpe = base;
      if (exercisesWithLoadUp > 0) {
        rpe += 0.5;
      }
      if (hasDropSets) {
        rpe += 0.5;
      }
      if (targetRatio >= 0.95 &&
          completionRatio >= 0.95 &&
          exercisesWithLoadDrop == 0) {
        rpe += 0.5;
      }
      if (exercisesWithLoadDrop > 0) {
        rpe -= 0.5 * math.min(2, exercisesWithLoadDrop);
      }
      if (setsBelowMinReps > 0) {
        rpe -= 0.5;
      }
      if (completionRatio < 0.7) {
        rpe -= 0.5;
      }
      autoRpe = _roundHalf(rpe.clamp(5.5, 9.5));
    }

    final scoreLabel = _labelForScore(executionScore);
    final rationale = _buildRationale(
      rpeSource: rpeSource,
      averageRir: averageRir,
      completedStrengthSets: completedStrengthSetsList.length,
      targetStrengthSets: targetStrengthSets,
      cardioMinutesLogged: cardioMinutesLogged,
      exercisesWithLoadUp: exercisesWithLoadUp,
      exercisesWithLoadDrop: exercisesWithLoadDrop,
      setsBelowMinReps: setsBelowMinReps,
      strengthExercises: strengthExercises,
    );

    return SessionPerformanceSummary(
      autoRpe: autoRpe,
      executionScore: executionScore,
      scoreLabel: scoreLabel,
      rationale: rationale,
      rpeSource: rpeSource,
      averageRir: averageRir,
      completedStrengthSets: completedStrengthSetsList.length,
      targetStrengthSets: targetStrengthSets,
      cardioMinutesLogged: cardioMinutesLogged,
      exercisesWithLoadUp: exercisesWithLoadUp,
      exercisesWithLoadMaintained: exercisesWithLoadMaintained,
      exercisesWithLoadDrop: exercisesWithLoadDrop,
      setsBelowMinReps: setsBelowMinReps,
    );
  }

  static double _roundHalf(double value) => (value * 2).round() / 2.0;

  static String _labelForScore(int score) {
    if (score >= 90) return 'Execução excelente';
    if (score >= 75) return 'Execução sólida';
    if (score >= 55) return 'Execução moderada';
    return 'Abaixo da meta';
  }

  static String _buildRationale({
    required RpeEstimationSource rpeSource,
    required double? averageRir,
    required int completedStrengthSets,
    required int targetStrengthSets,
    required int cardioMinutesLogged,
    required int exercisesWithLoadUp,
    required int exercisesWithLoadDrop,
    required int setsBelowMinReps,
    required List<SessionExercise> strengthExercises,
  }) {
    final parts = <String>[];
    if (rpeSource == RpeEstimationSource.rirBased && averageRir != null) {
      parts.add('RIR médio ${averageRir.toStringAsFixed(1).replaceAll('.', ',')}');
    }
    if (strengthExercises.isNotEmpty) {
      parts.add('$completedStrengthSets/$targetStrengthSets séries');
    }
    if (cardioMinutesLogged > 0) {
      parts.add('$cardioMinutesLogged min cardio');
    }
    if (exercisesWithLoadUp > 0) {
      parts.add('$exercisesWithLoadUp subida(s) de carga');
    } else if (exercisesWithLoadDrop > 0) {
      parts.add('$exercisesWithLoadDrop queda(s) de carga');
    } else if (setsBelowMinReps > 0) {
      parts.add('$setsBelowMinReps série(s) abaixo do mínimo');
    } else if (strengthExercises.isNotEmpty) {
      parts.add('carga mantida e faixa cumprida');
    }
    return parts.join(' · ');
  }
}
