import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/meal_food.dart';

class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.onAddFood,
    required this.onRemoveFood,
  });

  final Meal meal;
  final VoidCallback onAddFood;
  final ValueChanged<String> onRemoveFood;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Meal Name & Total Calories & Add Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${meal.totalCalories.toStringAsFixed(0)} kcal • ${meal.totalProtein.toStringAsFixed(0)}P • ${meal.totalCarbs.toStringAsFixed(0)}C • ${meal.totalFat.toStringAsFixed(0)}G',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add_rounded, size: 18),
                tooltip: 'Adicionar Alimento',
                visualDensity: VisualDensity.compact,
                onPressed: onAddFood,
              ),
            ],
          ),

          if (meal.foods.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Foods list
            ...meal.foods.map((foodItem) => _MealFoodRow(
                  item: foodItem,
                  onDelete: () => onRemoveFood(foodItem.id),
                )),
          ],
        ],
      ),
    );
  }
}

class _MealFoodRow extends StatelessWidget {
  const _MealFoodRow({
    required this.item,
    required this.onDelete,
  });

  final MealFood item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.foodName,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '${item.quantityGrams.toStringAsFixed(0)}g • ${item.calories.toStringAsFixed(0)} kcal (${item.protein.toStringAsFixed(0)}P / ${item.carbs.toStringAsFixed(0)}C / ${item.fat.toStringAsFixed(0)}G)',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: colors.textTertiary),
            visualDensity: VisualDensity.compact,
            tooltip: 'Remover Alimento',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
