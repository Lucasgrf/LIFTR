/// Pure Domain Entity representing daily calorie and macronutrient targets.
class NutritionGoal {
  const NutritionGoal({
    required this.id,
    this.userId,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.effectiveFrom,
    this.effectiveUntil,
    this.notes,
  });

  final String id;
  final String? userId;
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final DateTime? effectiveFrom;
  final DateTime? effectiveUntil;
  final String? notes;

  bool isActiveOn(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    if (effectiveFrom != null) {
      final fromDate =
          DateTime(effectiveFrom!.year, effectiveFrom!.month, effectiveFrom!.day);
      if (targetDate.isBefore(fromDate)) return false;
    }
    if (effectiveUntil != null) {
      final untilDate = DateTime(
          effectiveUntil!.year, effectiveUntil!.month, effectiveUntil!.day);
      if (targetDate.isAfter(untilDate)) return false;
    }
    return true;
  }

  NutritionGoal copyWith({
    String? id,
    String? userId,
    int? calories,
    int? proteinGrams,
    int? carbsGrams,
    int? fatGrams,
    DateTime? effectiveFrom,
    DateTime? effectiveUntil,
    String? notes,
  }) {
    return NutritionGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveUntil: effectiveUntil ?? this.effectiveUntil,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NutritionGoal &&
        other.id == id &&
        other.userId == userId &&
        other.calories == calories &&
        other.proteinGrams == proteinGrams &&
        other.carbsGrams == carbsGrams &&
        other.fatGrams == fatGrams &&
        other.effectiveFrom == effectiveFrom &&
        other.effectiveUntil == effectiveUntil &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        calories,
        proteinGrams,
        carbsGrams,
        fatGrams,
        effectiveFrom,
        effectiveUntil,
        notes,
      );
}
