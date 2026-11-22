import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/widgets/exercise_card.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/set_template_row.dart';

class WorkoutExerciseCard extends StatelessWidget {
  const WorkoutExerciseCard({
    required this.workoutExercise,
    this.index = 1,
    this.onConfigureSets,
    this.onDelete,
    super.key,
  });

  final WorkoutExercise workoutExercise;
  final int index;
  final VoidCallback? onConfigureSets;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final exerciseName = workoutExercise.exercise?.name ?? 'Exercício $index';
    final primaryMuscle = workoutExercise.exercise?.primaryMuscleGroup ?? 'Geral';
    final muscleLabel = ExerciseCard.getMuscleLabel(primaryMuscle);
    final equipmentLabel = ExerciseCard.getEquipmentLabel(workoutExercise.exercise?.equipment);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Number + Exercise Name + Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order badge
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.appColors.border),
                  ),
                  child: Text(
                    '$index',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Name and tags
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exerciseName,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: context.appColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          LiftrBadge(
                            label: muscleLabel,
                            tone: LiftrBadgeTone.neutral,
                          ),
                          if (equipmentLabel.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '·',
                              style: TextStyle(color: context.appColors.textTertiary),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              equipmentLabel,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.appColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete button
                if (onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: context.appColors.textTertiary,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Remover do treino',
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Sets List
            if (workoutExercise.setTemplates.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.appColors.surfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(context.appRadius.small),
                  border: Border.all(
                    color: context.appColors.border.withValues(alpha: 0.5),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Text(
                  'Nenhuma série configurada',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.appColors.textTertiary,
                  ),
                ),
              )
            else
              ...workoutExercise.setTemplates.map(
                (template) => SetTemplateRow(template: template),
              ),

            const SizedBox(height: 10),

            // Action: Edit / Configure Sets button
            if (onConfigureSets != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onConfigureSets,
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Configurar Séries'),
                  style: TextButton.styleFrom(
                    foregroundColor: context.appColors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
