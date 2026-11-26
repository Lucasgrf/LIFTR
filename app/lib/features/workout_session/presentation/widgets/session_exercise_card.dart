import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/core/widgets/liftr_progress_bar.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/progression_recommendation.dart';
import 'package:personal_fitness_os/features/progression/domain/services/progression_engine.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/services/initial_weight_estimator.dart';
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
  final Map<int, ({double weightKg, int reps})> _prefilledBySetNumber = {};
  final Map<int, ({double weightKg, int reps})> _draftBySetNumber = {};
  int _syncToken = 0;
  bool _isBulkCompleting = false;

  @override
  void didUpdateWidget(covariant SessionExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionExercise.id != widget.sessionExercise.id) {
      _prefilledBySetNumber.clear();
      _draftBySetNumber.clear();
      _extraRowTypes.clear();
      _minRowCount = 0;
      _syncToken++;
      _isBulkCompleting = false;
    }
  }

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

  ({double weightKg, int reps}) _resolveDefaultsForSet({
    required int setNumber,
    required double defaultWeight,
  }) {
    final prefilled = _prefilledBySetNumber[setNumber];
    if (prefilled != null) {
      return prefilled;
    }

    LoggedSet? latestPrev;
    for (final s in widget.sessionExercise.sets) {
      if (s.setNumber < setNumber &&
          (latestPrev == null || s.setNumber > latestPrev.setNumber)) {
        latestPrev = s;
      }
    }

    final prevWeight = latestPrev != null ? latestPrev.weightKg : defaultWeight;
    final prevReps = latestPrev != null && latestPrev.repsCompleted > 0
        ? latestPrev.repsCompleted
        : widget.sessionExercise.targetRepsMin;
    return (weightKg: prevWeight, reps: prevReps);
  }

  void _applyToRemainingSets(int fromSetNumber, double weightKg, int reps) {
    final total = _totalRowsCount;
    var updatedCount = 0;
    setState(() {
      if (_findLoggedSetForNumber(fromSetNumber) == null) {
        _prefilledBySetNumber[fromSetNumber] = (weightKg: weightKg, reps: reps);
        _draftBySetNumber[fromSetNumber] = (weightKg: weightKg, reps: reps);
      }
      for (var n = fromSetNumber + 1; n <= total; n++) {
        if (_findLoggedSetForNumber(n) == null) {
          _prefilledBySetNumber[n] = (weightKg: weightKg, reps: reps);
          _draftBySetNumber.remove(n);
          updatedCount++;
        }
      }
      _syncToken++;
    });
    if (updatedCount > 0 && mounted) {
      context.showSnackBar(
        'Aplicado ${_formatWeight(weightKg)} kg × $reps reps às $updatedCount séries restantes.',
      );
    }
  }

  void _repeatLastSession(ProgressionRecommendation rec) {
    final se = widget.sessionExercise;
    final prevWorking = rec.previousWorkingSets;
    final total = _totalRowsCount;
    var updatedCount = 0;
    setState(() {
      for (var n = 1; n <= total; n++) {
        if (_findLoggedSetForNumber(n) != null) continue;
        final sourceSet = prevWorking.isNotEmpty
            ? prevWorking[(n - 1).clamp(0, prevWorking.length - 1)]
            : null;
        final targetWeight = rec.isIncrease && rec.suggestedWeightKg > 0
            ? rec.suggestedWeightKg
            : (sourceSet != null && sourceSet.weightKg > 0
                ? sourceSet.weightKg
                : rec.suggestedWeightKg);
        final targetReps = rec.isIncrease
            ? se.targetRepsMin
            : (sourceSet != null && sourceSet.repsCompleted > 0
                ? sourceSet.repsCompleted
                : se.targetRepsMin);
        if (targetReps > 0) {
          _prefilledBySetNumber[n] = (weightKg: targetWeight, reps: targetReps);
          _draftBySetNumber.remove(n);
          updatedCount++;
        }
      }
      _syncToken++;
    });
    if (updatedCount > 0 && mounted) {
      HapticFeedback.lightImpact();
      context.showSnackBar(
        rec.isIncrease
            ? 'Nova meta (${_formatWeight(rec.suggestedWeightKg)} kg) aplicada nas séries pendentes.'
            : 'Última sessão aplicada nas $updatedCount séries pendentes.',
      );
    }
  }

  Future<void> _completeAllRemainingSets({
    required double defaultWeight,
  }) async {
    if (_isBulkCompleting) return;
    final se = widget.sessionExercise;
    final total = _totalRowsCount;
    final pendingNumbers = <int>[
      for (var n = 1; n <= total; n++)
        if (_findLoggedSetForNumber(n) == null) n,
    ];
    if (pendingNumbers.isEmpty) return;

    setState(() => _isBulkCompleting = true);
    HapticFeedback.mediumImpact();
    try {
      for (final n in pendingNumbers) {
        final idx = n - 1;
        final setType = _extraRowTypes[n] ??
            (idx < se.prescribedSetTypes.length
                ? se.prescribedSetTypes[idx]
                : SetType.working);
        final resolved = _draftBySetNumber[n] ??
            _resolveDefaultsForSet(
              setNumber: n,
              defaultWeight: defaultWeight,
            );
        final repsToLog =
            resolved.reps > 0 ? resolved.reps : math.max(1, se.targetRepsMin);
        await widget.onLogSet(
          sessionExerciseId: se.id,
          setNumber: n,
          setType: setType,
          weightKg: resolved.weightKg,
          repsCompleted: repsToLog,
          rirActual: widget.showRir ? se.targetRir : null,
          restSeconds: se.targetRestSeconds,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBulkCompleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final radius = context.appRadius;
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
              ? '${formatCardioSeconds(se.totalCardioDurationSeconds)} concluído'
              : 'Meta ${se.targetRepsMin == se.targetRepsMax ? '${se.targetRepsMin}' : '${se.targetRepsMin}–${se.targetRepsMax}'} min')
          : (isAllDone
              ? '${se.completedWorkingSetsCount}/${se.targetSetsCount} concluídas'
              : '${se.completedWorkingSetsCount}/${se.targetSetsCount} séries');

      return Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.large),
          side: BorderSide(
            color: isAllDone
                ? fitnessColors.progressUp.withValues(alpha: 0.35)
                : colors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onToggleExpand?.call();
          },
          borderRadius: BorderRadius.circular(radius.large),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.appSpacing.space16,
                vertical: context.appSpacing.space12,
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
                    SizedBox(height: context.appSpacing.space4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAllDone) ...[
                          Icon(
                            Icons.check_circle_rounded,
                            size: 13,
                            color: fitnessColors.progressUp,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            collapsedSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: isAllDone
                                  ? fitnessColors.progressUp
                                  : colors.textTertiary,
                              fontFeatures: AppTypography.tabularFeatures,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
      ),
    );
    }

    final settings = ref.watch(userSettingsProvider);
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

    final hasHistoryWeight = rec != null && rec.suggestedWeightKg > 0;
    final estimatedInitial = (!isCardio && !hasHistoryWeight)
        ? InitialWeightEstimator.estimate(
            exercise: se.exercise,
            experience: settings.experience,
            bodyWeightKg: settings.weightKg,
            biologicalSex: settings.biologicalSex,
            targetRepsMin: se.targetRepsMin,
            targetRepsMax: se.targetRepsMax,
            equipmentIncrement: widget.weightIncrement,
          )
        : null;

    final double defaultWeight = hasHistoryWeight
        ? rec.suggestedWeightKg
        : (estimatedInitial?.weightKg ?? 0.0);
    final bool isUsingInitialEstimate =
        !isCardio && !hasHistoryWeight && (estimatedInitial?.isEstimated ?? false) && defaultWeight > 0;
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
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
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: widget.onToggleExpand,
                    borderRadius: BorderRadius.circular(radius.small),
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
                      ] else if (isUsingInitialEstimate) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Carga inicial sugerida (${settings.experience.label}) · ajuste se necessário',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.primaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
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
                      child: Material(
                        color: colors.primaryMuted,
                        borderRadius: BorderRadius.circular(radius.medium),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: widget.onSwapExercise,
                          borderRadius: BorderRadius.circular(radius.medium),
                          child: ExcludeSemantics(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.appSpacing.space12,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.swap_horiz_rounded,
                                      size: 17,
                                      color: colors.primaryLight,
                                    ),
                                    AppSpacing.horizontalGap4,
                                    Text(
                                      'Trocar',
                                      style: context.textTheme.labelMedium
                                          ?.copyWith(
                                        color: colors.primaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                  if (!isCardio && rec != null && rec.isIncrease) ...[
                    const SizedBox(height: 6),
                    LiftrBadge(
                      label: 'SUBIR +${_formatWeight(rec.weightDeltaKg)} kg',
                      tone: LiftrBadgeTone.success,
                      icon: Icons.north_east_rounded,
                    ),
                  ],
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
                    ? ((rec?.consecutiveCeilingHits ?? 0) >= 1
                        ? 'Topo consolidado (2/2) · subida de carga liberada!'
                        : 'Topo da faixa batido (1/2) · repita na próxima sessão para subir carga')
                    : (!isCardio &&
                            rec != null &&
                            rec.consecutiveCeilingHits == 1 &&
                            !rec.isIncrease)
                        ? 'Teto 1/2 · repita hoje para liberar +${_formatWeight(ProgressionEngine.defaultWeightIncrement(se.exercise?.equipment))} kg'
                        : '$loggedWorkingReps/$totalTargetReps reps · faltam $repsRemaining para o topo da faixa'),
            style: context.textTheme.labelSmall?.copyWith(
              color: (isCardio
                      ? isAllDone
                      : (repsRemaining == 0 &&
                          (rec?.consecutiveCeilingHits ?? 0) >= 1))
                  ? fitnessColors.progressUp
                  : (!isCardio &&
                          ((rec?.consecutiveCeilingHits ?? 0) == 1 ||
                              repsRemaining == 0))
                      ? colors.primaryLight
                      : colors.textTertiary,
              fontFeatures: AppTypography.tabularFeatures,
            ),
          ),
          if (!isCardio &&
              [
                for (var n = 1; n <= _totalRowsCount; n++)
                  if (_findLoggedSetForNumber(n) == null) n,
              ].isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (rec != null && rec.previousWorkingSets.isNotEmpty)
                  Semantics(
                    label: 'Repetir carga e repetições da última sessão',
                    button: true,
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () => _repeatLastSession(rec),
                        borderRadius: BorderRadius.circular(radius.medium),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          child: Center(
                            widthFactor: 1,
                            child: Ink(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.appSpacing.space12,
                                vertical: context.appSpacing.space8,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceElevated,
                                borderRadius:
                                    BorderRadius.circular(radius.medium),
                                border: Border.all(color: colors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.replay_rounded,
                                    size: 15,
                                    color: colors.primaryLight,
                                  ),
                                  AppSpacing.horizontalGap4,
                                  Flexible(
                                    child: Text(
                                      'Repetir última',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (defaultWeight > 0 || se.sets.isNotEmpty)
                  Semantics(
                    label: 'Concluir séries restantes deste exercício',
                    button: true,
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: _isBulkCompleting
                            ? null
                            : () => _completeAllRemainingSets(
                                  defaultWeight: defaultWeight,
                                ),
                        borderRadius: BorderRadius.circular(radius.medium),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          child: Center(
                            widthFactor: 1,
                            child: Ink(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.appSpacing.space12,
                                vertical: context.appSpacing.space8,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primaryMuted,
                                borderRadius:
                                    BorderRadius.circular(radius.medium),
                                border: Border.all(
                                  color: colors.primary.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isBulkCompleting)
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.primaryLight,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.done_all_rounded,
                                      size: 15,
                                      color: colors.primaryLight,
                                    ),
                                  AppSpacing.horizontalGap4,
                                  Flexible(
                                    child: Text(
                                      'Concluir restantes',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                        color: colors.primaryLight,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),

          // Column Labels
          LayoutBuilder(
            builder: (context, constraints) {
              if (!isCardio &&
                  constraints.maxWidth < (widget.showRir ? 520.0 : 448.0)) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: EdgeInsets.only(
                  left: context.appSpacing.space4,
                  right: context.appSpacing.space4,
                  bottom: context.appSpacing.space8,
                ),
                child: isCardio
                    ? Row(
                        children: [
                          SizedBox(
                            width: 34,
                            child: Text(
                              'BL.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          AppSpacing.horizontalGap8,
                          Expanded(
                            child: Text(
                              'TEMPO (MIN)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          AppSpacing.horizontalGap8,
                          SizedBox(
                            width: 48,
                            child: Text(
                              'FEITO',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text(
                              'SÉR.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          AppSpacing.horizontalGap8,
                          Expanded(
                            flex: 12,
                            child: Text(
                              'KG',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          AppSpacing.horizontalGap8,
                          Expanded(
                            flex: 10,
                            child: Text(
                              'REPS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (widget.showRir) ...[
                            AppSpacing.horizontalGap8,
                            SizedBox(
                              width: 58,
                              child: Text(
                                'RIR',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: colors.textTertiary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          AppSpacing.horizontalGap8,
                          SizedBox(
                            width: 48,
                            child: Text(
                              'FEITO',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
              );
            },
          ),

          // Set Rows
          ...List.generate(_totalRowsCount, (idx) {
            final setNumber = idx + 1;
            final LoggedSet? logged = _findLoggedSetForNumber(setNumber);

            final resolvedDefaults = _resolveDefaultsForSet(
              setNumber: setNumber,
              defaultWeight: defaultWeight,
            );
            final hasRemainingUnlogged = [
              for (var n = setNumber + 1; n <= _totalRowsCount; n++)
                if (_findLoggedSetForNumber(n) == null) n,
            ].isNotEmpty;

            final initialType = _extraRowTypes[setNumber] ??
                (idx < se.prescribedSetTypes.length
                    ? se.prescribedSetTypes[idx]
                    : SetType.working);

            return LoggedSetRow(
              key: ValueKey('set_${se.id}_$setNumber'),
              setNumber: setNumber,
              initialType: initialType,
              loggedSet: logged,
              defaultWeight: resolvedDefaults.weightKg,
              defaultReps: resolvedDefaults.reps,
              defaultDurationMinutes:
                  se.targetRepsMin > 0 ? se.targetRepsMin : 15,
              defaultRir: se.targetRir,
              weightIncrement: widget.weightIncrement,
              showRir: widget.showRir,
              isCardio: isCardio,
              syncToken: _syncToken,
              onApplyToRemaining: (!isCardio && hasRemainingUnlogged)
                  ? (w, r) => _applyToRemainingSets(setNumber, w, r)
                  : null,
              onDraftChanged: isCardio
                  ? null
                  : (w, r) {
                      _draftBySetNumber[setNumber] = (weightKg: w, reps: r);
                    },
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
            AppSpacing.verticalGap8,
            Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _minRowCount = _totalRowsCount + 1;
                        });
                        widget.onAddExtraSet?.call();
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Adicionar série',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: colors.primaryLight,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
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
                      label: const Text(
                        'Drop-set',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
