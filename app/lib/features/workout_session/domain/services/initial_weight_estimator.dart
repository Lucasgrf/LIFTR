import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/progression/domain/services/progression_engine.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';

@immutable
class InitialWeightSuggestion {
  const InitialWeightSuggestion({
    required this.weightKg,
    required this.recommendedRepsMin,
    required this.recommendedRepsMax,
    required this.isEstimated,
  });

  final double weightKg;
  final int recommendedRepsMin;
  final int recommendedRepsMax;
  final bool isEstimated;
}

/// Estimates safe, realistic starting working weights (in kg) when an exercise
/// has no prior logged history yet, calibrating by user experience level,
/// bodyweight, biological sex, movement pattern, equipment and rep range.
class InitialWeightEstimator {
  const InitialWeightEstimator._();

  static String _normalize(String input) {
    const replacements = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ç': 'c',
    };
    var out = input.trim().toLowerCase();
    replacements.forEach((k, v) {
      out = out.replaceAll(k, v);
    });
    return out;
  }

  static double _roundToStep(double raw, double step) {
    if (raw <= 0) return 0.0;
    final safeStep = step > 0 ? step : 2.5;
    final rounded = (raw / safeStep).round() * safeStep;
    return rounded < safeStep ? safeStep : rounded;
  }

  static double _tierValue(
    UserExperience experience, {
    required double beginner,
    required double intermediate,
    required double advanced,
  }) {
    switch (experience) {
      case UserExperience.beginner:
        return beginner;
      case UserExperience.intermediate:
        return intermediate;
      case UserExperience.advanced:
        return advanced;
    }
  }

  static InitialWeightSuggestion estimate({
    required Exercise? exercise,
    required UserExperience experience,
    required double bodyWeightKg,
    required String biologicalSex,
    int? targetRepsMin,
    int? targetRepsMax,
    double? equipmentIncrement,
  }) {
    if (exercise == null || exercise.isCardio) {
      return const InitialWeightSuggestion(
        weightKg: 0.0,
        recommendedRepsMin: 15,
        recommendedRepsMax: 20,
        isEstimated: false,
      );
    }

    final eq = (exercise.equipment ?? '').trim().toLowerCase();
    final pattern = (exercise.movementPattern ?? '').trim().toLowerCase();
    final muscle = exercise.primaryMuscleGroup.trim().toLowerCase();
    final name = _normalize(exercise.name);

    final bool isCompound = const {
      'horizontal_push',
      'vertical_push',
      'horizontal_pull',
      'vertical_pull',
      'squat',
      'hinge',
      'lunge',
    }.contains(pattern);

    final int recRepsMin = targetRepsMin ?? (isCompound ? 6 : 12);
    final int recRepsMax = targetRepsMax ?? (isCompound ? 10 : 15);

    final bool isBodyweightMove = eq == 'bodyweight' ||
        name.contains('flexao') ||
        name.contains('prancha') ||
        name.contains('barra fixa') ||
        name.contains('paralela') ||
        (name.contains('abdominal') && eq != 'machine' && eq != 'cable');

    if (isBodyweightMove) {
      return InitialWeightSuggestion(
        weightKg: 0.0,
        recommendedRepsMin: recRepsMin,
        recommendedRepsMax: recRepsMax,
        isEstimated: true,
      );
    }

    final bw = bodyWeightKg.clamp(45.0, 125.0);
    final isFemale = biologicalSex.toUpperCase() == 'F';
    final isLowerBody =
        muscle == 'legs' || muscle == 'glutes' || pattern == 'squat' || pattern == 'hinge' || pattern == 'lunge';
    final sexFactor = isFemale ? (isLowerBody ? 0.78 : 0.60) : 1.0;

    // Rep-range multiplier relative to ~8-10 reps baseline.
    final avgReps = ((recRepsMin + recRepsMax) / 2.0);
    final repFactor = avgReps >= 13
        ? 0.84
        : (avgReps <= 7 ? 1.08 : 1.0);

    final isDumbbell = eq == 'dumbbell' || eq == 'kettlebell';
    final isBarbell = eq == 'barbell' || eq == 'smith_machine' || eq == 'smithmachine';

    double bwRatio;

    if (pattern == 'horizontal_push' ||
        name.contains('supino') ||
        (muscle == 'chest' && !name.contains('crucifixo') && !name.contains('peck'))) {
      if (isDumbbell) {
        // Per dumbbell: ~6-8 kg beginner, ~16-18 kg intermediate, ~24-26 kg advanced (at ~75-80kg BW)
        bwRatio = _tierValue(experience, beginner: 0.08, intermediate: 0.21, advanced: 0.31);
      } else if (isBarbell) {
        // Total barbell load (bar + plates): ~30 kg beginner, ~60 kg intermediate, ~85 kg advanced
        bwRatio = _tierValue(experience, beginner: 0.38, intermediate: 0.75, advanced: 1.08);
      } else {
        bwRatio = _tierValue(experience, beginner: 0.32, intermediate: 0.58, advanced: 0.85);
      }
    } else if (pattern == 'squat' ||
        name.contains('agachamento') ||
        name.contains('leg press') ||
        name.contains('hack')) {
      if (name.contains('leg press')) {
        bwRatio = _tierValue(experience, beginner: 0.90, intermediate: 1.65, advanced: 2.35);
      } else if (isDumbbell) {
        bwRatio = _tierValue(experience, beginner: 0.12, intermediate: 0.24, advanced: 0.34);
      } else if (isBarbell) {
        bwRatio = _tierValue(experience, beginner: 0.50, intermediate: 0.95, advanced: 1.35);
      } else {
        bwRatio = _tierValue(experience, beginner: 0.60, intermediate: 1.10, advanced: 1.60);
      }
    } else if (pattern == 'hinge' ||
        name.contains('terra') ||
        name.contains('stiff') ||
        name.contains('elevacao pelvica') ||
        name.contains('hip thrust')) {
      if (isDumbbell) {
        bwRatio = _tierValue(experience, beginner: 0.14, intermediate: 0.26, advanced: 0.36);
      } else if (isBarbell) {
        bwRatio = _tierValue(experience, beginner: 0.55, intermediate: 1.05, advanced: 1.48);
      } else {
        bwRatio = _tierValue(experience, beginner: 0.45, intermediate: 0.85, advanced: 1.25);
      }
    } else if (pattern == 'lunge' ||
        name.contains('afundo') ||
        name.contains('bulgaro') ||
        name.contains('passada')) {
      if (isDumbbell) {
        bwRatio = _tierValue(experience, beginner: 0.08, intermediate: 0.18, advanced: 0.26);
      } else if (isBarbell) {
        bwRatio = _tierValue(experience, beginner: 0.35, intermediate: 0.65, advanced: 0.95);
      } else {
        bwRatio = _tierValue(experience, beginner: 0.30, intermediate: 0.55, advanced: 0.80);
      }
    } else if (pattern == 'horizontal_pull' ||
        pattern == 'vertical_pull' ||
        name.contains('remada') ||
        name.contains('puxada') ||
        name.contains('pulldown')) {
      if (isDumbbell) {
        bwRatio = _tierValue(experience, beginner: 0.11, intermediate: 0.22, advanced: 0.32);
      } else if (isBarbell) {
        bwRatio = _tierValue(experience, beginner: 0.38, intermediate: 0.68, advanced: 0.98);
      } else {
        bwRatio = _tierValue(experience, beginner: 0.35, intermediate: 0.60, advanced: 0.88);
      }
    } else if (pattern == 'vertical_push' || name.contains('desenvolvimento')) {
      if (isDumbbell) {
        bwRatio = _tierValue(experience, beginner: 0.08, intermediate: 0.18, advanced: 0.26);
      } else if (isBarbell) {
        bwRatio = _tierValue(experience, beginner: 0.28, intermediate: 0.50, advanced: 0.72);
      } else {
        bwRatio = _tierValue(experience, beginner: 0.25, intermediate: 0.45, advanced: 0.68);
      }
    } else if (muscle == 'legs' ||
        name.contains('extensora') ||
        name.contains('flexora') ||
        name.contains('panturrilha') ||
        name.contains('abdutora') ||
        name.contains('adutora')) {
      bwRatio = _tierValue(experience, beginner: 0.32, intermediate: 0.58, advanced: 0.88);
    } else if (muscle == 'shoulders' ||
        name.contains('elevacao lateral') ||
        name.contains('elevacao frontal')) {
      if (isDumbbell) {
        bwRatio = _tierValue(experience, beginner: 0.055, intermediate: 0.12, advanced: 0.18);
      } else {
        bwRatio = _tierValue(experience, beginner: 0.12, intermediate: 0.22, advanced: 0.32);
      }
    } else if (muscle == 'arms' ||
        muscle == 'biceps' ||
        muscle == 'triceps' ||
        name.contains('rosca') ||
        name.contains('triceps')) {
      if (isDumbbell) {
        bwRatio = _tierValue(experience, beginner: 0.08, intermediate: 0.15, advanced: 0.22);
      } else {
        bwRatio = _tierValue(experience, beginner: 0.20, intermediate: 0.36, advanced: 0.52);
      }
    } else if (muscle == 'chest') {
      // Chest isolations (crucifixo, peck deck, crossover)
      if (isDumbbell) {
        bwRatio = _tierValue(experience, beginner: 0.08, intermediate: 0.16, advanced: 0.24);
      } else {
        bwRatio = _tierValue(experience, beginner: 0.25, intermediate: 0.48, advanced: 0.72);
      }
    } else {
      // General fallback
      bwRatio = isDumbbell
          ? _tierValue(experience, beginner: 0.08, intermediate: 0.16, advanced: 0.24)
          : _tierValue(experience, beginner: 0.25, intermediate: 0.45, advanced: 0.68);
    }

    final step = equipmentIncrement ?? ProgressionEngine.defaultWeightIncrement(exercise.equipment);
    final rawWeight = bw * bwRatio * sexFactor * repFactor;
    final rounded = _roundToStep(rawWeight, step);

    return InitialWeightSuggestion(
      weightKg: rounded,
      recommendedRepsMin: recRepsMin,
      recommendedRepsMax: recRepsMax,
      isEstimated: true,
    );
  }
}
