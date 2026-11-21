import 'package:personal_fitness_os/features/nutrition/data/models/meal_model.dart';
import 'package:personal_fitness_os/features/nutrition/data/models/nutrition_goal_model.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';

/// DTO for `daily_nutrition` table in Supabase.
class DailyNutritionModel {
  const DailyNutritionModel({
    required this.id,
    this.userId,
    required this.date,
    this.goal,
    this.meals = const [],
    this.notes,
  });

  final String id;
  final String? userId;
  final DateTime date;
  final NutritionGoalModel? goal;
  final List<MealModel> meals;
  final String? notes;

  factory DailyNutritionModel.fromJson(
    Map<String, dynamic> json, {
    NutritionGoalModel? goal,
  }) {
    final mealsList = (json['meals'] as List<dynamic>?)
            ?.map((e) => MealModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return DailyNutritionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      date: DateTime.parse(json['date'] as String),
      goal: goal,
      meals: mealsList,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'date': date.toIso8601String().split('T').first,
      if (notes != null) 'notes': notes,
    };
  }

  DailyNutrition toDomain() {
    return DailyNutrition(
      id: id,
      userId: userId,
      date: date,
      goal: goal?.toDomain(),
      meals: meals.map((m) => m.toDomain()).toList(),
      notes: notes,
    );
  }
}
