import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/nutrition/domain/entities/daily_nutrition.dart';

class DashboardNutritionCard extends StatelessWidget {
  const DashboardNutritionCard({
    super.key,
    required this.nutrition,
  });

  final DailyNutrition nutrition;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    final goal = nutrition.goal;
    final totalCals = nutrition.totalCalories;
    final targetCals = goal?.calories.toDouble() ?? 2000.0;
    final calProgress = (totalCals / targetCals).clamp(0.0, 1.0);

    final totalProtein = nutrition.totalProtein;
    final targetProtein = goal?.proteinGrams.toDouble() ?? 150.0;
    final proteinProgress = (totalProtein / targetProtein).clamp(0.0, 1.0);

    return AppCard(
      onTap: () => context.go('/nutrition'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.restaurant_rounded,
                    size: 18,
                    color: fitnessColors.progressMaintain,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'NUTRIÇÃO HOJE',
                    style: context.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textSecondary,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textTertiary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Calories bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calorias',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Text(
                '${totalCals.round()} / ${targetCals.round()} kcal',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(context.appRadius.full),
            child: LinearProgressIndicator(
              value: calProgress,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                fitnessColors.progressMaintain,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // Protein bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Proteína',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Text(
                '${totalProtein.round()} / ${targetProtein.round()} g',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(context.appRadius.full),
            child: LinearProgressIndicator(
              value: proteinProgress,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                colors.primary,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
