import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/core/widgets/liftr_progress_bar.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/exercise_history_modal.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

enum _ExerciseProgressStatus { rising, steady, stalled }

class _AggregatedExerciseProgress {
  _AggregatedExerciseProgress({
    required this.id,
    required this.name,
    required this.latestWeightKg,
    required this.setsCount,
    required this.repsMin,
    required this.repsMax,
    required this.completionRatio,
    required this.status,
  });

  final String id;
  final String name;
  final double latestWeightKg;
  final int setsCount;
  final int repsMin;
  final int repsMax;
  final double completionRatio;
  final _ExerciseProgressStatus status;
}

class ProgressExercisesView extends ConsumerStatefulWidget {
  const ProgressExercisesView({super.key});

  @override
  ConsumerState<ProgressExercisesView> createState() =>
      _ProgressExercisesViewState();
}

class _ProgressExercisesViewState extends ConsumerState<ProgressExercisesView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_AggregatedExerciseProgress> _aggregate(List<WorkoutSession> sessions) {
    final byId =
        <String, List<(WorkoutSession, SessionExercise, List<LoggedSet>)>>{};
    for (final session in sessions) {
      for (final se in session.exercises) {
        final sets = se.sets.where((s) => s.isWorkingSet).toList();
        if (sets.isEmpty) continue;
        byId.putIfAbsent(se.exerciseId, () => []).add((session, se, sets));
      }
    }

    final result = <_AggregatedExerciseProgress>[];
    byId.forEach((exerciseId, entries) {
      final latest = entries.first;
      final latestSe = latest.$2;
      final latestSets = latest.$3;
      final name = latestSe.exercise?.name ?? 'Exercício';
      final topWeight = latestSets.fold<double>(
        0.0,
        (m, s) => s.weightKg > m ? s.weightKg : m,
      );
      final targetTotal =
          (latestSe.targetSetsCount * latestSe.targetRepsMax).clamp(1, 999);
      final totalReps =
          latestSets.fold<int>(0, (sum, s) => sum + s.repsCompleted);
      final ratio = (totalReps / targetTotal).clamp(0.0, 1.0);

      var status = _ExerciseProgressStatus.steady;
      if (ratio >= 0.98) {
        status = _ExerciseProgressStatus.rising;
      } else if (entries.length >= 2) {
        final prevSets = entries[1].$3;
        final prevWeight = prevSets.fold<double>(
          0.0,
          (m, s) => s.weightKg > m ? s.weightKg : m,
        );
        final prevReps =
            prevSets.fold<int>(0, (sum, s) => sum + s.repsCompleted);
        if (topWeight > prevWeight || totalReps > prevReps) {
          status = _ExerciseProgressStatus.rising;
        } else if (entries.length >= 3 &&
            topWeight <= prevWeight &&
            totalReps <= prevReps) {
          status = _ExerciseProgressStatus.stalled;
        }
      }

      result.add(
        _AggregatedExerciseProgress(
          id: exerciseId,
          name: name,
          latestWeightKg: topWeight,
          setsCount: latestSe.targetSetsCount,
          repsMin: latestSe.targetRepsMin,
          repsMax: latestSe.targetRepsMax,
          completionRatio: ratio,
          status: status,
        ),
      );
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final historyAsync = ref.watch(historyListProvider);

    return historyAsync.when(
      loading: () => const LiftrScreenSkeleton(showHero: false),
      error: (err, st) => ErrorStateWidget(
        message: userFacingMessage(
          err,
          stackTrace: st,
          context: 'ProgressExercisesView.build',
        ),
        safetyNote: offlineSafetyNoteFor(err),
        onRetry: () => ref.invalidate(historyListProvider),
      ),
      data: (sessions) {
        final items = _aggregate(sessions);
        if (items.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.show_chart_rounded,
            title: 'Sem dados de progressão ainda',
            subtitle:
                'Complete seu primeiro treino para destravar seus gráficos de progressão.',
            actionLabel: 'Ir para Hoje',
            onAction: () => context.go('/'),
          );
        }

        final filtered = _query.isEmpty
            ? items
            : items
                .where(
                  (e) => e.name.toLowerCase().contains(_query.toLowerCase()),
                )
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (items.length > 5) ...[
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Filtrar exercício...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text('DUPLA PROGRESSÃO', style: AppTypography.eyebrow(context)),
            const SizedBox(height: 10),
            ...filtered.map((item) {
              final (badgeText, badgeTone, badgeIcon) = switch (item.status) {
                _ExerciseProgressStatus.rising => (
                    'Subindo',
                    LiftrBadgeTone.success,
                    Icons.north_east_rounded,
                  ),
                _ExerciseProgressStatus.steady => (
                    'Estável',
                    LiftrBadgeTone.neutral,
                    Icons.trending_flat_rounded,
                  ),
                _ExerciseProgressStatus.stalled => (
                    'Travado',
                    LiftrBadgeTone.warning,
                    Icons.priority_high_rounded,
                  ),
              };
              final weightText = item.latestWeightKg == item.latestWeightKg.toInt()
                  ? '${item.latestWeightKg.toInt()} kg'
                  : '${item.latestWeightKg.toStringAsFixed(1).replaceAll('.', ',')} kg';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => ExerciseHistoryModal.show(
                    context,
                    exerciseId: item.id,
                    exerciseName: item.name,
                  ),
                  padding: const EdgeInsets.all(15),
                  child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.textTheme.titleSmall,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  LiftrBadge(
                                    label: badgeText,
                                    tone: badgeTone,
                                    icon: badgeIcon,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$weightText · ${item.setsCount}×${item.repsMin}–${item.repsMax}',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                  fontFeatures: AppTypography.tabularFeatures,
                                ),
                              ),
                              const SizedBox(height: 10),
                              LiftrProgressBar(
                                progress: item.completionRatio,
                                height: 5,
                                color: item.status ==
                                        _ExerciseProgressStatus.rising
                                    ? fitnessColors.progressUp
                                    : colors.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.textTertiary,
                        ),
                      ],
                    ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
