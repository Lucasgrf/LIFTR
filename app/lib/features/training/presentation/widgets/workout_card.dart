import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/workout_card_palette.dart';
import 'package:personal_fitness_os/core/widgets/liftr_icon.dart';
import 'package:personal_fitness_os/core/widgets/liftr_workout_card.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';

/// A colored ficha used wherever the program is shown outside its queue.
class WorkoutCard extends StatelessWidget {
  const WorkoutCard({required this.workout, this.onTap, super.key});

  final Workout workout;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = WorkoutCardPalette.forIndex(workout.sortOrder);
    final sets = workout.totalWorkingSetsCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: onTap != null,
        label:
            'Ficha ${workout.sortOrder + 1}, ${workout.name}, ${workout.totalExercisesCount} exercícios, $sets séries',
        child: LiftrWorkoutCard(
          color: color,
          onTap: onTap,
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${workout.sortOrder + 1}',
                  style: context.textTheme.displaySmall?.copyWith(
                    color: WorkoutCardPalette.ink,
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppTypography.tabularFeatures,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: WorkoutCardPalette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${workout.totalExercisesCount} exercícios, $sets séries · ${workout.dayOfWeekLabel}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: WorkoutCardPalette.secondaryInk,
                        fontFeatures: AppTypography.tabularFeatures,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const LiftrIcon(
                LiftrIconName.chevron,
                color: WorkoutCardPalette.secondaryInk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
