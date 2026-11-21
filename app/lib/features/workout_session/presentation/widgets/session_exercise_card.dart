import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/progression/presentation/providers/progression_providers.dart';
import 'package:personal_fitness_os/features/progression/presentation/widgets/progression_recommendation_banner.dart';
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

  @override
  ConsumerState<SessionExerciseCard> createState() => _SessionExerciseCardState();
}

class _SessionExerciseCardState extends ConsumerState<SessionExerciseCard> {
  int _extraSlotsCount = 0;

  int get _totalRowsCount {
    final baseCount = widget.sessionExercise.targetSetsCount > widget.sessionExercise.sets.length
        ? widget.sessionExercise.targetSetsCount
        : widget.sessionExercise.sets.length;
    return baseCount + _extraSlotsCount;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final se = widget.sessionExercise;
    final exerciseName = se.exercise?.name ?? 'Exercício';
    final muscle = se.exercise?.primaryMuscleGroup;

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

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name, Muscle badge, Target rest
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseName,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (muscle != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant,
                              borderRadius: BorderRadius.circular(context.appRadius.small),
                            ),
                            child: Text(
                              muscle.toUpperCase(),
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(Icons.timer_outlined, size: 14, color: colors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          '${se.targetRestSeconds}s descanso',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Progress badge (e.g. 2/3)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: se.completedWorkingSetsCount >= se.targetSetsCount
                      ? fitnessColors.progressUp.withOpacity(0.15)
                      : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(context.appRadius.small),
                ),
                child: Text(
                  '${se.completedWorkingSetsCount}/${se.targetSetsCount} séries',
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: se.completedWorkingSetsCount >= se.targetSetsCount
                        ? fitnessColors.progressUp
                        : colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progression Recommendation Banner
          progressionAsync.when(
            data: (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProgressionRecommendationBanner(recommendation: rec),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Header Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    'SET',
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    'CARGA (KG)',
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    'REPS',
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'RIR',
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 46),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Rows
          ...List.generate(_totalRowsCount, (idx) {
            final setNumber = idx + 1;
            final LoggedSet? logged = idx < se.sets.length ? se.sets[idx] : null;

            return LoggedSetRow(
              key: ValueKey('set_${se.id}_$setNumber'),
              setNumber: setNumber,
              loggedSet: logged,
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

          // Add set button
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _extraSlotsCount++),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Adicionar Série'),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
