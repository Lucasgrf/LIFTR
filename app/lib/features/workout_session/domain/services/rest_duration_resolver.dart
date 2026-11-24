import 'package:personal_fitness_os/core/constants/app_constants.dart';

/// Resolves evidence-based rest durations between sets:
/// - Cardio: 0s
/// - Warmup / Mobility: 60s
/// - Heavy compound strength/hypertrophy sets (<= 10 reps, or 8-12 heavy compounds): 180s (3 min)
/// - Lighter isolation / higher-rep sets (12-15+ reps, or 8-12 accessories): 120s (2 min)
class RestDurationResolver {
  const RestDurationResolver._();

  static const int heavyCompoundRestSeconds = 180;
  static const int lightAccessoryRestSeconds = 120;
  static const int warmupRestSeconds = 60;

  static const Set<String> _heavyMovementPatterns = {
    'squat',
    'hinge',
    'horizontal_push',
    'vertical_push',
    'horizontal_pull',
    'vertical_pull',
  };

  static const Set<String> _lightMuscleGroups = {
    'arms',
    'biceps',
    'triceps',
    'forearms',
    'abs',
    'core',
    'calves',
  };

  static bool isHeavyCompoundPattern(String? movementPattern) {
    final normalized = movementPattern?.trim().toLowerCase() ?? '';
    return _heavyMovementPatterns.contains(normalized);
  }

  static int resolve({
    required int targetRepsMin,
    required int targetRepsMax,
    String? movementPattern,
    String? primaryMuscleGroup,
    String? equipment,
    bool isCardio = false,
    SetType setType = SetType.working,
    int? explicitTemplateRestSeconds,
  }) {
    if (isCardio) return 0;
    if (setType == SetType.warmup || setType == SetType.mobility) {
      return warmupRestSeconds;
    }

    final normalizedMuscle = primaryMuscleGroup?.trim().toLowerCase() ?? '';
    final normalizedPattern = movementPattern?.trim().toLowerCase() ?? '';

    final bool hasCustomRest = explicitTemplateRestSeconds != null &&
        explicitTemplateRestSeconds > 0 &&
        explicitTemplateRestSeconds != AppConstants.defaultRestSeconds;

    // Explicit lighter / metabolic rep ranges always rest 2 minutes unless
    // the user explicitly configured a non-legacy custom rest value.
    final bool isLightRange = targetRepsMin >= 12 ||
        (targetRepsMax >= 14 && targetRepsMin >= 10) ||
        (targetRepsMax >= 15 &&
            (normalizedPattern == 'isolation' ||
                normalizedPattern == 'carry' ||
                _lightMuscleGroups.contains(normalizedMuscle)));

    if (isLightRange) {
      return hasCustomRest && explicitTemplateRestSeconds <= 150
          ? explicitTemplateRestSeconds
          : lightAccessoryRestSeconds;
    }

    // Heavy sets (e.g., 6-10 reps) rest 3 minutes.
    if (targetRepsMax > 0 && targetRepsMax <= 10) {
      return hasCustomRest && explicitTemplateRestSeconds >= 150
          ? explicitTemplateRestSeconds
          : heavyCompoundRestSeconds;
    }

    if (hasCustomRest) {
      return explicitTemplateRestSeconds;
    }

    // When exercise metadata is absent and the template explicitly requested
    // a rest duration for a <= 12 rep set (with targetRepsMin < 12), honor it.
    if (movementPattern == null &&
        primaryMuscleGroup == null &&
        equipment == null &&
        explicitTemplateRestSeconds != null &&
        explicitTemplateRestSeconds > 0) {
      return explicitTemplateRestSeconds;
    }

    // Intermediate range (e.g., 8-12): heavy multi-joint compounds use 3 min,
    // isolations/arms/core/calves use 2 min.
    if (isHeavyCompoundPattern(normalizedPattern) &&
        !_lightMuscleGroups.contains(normalizedMuscle)) {
      return heavyCompoundRestSeconds;
    }

    if (normalizedPattern == 'isolation' ||
        normalizedPattern == 'carry' ||
        _lightMuscleGroups.contains(normalizedMuscle)) {
      return lightAccessoryRestSeconds;
    }

    final eq = equipment?.trim().toLowerCase() ?? '';
    if (eq == 'barbell' || eq == 'smith_machine' || eq == 'smithmachine') {
      return heavyCompoundRestSeconds;
    }

    return lightAccessoryRestSeconds;
  }
}
