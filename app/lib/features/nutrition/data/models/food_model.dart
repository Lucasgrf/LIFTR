import 'package:personal_fitness_os/features/nutrition/domain/entities/food.dart';

/// DTO for `foods` table in Supabase.
class FoodModel {
  const FoodModel({
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

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      servingSize: (json['serving_size'] as num?)?.toDouble() ?? 100.0,
      servingUnit: json['serving_unit'] as String? ?? 'g',
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
      barcode: json['barcode'] as String?,
      isCustom: json['is_custom'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      if (brand != null) 'brand': brand,
      'serving_size': servingSize,
      'serving_unit': servingUnit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      if (barcode != null) 'barcode': barcode,
      'is_custom': isCustom,
    };
  }

  Food toDomain() {
    return Food(
      id: id,
      userId: userId,
      name: name,
      brand: brand,
      servingSize: servingSize,
      servingUnit: servingUnit,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      barcode: barcode,
      isCustom: isCustom,
      createdAt: createdAt,
    );
  }

  factory FoodModel.fromDomain(Food domain) {
    return FoodModel(
      id: domain.id,
      userId: domain.userId,
      name: domain.name,
      brand: domain.brand,
      servingSize: domain.servingSize,
      servingUnit: domain.servingUnit,
      calories: domain.calories,
      protein: domain.protein,
      carbs: domain.carbs,
      fat: domain.fat,
      fiber: domain.fiber,
      barcode: domain.barcode,
      isCustom: domain.isCustom,
      createdAt: domain.createdAt,
    );
  }
}
