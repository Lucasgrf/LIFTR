import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';
import 'package:personal_fitness_os/features/nutrition/presentation/widgets/macro_progress_bar.dart';
import 'package:personal_fitness_os/features/nutrition/presentation/widgets/nutrition_goal_modal.dart';

class CalorieMacroTargetCard extends StatelessWidget {
  const CalorieMacroTargetCard({
    super.key,
    required this.dailyNutrition,
  });

  final DailyNutrition dailyNutrition;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final goal = dailyNutrition.goal;

    final targetCalories = goal?.calories ?? 0;
    final totalCalories = dailyNutrition.totalCalories;
    final remainingCalories = dailyNutrition.remainingCalories;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title and Edit Goal button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RESUMO NUTRICIONAL',
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textSecondary,
                  letterSpacing: 1.1,
                ),
              ),
              InkWell(
                onTap: () => NutritionGoalModal.show(
                  context,
                  currentGoal: goal,
                ),
                borderRadius: BorderRadius.circular(context.appRadius.small),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        goal != null ? 'Editar Meta' : 'Definir Meta',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Calorie Row: Consumed vs Remaining vs Goal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CalorieStat(
                label: 'Consumidas',
                value: '${totalCalories.toStringAsFixed(0)} kcal',
                color: colors.textPrimary,
              ),
              _CalorieStat(
                label: 'Restantes',
                value: targetCalories > 0
                    ? '${remainingCalories.toStringAsFixed(0)} kcal'
                    : '--',
                color: remainingCalories >= 0
                    ? fitnessColors.progressUp
                    : fitnessColors.progressDown,
              ),
              _CalorieStat(
                label: 'Meta',
                value: targetCalories > 0 ? '$targetCalories kcal' : '--',
                color: colors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Calorie Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(context.appRadius.full),
            child: LinearProgressIndicator(
              value: dailyNutrition.caloriesProgress,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                remainingCalories >= 0 ? colors.primary : fitnessColors.progressDown,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Macronutrient Progress Bars
          MacroProgressBar(
            label: 'Proteína',
            consumedGrams: dailyNutrition.totalProtein,
            targetGrams: goal?.proteinGrams ?? 0,
            color: fitnessColors.muscleChest,
          ),
          const SizedBox(height: 12),
          MacroProgressBar(
            label: 'Carboidratos',
            consumedGrams: dailyNutrition.totalCarbs,
            targetGrams: goal?.carbsGrams ?? 0,
            color: fitnessColors.progressMaintain,
          ),
          const SizedBox(height: 12),
          MacroProgressBar(
            label: 'Gorduras',
            consumedGrams: dailyNutrition.totalFat,
            targetGrams: goal?.fatGrams ?? 0,
            color: fitnessColors.muscleArms,
          ),
        ],
      ),
    );
  }
}

class _CalorieStat extends StatelessWidget {
  const _CalorieStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
