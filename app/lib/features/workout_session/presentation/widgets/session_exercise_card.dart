import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_motion.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
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
    int? durationSeconds,
    int? rirActual,
    int restSeconds,
    List<DropSetEntry> dropSets,
    String? existingSetId,
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
  int _minRowCount = 0;
  final Map<int, SetType> _extraRowTypes = {};

  int get _totalRowsCount {
    final se = widget.sessionExercise;
    final maxLoggedSetNumber = se.sets.fold<int>(
      0,
      (m, s) => s.setNumber > m ? s.setNumber : m,
    );
    return [
      se.targetSetsCount,
      se.prescribedSetTypes.length,
      se.sets.length,
      maxLoggedSetNumber,
      _minRowCount,
    ].reduce(math.max);
  }

  LoggedSet? _findLoggedSetForNumber(int setNumber) {
    for (final s in widget.sessionExercise.sets) {
      if (s.setNumber == setNumber) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final radius = context.appRadius;
    final motion = context.appMotion;
    final se = widget.sessionExercise;
    final isCardio = se.isCardio;
    final exerciseName = se.exercise?.name ?? 'Exercício';
    final muscle = se.exercise?.primaryMuscleGroup;
    final isAllDone = isCardio
        ? se.totalCardioDurationSeconds >= math.max(1, se.targetRepsMin) * 60
        : se.completedWorkingSetsCount >= se.targetSetsCount;

    if (!widget.isExpanded) {
      final idxLabel = ((widget.exerciseIndex ?? 0) + 1)
          .toString()
          .padLeft(2, '0');
      final collapsedSubtitle = isCardio
          ? (se.totalCardioDurationSeconds > 0
              ? '${formatCardioSeconds(se.totalCardioDurationSeconds)} concluído ✓'
              : 'Meta ${se.targetRepsMin == se.targetRepsMax ? '${se.targetRepsMin}' : '${se.targetRepsMin}–${se.targetRepsMax}'} min')
          : (isAllDone
              ? '${se.completedWorkingSetsCount}/${se.targetSetsCount} concluídas ✓'
              : '${se.completedWorkingSetsCount}/${se.targetSetsCount} séries');

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
                      collapsedSubtitle,
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
                duration: motion.resolve(context, motion.standard),
                curve: motion.curveStandard,
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

    final ProgressionRecommendation? rec = isCardio
        ? null
        : ref
            .watch(
              exerciseProgressionProvider(
                ExerciseProgressionParams(
                  exerciseId: se.exerciseId,
                  targetRepsMin: se.targetRepsMin,
                  targetRepsMax: se.targetRepsMax,
                  targetRir: se.targetRir,
                  equipment: se.exercise?.equipment,
                ),
              ),
            )
            .asData
            ?.value;

    final defaultWeight =
        (rec != null && rec.suggestedWeightKg > 0) ? rec.suggestedWeightKg : 0.0;
    final targetWeightText =
        defaultWeight > 0 ? '${_formatWeight(defaultWeight)} kg · ' : '';

    final totalTargetReps = se.targetSetsCount * se.targetRepsMax;
    final loggedWorkingReps = se.sets
        .where((s) => s.isWorkingSet)
        .fold(0, (sum, s) => sum + s.repsCompleted);
    final repsRemaining = (totalTargetReps - loggedWorkingReps).clamp(0, 999);
    final cardioLoggedMin = (se.totalCardioDurationSeconds / 60).round();
    final cardioTargetMin = math.max(1, se.targetRepsMin);
    final cardioRangeLabel = se.targetRepsMin == se.targetRepsMax
        ? '${se.targetRepsMin} min'
        : '${se.targetRepsMin}–${se.targetRepsMax} min';
    final progressRatio = isCardio
        ? (cardioLoggedMin / cardioTargetMin).clamp(0.0, 1.0)
        : (totalTargetReps > 0
            ? (loggedWorkingReps / totalTargetReps).clamp(0.0, 1.0)
            : 0.0);

    final badgeLabel = isCardio
        ? (se.totalCardioDurationSeconds > 0
            ? formatCardioSeconds(se.totalCardioDurationSeconds)
            : 'Cardio')
        : '${se.completedWorkingSetsCount}/${se.targetSetsCount} séries';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radius.xl),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.45),
          width: 1,
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
                            LiftrBadge(
                              label: muscle.toUpperCase(),
                              tone: LiftrBadgeTone.neutral,
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
                        isCardio
                            ? 'Meta: $cardioRangeLabel · registro por tempo'
                            : 'Alvo: $targetWeightText${se.targetRepsMin}–${se.targetRepsMax} reps · ${se.targetRestSeconds}s',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontFeatures: AppTypography.tabularFeatures,
                        ),
                      ),
                      if (!isCardio &&
                          rec?.previousSummary != null &&
                          rec!.previousSummary!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Última: ${rec.previousSummary}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.textTertiary,
                            fontFeatures: AppTypography.tabularFeatures,
                          ),
                        ),
                      ],
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
                      container: true,
                      label: 'Trocar exercício',
                      button: true,
                      child: InkWell(
                        onTap: widget.onSwapExercise,
                        borderRadius: BorderRadius.circular(radius.medium),
                        child: ExcludeSemantics(
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
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
                    ),
                  const SizedBox(height: 6),
                  LiftrBadge(
                    label: badgeLabel,
                    tone: isAllDone
                        ? LiftrBadgeTone.success
                        : LiftrBadgeTone.neutral,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Double progression or Cardio target bar
          LiftrProgressBar(
            progress: isCardio
                ? progressRatio
                : (progressRatio > 0
                    ? progressRatio
                    : (rec?.type == ProgressionType.increase ? 1.0 : 0.15)),
            height: 5,
            color: (isCardio
                    ? isAllDone
                    : (repsRemaining == 0 ||
                        rec?.type == ProgressionType.increase))
                ? fitnessColors.progressUp
                : colors.primary,
          ),
          const SizedBox(height: 6),
          Text(
            isCardio
                ? (cardioLoggedMin >= cardioTargetMin
                    ? 'Meta de cardio concluída ($cardioLoggedMin min)!'
                    : '$cardioLoggedMin/$cardioTargetMin min registrados')
                : (repsRemaining == 0
                    ? 'Meta da faixa batida · pronto para subir na próxima!'
                    : '$loggedWorkingReps/$totalTargetReps reps · faltam $repsRemaining para o topo da faixa'),
            style: context.textTheme.labelSmall?.copyWith(
              color: (isCardio ? isAllDone : repsRemaining == 0)
                  ? fitnessColors.progressUp
                  : colors.textTertiary,
              fontFeatures: AppTypography.tabularFeatures,
            ),
          ),
          const SizedBox(height: 16),

          // Column Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: isCardio
                ? Row(
                    children: [
                      SizedBox(
                        width: 34,
                        child: Text(
                          'BLOCO',
                          textAlign: TextAlign.center,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'TEMPO (MIN)',
                          textAlign: TextAlign.center,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 48,
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
                  )
                : Row(
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
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 12,
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
                      const SizedBox(width: 4),
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
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 58,
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
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 44,
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
            final LoggedSet? logged = _findLoggedSetForNumber(setNumber);
            final prevLogged = _findLoggedSetForNumber(setNumber - 1);
            final prevWeight = idx > 0 && prevLogged != null
                ? prevLogged.weightKg
                : defaultWeight;

            final initialType = _extraRowTypes[setNumber] ??
                (idx < se.prescribedSetTypes.length
                    ? se.prescribedSetTypes[idx]
                    : SetType.working);

            return LoggedSetRow(
              key: ValueKey('set_${se.id}_$setNumber'),
              setNumber: setNumber,
              initialType: initialType,
              loggedSet: logged,
              defaultWeight: prevWeight,
              defaultReps: se.targetRepsMin,
              defaultDurationMinutes:
                  se.targetRepsMin > 0 ? se.targetRepsMin : 15,
              defaultRir: se.targetRir,
              weightIncrement: widget.weightIncrement,
              showRir: widget.showRir,
              isCardio: isCardio,
              onSave: ({
                required double weightKg,
                required int repsCompleted,
                int? durationSeconds,
                int? rirActual,
                required SetType setType,
                List<DropSetEntry> dropSets = const [],
                String? existingSetId,
              }) =>
                  widget.onLogSet(
                sessionExerciseId: se.id,
                setNumber: setNumber,
                setType: setType,
                weightKg: weightKg,
                repsCompleted: repsCompleted,
                durationSeconds: durationSeconds,
                rirActual: rirActual,
                restSeconds: isCardio ? 0 : se.targetRestSeconds,
                dropSets: dropSets,
                existingSetId: existingSetId,
              ),
              onDelete: logged != null && widget.onDeleteSet != null
                  ? () => widget.onDeleteSet!(logged.id)
                  : null,
            );
          }),

          const SizedBox(height: 6),
          if (!isCardio) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const LiftrBadge(
                  label: 'AQ',
                  tone: LiftrBadgeTone.warning,
                ),
                const LiftrBadge(
                  label: 'DROP',
                  tone: LiftrBadgeTone.dropSet,
                ),
                Text(
                  'Toque no nº da série para alternar tipo',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _minRowCount = _totalRowsCount + 1;
                        });
                        widget.onAddExtraSet?.call();
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Adicionar série'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: colors.primaryLight,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          final nextRow = _totalRowsCount + 1;
                          _minRowCount = nextRow;
                          _extraRowTypes[nextRow] = SetType.dropSet;
                        });
                        widget.onAddExtraSet?.call();
                      },
                      icon: const Icon(Icons.bolt_rounded, size: 17),
                      label: const Text('Drop-set'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: fitnessColors.dropSetTag,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _minRowCount = _totalRowsCount + 1;
                  });
                  widget.onAddExtraSet?.call();
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Adicionar bloco de cardio'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: colors.primaryLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatWeight(double w) {
    if (w == w.toInt()) return w.toInt().toString();
    return w.toStringAsFixed(1).replaceAll('.', ',');
  }
}
