import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/liftr_progress_bar.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/progression_recommendation.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';

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
    final colors = context.appColors;
    final radius = context.appRadius;
    final fitnessColors = context.fitnessColors;

    final workingSets = workoutExercise.setTemplates
        .where((s) => s.isWorkingSet)
        .toList();
    final firstWorking =
        workingSets.isNotEmpty ? workingSets.first : null;
    final setsCount =
        workingSets.isNotEmpty ? workingSets.length : 3;
    final repsMin = firstWorking?.targetRepsMin ?? 8;
    final repsMax = firstWorking?.targetRepsMax ?? 12;
    final targetRir = firstWorking?.targetRirMin ?? 2;

    final progressionAsync = ref.watch(
      exerciseProgressionProvider(
        ExerciseProgressionParams(
          exerciseId: workoutExercise.exerciseId,
          targetRepsMin: repsMin,
          targetRepsMax: repsMax,
          targetRir: targetRir,
          equipment: workoutExercise.exercise?.equipment,
        ),
      ),
    );

    final rec = progressionAsync.asData?.value;
    final suggestedWeight =
        (rec != null && rec.suggestedWeightKg > 0)
            ? rec.suggestedWeightKg
            : (firstWorking?.targetWeight ?? 0);

    final weightText = suggestedWeight > 0
        ? '${_formatWeight(suggestedWeight)} kg · '
        : '';
    final targetSummary = '$weightText$setsCount×$repsMin–$repsMax';

    final isIncrease = rec?.type == ProgressionType.increase;
    final progressValue = isIncrease
        ? 1.0
        : (rec != null && rec.suggestedWeightKg > 0 ? 0.78 : 0.45);
    final noteText = isIncrease
        ? 'Meta batida · +${_formatWeight(rec!.weightDeltaKg)} kg hoje'
        : (rec?.previousSummary != null && rec!.previousSummary!.isNotEmpty
            ? 'Última: ${rec.previousSummary}'
            : '$setsCount séries válidas · alvo $repsMin–$repsMax reps');

    final indexLabel = (index + 1).toString().padLeft(2, '0');
    final exerciseName = workoutExercise.exercise?.name ?? 'Exercício ${index + 1}';

    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: embedded ? 80 : 88),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 26,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  indexLabel,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppTypography.tabularFeatures,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          exerciseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleSmall?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 2,
                        child: Text(
                          targetSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontFeatures: AppTypography.tabularFeatures,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  LiftrProgressBar(
                    progress: progressValue,
                    height: 5,
                    color: isIncrease ? fitnessColors.progressUp : colors.primary,
                    trackColor: colors.surfaceElevated,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    noteText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: isIncrease
                          ? fitnessColors.progressUp
                          : colors.textTertiary,
                      fontWeight:
                          isIncrease ? FontWeight.w600 : FontWeight.w500,
                      fontFeatures: AppTypography.tabularFeatures,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (embedded) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePreview,
        borderRadius: BorderRadius.circular(radius.large),
        border: Border.all(color: colors.border),
      ),
      child: content,
    );
  }

  String _formatWeight(double weight) {
    if (weight == weight.toInt()) {
      return weight.toInt().toString();
    }
    return weight.toStringAsFixed(1).replaceAll('.', ',');
  }
}
