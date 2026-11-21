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
  });

  final ProgressionType type;
  final double suggestedWeightKg;
  final double weightDeltaKg;
  final String rationale;
  final String? previousSummary;
  final int? targetRepsMin;
  final int? targetRepsMax;
  final int? targetRir;

  bool get isIncrease => type == ProgressionType.increase;
  bool get isMaintain => type == ProgressionType.maintain;
  bool get isDecrease => type == ProgressionType.decrease;

  String get shortActionLabel {
    switch (type) {
      case ProgressionType.increase:
        return '↗ Aumentar (+${weightDeltaKg.toStringAsFixed(1)} kg)';
      case ProgressionType.maintain:
        return '→ Manter (${suggestedWeightKg.toStringAsFixed(1)} kg)';
      case ProgressionType.decrease:
        return '↘ Ajustar (${suggestedWeightKg.toStringAsFixed(1)} kg)';
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
        other.targetRir == targetRir;
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
      );
}
