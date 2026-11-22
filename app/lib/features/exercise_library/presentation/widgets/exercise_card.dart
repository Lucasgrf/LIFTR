import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/widgets/exercise_diagram.dart';

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
    return context.appColors.primary;
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
    final muscleLabel = getMuscleLabel(exercise.primaryMuscleGroup);
    final equipmentLabel = getEquipmentLabel(exercise.equipment);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExerciseDiagram(exercise: exercise, size: 48),
            const SizedBox(width: 14),

            // Main info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      if (exercise.isCustom) ...[
                        const SizedBox(width: 8),
                        const LiftrBadge(
                          label: 'Custom',
                          tone: LiftrBadgeTone.brand,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Muscle and Equipment tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      LiftrBadge(
                        label: muscleLabel,
                        tone: LiftrBadgeTone.neutral,
                      ),
                      if (equipmentLabel.isNotEmpty) ...[
                        Text(
                          '·',
                          style: TextStyle(color: context.appColors.textTertiary),
                        ),
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

            const SizedBox(width: 8),
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
