import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/utils/pt_br_copy_utils.dart';
import 'package:personal_fitness_os/core/widgets/liftr_icon.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/widgets/exercise_diagram.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    required this.exercise,
    this.onTap,
    this.margin,
    super.key,
  });

  final Exercise exercise;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

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
        return 'Deltoide ant.';
      case 'lateral_deltoid':
        return 'Deltoide lat.';
      case 'posterior_deltoid':
        return 'Deltoide post.';
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

  static Color getMuscleColor(BuildContext context, String raw) =>
      context.appColors.textSecondary;

  static String getEquipmentLabel(String? raw) => formatEquipmentPtBr(raw);

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final subtitle = [
      getMuscleLabel(exercise.primaryMuscleGroup),
      getEquipmentLabel(exercise.equipment),
      if (exercise.isCustom) 'Personalizado',
    ].where((item) => item.isNotEmpty).join(' · ');

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Column(
        children: [
          Semantics(
            button: onTap != null,
            label: '${exercise.name}, $subtitle',
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: spacing.space12),
                  child: Row(
                    children: [
                      ExerciseDiagram(exercise: exercise, size: 40),
                      SizedBox(width: spacing.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              exercise.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.appColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const LiftrIcon(LiftrIconName.chevron, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: context.appColors.divider),
        ],
      ),
    );
  }
}
