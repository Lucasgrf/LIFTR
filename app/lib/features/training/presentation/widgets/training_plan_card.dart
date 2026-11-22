import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';

class TrainingPlanCard extends StatelessWidget {
  const TrainingPlanCard({
    required this.plan,
    this.onTap,
    this.onActivate,
    this.isActivating = false,
    super.key,
  });

  final TrainingPlan plan;
  final VoidCallback? onTap;
  final VoidCallback? onActivate;
  final bool isActivating;

  @override
  Widget build(BuildContext context) {
    final activeColor = context.fitnessColors.progressUp;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row
            Row(
              children: [
                if (plan.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(context.appRadius.small),
                      border: Border.all(color: activeColor.withValues(alpha: 0.4), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: activeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'PLANO ATIVO',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: activeColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.appColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(context.appRadius.small),
                    ),
                    child: Text(
                      'ARQUIVADO',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.appColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                if (!plan.isActive && onActivate != null)
                  TextButton.icon(
                    onPressed: isActivating ? null : onActivate,
                    icon: isActivating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        : const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('Tornar Ativo'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.appColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Plan Name
            Text(
              plan.name,
              style: context.textTheme.titleLarge?.copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (plan.description != null && plan.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                plan.description!,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.appColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 14),

            // Metrics summary
            Row(
              children: [
                _buildMetric(
                  context,
                  Icons.calendar_today_rounded,
                  '${plan.totalWorkoutsCount} treinos/sem',
                ),
                const SizedBox(width: 16),
                _buildMetric(
                  context,
                  Icons.format_list_numbered_rounded,
                  '${plan.totalWeeklySetsCount} séries válidas',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.appColors.textTertiary),
        const SizedBox(width: 6),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.appColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
