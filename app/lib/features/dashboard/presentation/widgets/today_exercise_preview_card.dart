import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/workout_card_palette.dart';
import 'package:personal_fitness_os/core/utils/pt_br_copy_utils.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/progression_recommendation.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';

double? computeDoubleProgressionRatio({
  required List<LoggedSet> previousWorkingSets,
  required int targetRepsMax,
}) {
  if (previousWorkingSets.isEmpty || targetRepsMax <= 0) return null;
  final setsAtCeiling = previousWorkingSets
      .where((set) => set.repsCompleted >= targetRepsMax)
      .length;
  return (setsAtCeiling / previousWorkingSets.length).clamp(0.0, 1.0);
}

class TodayExercisePreviewCard extends ConsumerWidget {
  const TodayExercisePreviewCard({
    super.key,
    required this.index,
    required this.workoutExercise,
    this.embedded = false,
  });

  final int index;
  final WorkoutExercise workoutExercise;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workingSets = workoutExercise.setTemplates
        .where((set) => set.isWorkingSet)
        .toList();
    final firstWorking = workingSets.firstOrNull;
    final isCardio = workoutExercise.isCardio;
    final repsMin = firstWorking?.targetRepsMin;
    final repsMax = firstWorking?.targetRepsMax;
    final ProgressionRecommendation? recommendation =
        isCardio || firstWorking == null || repsMin == null || repsMax == null
        ? null
        : ref
              .watch(
                exerciseProgressionProvider(
                  ExerciseProgressionParams(
                    exerciseId: workoutExercise.exerciseId,
                    targetRepsMin: repsMin,
                    targetRepsMax: repsMax,
                    targetRir: firstWorking.targetRirMin ?? 0,
                    equipment: workoutExercise.exercise?.equipment,
                  ),
                ),
              )
              .asData
              ?.value;

    final exerciseName = workoutExercise.exercise?.name ?? 'Exercício';
    final prescription =
        firstWorking == null || repsMin == null || repsMax == null
        ? 'Sem prescrição'
        : isCardio
        ? (repsMin == repsMax ? '$repsMin min' : '$repsMin–$repsMax min')
        : '${workingSets.length} × $repsMin–$repsMax';
    final previousSets = recommendation?.previousWorkingSets ?? const [];
    final previousSummary = previousSets.isEmpty
        ? null
        : '${formatWeightKgPtBr(previousSets.map((set) => set.weightKg).reduce((a, b) => a > b ? a : b)).replaceFirst(RegExp(r'\s*kg$'), '')} × ${previousSets.map((set) => '${set.repsCompleted}').join(', ')}';

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: index == 0
                ? WorkoutCardPalette.ink
                : WorkoutCardPalette.ink.withValues(alpha: .22),
            width: index == 0 ? 2 : 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  exerciseName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: WorkoutCardPalette.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                prescription,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: WorkoutCardPalette.ink,
                  fontWeight: FontWeight.w600,
                  fontFeatures: AppTypography.tabularFeatures,
                ),
              ),
            ],
          ),
          if (previousSummary != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                previousSummary,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: WorkoutCardPalette.penInk,
                  fontWeight: FontWeight.w600,
                  fontFeatures: AppTypography.tabularFeatures,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
