import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/liftr_progress_bar.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/progression_recommendation.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/logged_set_row.dart';

class SessionExerciseCard extends ConsumerStatefulWidget {
  const SessionExerciseCard({
    super.key,
    required this.sessionExercise,
    required this.onLogSet,
    this.onDeleteSet,
    this.onAddExtraSet,
    this.isExpanded = true,
    this.onToggleExpand,
    this.onSwapExercise,
    this.exerciseIndex,
    this.totalExercises,
    this.weightIncrement = 2.5,
    this.showRir = true,
  });

  final SessionExercise sessionExercise;
  final Future<void> Function({
    required String sessionExerciseId,
    required int setNumber,
    required SetType setType,
    required double weightKg,
    required int repsCompleted,
    int? rirActual,
    int restSeconds,
  }) onLogSet;
  final Future<void> Function(String setId)? onDeleteSet;
  final VoidCallback? onAddExtraSet;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onSwapExercise;
  final int? exerciseIndex;
  final int? totalExercises;
  final double weightIncrement;
  final bool showRir;

  @override
  ConsumerState<SessionExerciseCard> createState() =>
      _SessionExerciseCardState();
}

class _SessionExerciseCardState extends ConsumerState<SessionExerciseCard> {
  int _extraSlotsCount = 0;

  int get _totalRowsCount {
    final baseCount = widget.sessionExercise.targetSetsCount >
            widget.sessionExercise.sets.length
        ? widget.sessionExercise.targetSetsCount
        : widget.sessionExercise.sets.length;
    return baseCount + _extraSlotsCount;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final radius = context.appRadius;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final se = widget.sessionExercise;
    final exerciseName = se.exercise?.name ?? 'Exercício';
    final muscle = se.exercise?.primaryMuscleGroup;
    final isAllDone = se.completedWorkingSetsCount >= se.targetSetsCount;

    if (!widget.isExpanded) {
      final idxLabel = ((widget.exerciseIndex ?? 0) + 1)
          .toString()
          .padLeft(2, '0');
      return InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onToggleExpand?.call();
        },
        borderRadius: BorderRadius.circular(radius.large),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(radius.large),
            border: Border.all(
              color: isAllDone
                  ? fitnessColors.progressUp.withValues(alpha: 0.35)
                  : colors.border,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  idxLabel,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppTypography.tabularFeatures,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      exerciseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isAllDone
                          ? '${se.completedWorkingSetsCount}/${se.targetSetsCount} concluídas ✓'
                          : '${se.completedWorkingSetsCount}/${se.targetSetsCount} séries',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: isAllDone
                            ? fitnessColors.progressUp
                            : colors.textTertiary,
                        fontFeatures: AppTypography.tabularFeatures,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: 0,
                duration: disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 240),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final progressionAsync = ref.watch(
      exerciseProgressionProvider(
        ExerciseProgressionParams(
          exerciseId: se.exerciseId,
          targetRepsMin: se.targetRepsMin,
          targetRepsMax: se.targetRepsMax,
          targetRir: se.targetRir,
          equipment: se.exercise?.equipment,
        ),
      ),
    );

    final rec = progressionAsync.asData?.value;
    final defaultWeight =
        (rec != null && rec.suggestedWeightKg > 0) ? rec.suggestedWeightKg : 0.0;
    final targetWeightText =
        defaultWeight > 0 ? '${_formatWeight(defaultWeight)} kg · ' : '';

    final totalTargetReps = se.targetSetsCount * se.targetRepsMax;
    final loggedWorkingReps = se.sets
        .where((s) => s.isWorkingSet)
        .fold(0, (sum, s) => sum + s.repsCompleted);
    final repsRemaining = (totalTargetReps - loggedWorkingReps).clamp(0, 999);
    final progressRatio = totalTargetReps > 0
        ? (loggedWorkingReps / totalTargetReps).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radius.xl),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.47),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.06),
            colors.surface,
          ],
          stops: const [0.0, 0.35],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.onToggleExpand,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (widget.exerciseIndex != null &&
                              widget.totalExercises != null)
                            Text(
                              'EXERCÍCIO ${widget.exerciseIndex! + 1} DE ${widget.totalExercises}',
                              style: AppTypography.eyebrow(context),
                            ),
                          if (muscle != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceElevated,
                                borderRadius:
                                    BorderRadius.circular(radius.xs),
                              ),
                              child: Text(
                                muscle.toUpperCase(),
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        exerciseName,
                        style: context.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Alvo: $targetWeightText${se.targetRepsMin}–${se.targetRepsMax} reps · ${se.targetRestSeconds}s',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontFeatures: AppTypography.tabularFeatures,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.onSwapExercise != null)
                    Semantics(
                      label: 'Trocar exercício',
                      button: true,
                      child: InkWell(
                        onTap: widget.onSwapExercise,
                        borderRadius: BorderRadius.circular(radius.medium),
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: colors.primaryMuted,
                            borderRadius:
                                BorderRadius.circular(radius.medium),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.swap_horiz_rounded,
                                size: 17,
                                color: colors.primaryLight,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Trocar',
                                style: context.textTheme.labelMedium?.copyWith(
                                  color: colors.primaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isAllDone
                          ? fitnessColors.progressUp.withValues(alpha: 0.15)
                          : colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(radius.xs),
                    ),
                    child: Text(
                      '${se.completedWorkingSetsCount}/${se.targetSetsCount} séries',
                      style: context.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isAllDone
                            ? fitnessColors.progressUp
                            : colors.textSecondary,
                        fontFeatures: AppTypography.tabularFeatures,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Double progression micro bar
          LiftrProgressBar(
            progress: progressRatio > 0
                ? progressRatio
                : (rec?.type == ProgressionType.increase ? 1.0 : 0.15),
            height: 5,
            color: (repsRemaining == 0 || rec?.type == ProgressionType.increase)
                ? fitnessColors.progressUp
                : colors.primary,
          ),
          const SizedBox(height: 6),
          Text(
            repsRemaining == 0
                ? 'Meta da faixa batida · pronto para subir na próxima!'
                : '$loggedWorkingReps/$totalTargetReps reps · faltam $repsRemaining para o topo da faixa',
            style: context.textTheme.labelSmall?.copyWith(
              color: repsRemaining == 0
                  ? fitnessColors.progressUp
                  : colors.textTertiary,
              fontFeatures: AppTypography.tabularFeatures,
            ),
          ),
          const SizedBox(height: 16),

          // Column Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    'SÉRIE',
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 13,
                  child: Text(
                    'KG',
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 10,
                  child: Text(
                    'REPS',
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.showRir) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 60,
                    child: Text(
                      'RIR',
                      textAlign: TextAlign.center,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                SizedBox(
                  width: 46,
                  child: Text(
                    'FEITO',
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Set Rows
          ...List.generate(_totalRowsCount, (idx) {
            final setNumber = idx + 1;
            final LoggedSet? logged =
                idx < se.sets.length ? se.sets[idx] : null;
            final prevWeight = idx > 0 && idx - 1 < se.sets.length
                ? se.sets[idx - 1].weightKg
                : defaultWeight;

            return LoggedSetRow(
              key: ValueKey('set_${se.id}_$setNumber'),
              setNumber: setNumber,
              loggedSet: logged,
              defaultWeight: prevWeight,
              defaultReps: se.targetRepsMin,
              defaultRir: se.targetRir,
              weightIncrement: widget.weightIncrement,
              showRir: widget.showRir,
              onSave: ({
                required double weightKg,
                required int repsCompleted,
                int? rirActual,
                required SetType setType,
              }) =>
                  widget.onLogSet(
                sessionExerciseId: se.id,
                setNumber: setNumber,
                setType: setType,
                weightKg: weightKg,
                repsCompleted: repsCompleted,
                rirActual: rirActual,
                restSeconds: se.targetRestSeconds,
              ),
              onDelete: logged != null && widget.onDeleteSet != null
                  ? () => widget.onDeleteSet!(logged.id)
                  : null,
            );
          }),

          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: fitnessColors.warmupTag.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(radius.xs),
                ),
                child: Text(
                  'AQ',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: fitnessColors.warmupTag,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Aquecimento não entra na progressão',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _extraSlotsCount++);
                widget.onAddExtraSet?.call();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Adicionar série'),
              style: TextButton.styleFrom(
                foregroundColor: colors.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWeight(double w) {
    if (w == w.toInt()) return w.toInt().toString();
    return w.toStringAsFixed(1).replaceAll('.', ',');
  }
}
