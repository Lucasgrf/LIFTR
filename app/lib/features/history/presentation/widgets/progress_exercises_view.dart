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

enum ExerciseProgressStatus { rising, steady, stalled }

class AggregatedExerciseProgress {
  const AggregatedExerciseProgress({
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
  final ExerciseProgressStatus status;
}

/// Aggregates completed sessions into per-exercise double-progression items.
List<AggregatedExerciseProgress> aggregateExerciseProgress(
  List<WorkoutSession> sessions,
) {
  final byId =
      <String, List<(WorkoutSession, SessionExercise, List<LoggedSet>)>>{};
  for (final session in sessions) {
    for (final se in session.exercises) {
      final sets = se.sets.where((s) => s.isWorkingSet).toList();
      if (sets.isEmpty) continue;
      byId.putIfAbsent(se.exerciseId, () => []).add((session, se, sets));
    }
  }

  final result = <AggregatedExerciseProgress>[];
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

    var status = ExerciseProgressStatus.steady;
    if (ratio >= 0.98) {
      status = ExerciseProgressStatus.rising;
    } else if (entries.length >= 2) {
      final prevSets = entries[1].$3;
      final prevWeight = prevSets.fold<double>(
        0.0,
        (m, s) => s.weightKg > m ? s.weightKg : m,
      );
      final prevReps =
          prevSets.fold<int>(0, (sum, s) => sum + s.repsCompleted);
      if (topWeight > prevWeight || totalReps > prevReps) {
        status = ExerciseProgressStatus.rising;
      } else if (entries.length >= 3 &&
          topWeight <= prevWeight &&
          totalReps <= prevReps) {
        status = ExerciseProgressStatus.stalled;
      }
    }

    result.add(
      AggregatedExerciseProgress(
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

  return List<AggregatedExerciseProgress>.unmodifiable(result);
}

/// Derived provider caching aggregated exercise progression so search typing
/// filters the cached items without re-aggregating sessions and sets.
final aggregatedExerciseProgressProvider =
    Provider.autoDispose<AsyncValue<List<AggregatedExerciseProgress>>>(
  (ref) => ref.watch(historyListProvider).whenData(aggregateExerciseProgress),
);

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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final aggregatedAsync = ref.watch(aggregatedExerciseProgressProvider);

    return aggregatedAsync.when(
      skipLoadingOnRefresh: true,
      skipError: true,
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
      data: (items) {
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
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          tooltip: 'Limpar busca',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (filtered.isEmpty)
              EmptyStateWidget(
                icon: Icons.search_off_rounded,
                title: 'Nenhum exercício encontrado',
                subtitle: 'Nenhum exercício corresponde a "$_query".',
                actionLabel: 'Limpar busca',
                onAction: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              )
            else ...[
            Text(
              'Dupla progressão',
              style: context.textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final (badgeText, badgeTone, badgeIcon) =
                    switch (item.status) {
                  ExerciseProgressStatus.rising => (
                      'Subindo',
                      LiftrBadgeTone.success,
                      Icons.north_east_rounded,
                    ),
                  ExerciseProgressStatus.steady => (
                      'Estável',
                      LiftrBadgeTone.neutral,
                      Icons.trending_flat_rounded,
                    ),
                  ExerciseProgressStatus.stalled => (
                      'Travado',
                      LiftrBadgeTone.warning,
                      Icons.priority_high_rounded,
                    ),
                };
                final weightText =
                    item.latestWeightKg == item.latestWeightKg.toInt()
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
                                        ExerciseProgressStatus.rising
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
              },
            ),
            ],
          ],
        );
      },
    );
  }
}
