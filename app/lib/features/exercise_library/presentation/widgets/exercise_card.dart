import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    required this.exercise,
    this.onTap,
    super.key,
  });

  final Exercise exercise;
  final VoidCallback? onTap;

  static String getMuscleLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'chest':
        return 'Peito';
      case 'back':
        return 'Costas';
      case 'quadriceps':
        return 'Quadríceps';
      case 'hamstrings':
        return 'Posterior';
      case 'glutes':
        return 'Glúteos';
      case 'calves':
        return 'Panturrilha';
      case 'anterior_deltoid':
        return 'Deltóide Ant.';
      case 'lateral_deltoid':
        return 'Deltóide Lat.';
      case 'posterior_deltoid':
        return 'Deltóide Post.';
      case 'shoulders':
        return 'Ombros';
      case 'biceps':
        return 'Bíceps';
      case 'triceps':
        return 'Tríceps';
      case 'forearms':
        return 'Antebraço';
      case 'abs':
        return 'Abdômen';
      case 'obliques':
        return 'Oblíquos';
      case 'core':
        return 'Core';
      case 'lower_back':
        return 'Lombar';
      default:
        return raw;
    }
  }

  static Color getMuscleColor(BuildContext context, String raw) {
    final colors = context.fitnessColors;
    switch (raw.toLowerCase()) {
      case 'chest':
        return colors.muscleChest;
      case 'back':
      case 'traps':
      case 'lats':
      case 'rhomboids':
        return colors.muscleBack;
      case 'quadriceps':
      case 'hamstrings':
      case 'glutes':
      case 'calves':
      case 'legs':
        return colors.muscleLegs;
      case 'anterior_deltoid':
      case 'lateral_deltoid':
      case 'posterior_deltoid':
      case 'shoulders':
        return colors.muscleShoulders;
      case 'biceps':
      case 'triceps':
      case 'forearms':
      case 'arms':
        return colors.muscleArms;
      case 'abs':
      case 'obliques':
      case 'core':
      case 'lower_back':
        return colors.muscleCore;
      default:
        return colors.progressNeutral;
    }
  }

  static String getEquipmentLabel(String? raw) {
    if (raw == null) return '';
    switch (raw.toLowerCase()) {
      case 'barbell':
        return 'Barra';
      case 'dumbbell':
        return 'Halteres';
      case 'machine':
        return 'Máquina';
      case 'cable':
        return 'Cabo / Polia';
      case 'bodyweight':
        return 'Peso Corporal';
      default:
        return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final muscleColor = getMuscleColor(context, exercise.primaryMuscleGroup);
    final muscleLabel = getMuscleLabel(exercise.primaryMuscleGroup);
    final equipmentLabel = getEquipmentLabel(exercise.equipment);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          // Muscle indicator stripe / badge
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: muscleColor,
              borderRadius: BorderRadius.circular(context.appRadius.small),
            ),
          ),
          const SizedBox(width: 14),

          // Main info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and custom tag
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (exercise.isCustom)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.appColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(context.appRadius.small),
                          border: Border.all(
                            color: context.appColors.primary.withOpacity(0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Custom',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.appColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Muscle and Equipment tags
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: muscleColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(context.appRadius.small),
                      ),
                      child: Text(
                        muscleLabel,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: muscleColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (equipmentLabel.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '·',
                        style: TextStyle(color: context.appColors.textTertiary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        equipmentLabel,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Action arrow
          Icon(
            Icons.chevron_right_rounded,
            color: context.appColors.textTertiary,
            size: 22,
          ),
        ],
      ),
    ),
  );
}
}
