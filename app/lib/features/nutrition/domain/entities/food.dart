/// Pure Domain Entity representing a food item with its nutritional profile.
class Food {
  const Food({
    required this.id,
    this.userId,
    required this.name,
    this.brand,
    this.servingSize = 100.0,
    this.servingUnit = 'g',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0.0,
    this.barcode,
    this.isCustom = false,
    this.createdAt,
  });

  final String id;
  final String? userId;
  final String name;
  final String? brand;
  final double servingSize;
  final String servingUnit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String? barcode;
  final bool isCustom;
  final DateTime? createdAt;

  String get displayName => brand != null && brand!.isNotEmpty
      ? '$name ($brand)'
      : name;

  Food copyWith({
    String? id,
    String? userId,
    String? name,
    String? brand,
    double? servingSize,
    String? servingUnit,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    String? barcode,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return Food(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      barcode: barcode ?? this.barcode,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Food &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.brand == brand &&
        other.servingSize == servingSize &&
        other.servingUnit == servingUnit &&
        other.calories == calories &&
        other.protein == protein &&
        other.carbs == carbs &&
        other.fat == fat &&
        other.fiber == fiber &&
        other.barcode == barcode &&
        other.isCustom == isCustom;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        name,
        brand,
        servingSize,
        servingUnit,
        calories,
        protein,
        carbs,
        fat,
        fiber,
        barcode,
        isCustom,
      );
}
