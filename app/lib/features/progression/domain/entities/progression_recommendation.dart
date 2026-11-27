import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/core/utils/pt_br_copy_utils.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';

enum ProgressionType {
  increase,
  maintain,
  decrease,
}

/// Pure Domain Entity representing progressive overload recommendation calculated for an exercise.
class ProgressionRecommendation {
  const ProgressionRecommendation({
    required this.type,
    required this.suggestedWeightKg,
    required this.weightDeltaKg,
    required this.rationale,
    this.previousSummary,
    this.targetRepsMin,
    this.targetRepsMax,
    this.targetRir,
    this.consecutiveCeilingHits = 0,
    this.requiredCeilingHits = 2,
    this.previousWorkingSets = const [],
  });

  final ProgressionType type;
  final double suggestedWeightKg;
  final double weightDeltaKg;
  final String rationale;
  final String? previousSummary;
  final int? targetRepsMin;
  final int? targetRepsMax;
  final int? targetRir;
  final int consecutiveCeilingHits;
  final int requiredCeilingHits;
  final List<LoggedSet> previousWorkingSets;

  bool get isIncrease => type == ProgressionType.increase;
  bool get isMaintain => type == ProgressionType.maintain;
  bool get isDecrease => type == ProgressionType.decrease;

  String get shortActionLabel {
    switch (type) {
      case ProgressionType.increase:
        return '↗ Aumentar (+${formatWeightKgPtBr(weightDeltaKg)})';
      case ProgressionType.maintain:
        return '→ Manter (${formatWeightKgPtBr(suggestedWeightKg)})';
      case ProgressionType.decrease:
        return '↘ Ajustar (${formatWeightKgPtBr(suggestedWeightKg)})';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgressionRecommendation &&
        other.type == type &&
        other.suggestedWeightKg == suggestedWeightKg &&
        other.weightDeltaKg == weightDeltaKg &&
        other.rationale == rationale &&
        other.previousSummary == previousSummary &&
        other.targetRepsMin == targetRepsMin &&
        other.targetRepsMax == targetRepsMax &&
        other.targetRir == targetRir &&
        other.consecutiveCeilingHits == consecutiveCeilingHits &&
        other.requiredCeilingHits == requiredCeilingHits &&
        listEquals(other.previousWorkingSets, previousWorkingSets);
  }

  @override
  int get hashCode => Object.hash(
        type,
        suggestedWeightKg,
        weightDeltaKg,
        rationale,
        previousSummary,
        targetRepsMin,
        targetRepsMax,
        targetRir,
        consecutiveCeilingHits,
        requiredCeilingHits,
        Object.hashAll(previousWorkingSets),
      );
}
