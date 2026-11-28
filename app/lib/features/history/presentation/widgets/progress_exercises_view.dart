import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
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
    this.stalledSessions = 0,
  });

  final String id;
  final String name;
  final double latestWeightKg;
  final int setsCount;
  final int repsMin;
  final int repsMax;
  final double completionRatio;
  final ExerciseProgressStatus status;
  final int stalledSessions;
}

List<AggregatedExerciseProgress> aggregateExerciseProgress(
  List<WorkoutSession> sessions,
) {
  final byId =
      <String, List<(WorkoutSession, SessionExercise, List<LoggedSet>)>>{};
  for (final session in sessions) {
    for (final exercise in session.exercises) {
      final sets = exercise.sets.where((set) => set.isWorkingSet).toList();
      if (sets.isEmpty) continue;
      byId.putIfAbsent(exercise.exerciseId, () => []).add((
        session,
        exercise,
        sets,
      ));
    }
  }

  final result = <AggregatedExerciseProgress>[];
  byId.forEach((exerciseId, entries) {
    entries.sort(
      (first, second) => (second.$1.completedAt ?? second.$1.startedAt)
          .compareTo(first.$1.completedAt ?? first.$1.startedAt),
    );
    final latest = entries.first;
    final exercise = latest.$2;
    final latestSets = latest.$3;
    final topWeight = latestSets.fold<double>(
      0,
      (maximum, set) => set.weightKg > maximum ? set.weightKg : maximum,
    );
    final targetReps = (exercise.targetSetsCount * exercise.targetRepsMax)
        .clamp(1, 999);
    final totalReps = latestSets.fold<int>(
      0,
      (sum, set) => sum + set.repsCompleted,
    );
    final ratio = (totalReps / targetReps).clamp(0.0, 1.0);

    var stalledSessions = 1;
    for (var index = 1; index < entries.length; index++) {
      final previousSets = entries[index].$3;
      final previousWeight = previousSets.fold<double>(
        0,
        (maximum, set) => set.weightKg > maximum ? set.weightKg : maximum,
      );
      final previousReps = previousSets.fold<int>(
        0,
        (sum, set) => sum + set.repsCompleted,
      );
      if (topWeight <= previousWeight && totalReps <= previousReps) {
        stalledSessions++;
      } else {
        break;
      }
    }

    var status = ExerciseProgressStatus.steady;
    if (ratio >= .98) {
      status = ExerciseProgressStatus.rising;
    } else if (entries.length >= 2) {
      final previousSets = entries[1].$3;
      final previousWeight = previousSets.fold<double>(
        0,
        (maximum, set) => set.weightKg > maximum ? set.weightKg : maximum,
      );
      final previousReps = previousSets.fold<int>(
        0,
        (sum, set) => sum + set.repsCompleted,
      );
      if (topWeight > previousWeight || totalReps > previousReps) {
        status = ExerciseProgressStatus.rising;
      } else if (stalledSessions >= 4) {
        status = ExerciseProgressStatus.stalled;
      }
    }

    result.add(
      AggregatedExerciseProgress(
        id: exerciseId,
        name: exercise.exercise?.name ?? 'Exercício',
        latestWeightKg: topWeight,
        setsCount: exercise.targetSetsCount,
        repsMin: exercise.targetRepsMin,
        repsMax: exercise.targetRepsMax,
        completionRatio: ratio,
        status: status,
        stalledSessions: stalledSessions,
      ),
    );
  });
  return List<AggregatedExerciseProgress>.unmodifiable(result);
}

final aggregatedExerciseProgressProvider =
    Provider.autoDispose<AsyncValue<List<AggregatedExerciseProgress>>>(
      (ref) =>
          ref.watch(historyListProvider).whenData(aggregateExerciseProgress),
    );

class ProgressExercisesView extends ConsumerStatefulWidget {
  const ProgressExercisesView({super.key});

  @override
  ConsumerState<ProgressExercisesView> createState() =>
      _ProgressExercisesViewState();
}

class _ProgressExercisesViewState extends ConsumerState<ProgressExercisesView> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final itemsAsync = ref.watch(aggregatedExerciseProgressProvider);

    return itemsAsync.when(
      skipLoadingOnRefresh: itemsAsync.hasValue,
      skipError: itemsAsync.hasValue,
      loading: () => const LiftrScreenSkeleton(showHero: false),
      error: (error, stack) => ErrorStateWidget(
        message: userFacingMessage(
          error,
          stackTrace: stack,
          context: 'ProgressExercisesView.build',
        ),
        safetyNote: offlineSafetyNoteFor(error),
        onRetry: () => ref.invalidate(historyListProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.show_chart_rounded,
            title: 'Sem dados de progressão ainda',
            subtitle:
                'Complete seu primeiro treino para ver as cargas e repetições aqui.',
            actionLabel: 'Ir para Hoje',
            onAction: () => context.go('/'),
          );
        }

        final rising = items
            .where((item) => item.status == ExerciseProgressStatus.rising)
            .length;
        final stalled = items
            .where((item) => item.status == ExerciseProgressStatus.stalled)
            .length;
        final filtered = switch (_filter) {
          1 =>
            items
                .where((item) => item.status == ExerciseProgressStatus.rising)
                .toList(),
          2 =>
            items
                .where((item) => item.status == ExerciseProgressStatus.stalled)
                .toList(),
          _ => items,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cada rampa são as repetições subindo. Cada degrau é a carga subindo.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ProgressFilterChip(
                  label: 'Todos',
                  selected: _filter == 0,
                  onTap: () => setState(() => _filter = 0),
                ),
                _ProgressFilterChip(
                  label: 'Subindo, $rising',
                  selected: _filter == 1,
                  onTap: () => setState(() => _filter = 1),
                ),
                _ProgressFilterChip(
                  label: 'Travado, $stalled',
                  selected: _filter == 2,
                  onTap: () => setState(() => _filter = 2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < filtered.length; index++) ...[
              if (index > 0)
                Divider(height: 1, thickness: 1, color: colors.divider),
              _ProgressExerciseRow(item: filtered[index]),
            ],
          ],
        );
      },
    );
  }
}

class _ProgressFilterChip extends StatelessWidget {
  const _ProgressFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.textPrimary : colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  label,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? colors.background : colors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressExerciseRow extends StatelessWidget {
  const _ProgressExerciseRow({required this.item});

  final AggregatedExerciseProgress item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final weight = item.latestWeightKg == item.latestWeightKg.roundToDouble()
        ? item.latestWeightKg.toInt().toString()
        : item.latestWeightKg.toStringAsFixed(1).replaceAll('.', ',');
    final detail = '${item.setsCount} × ${item.repsMin}–${item.repsMax}';
    final status = switch (item.status) {
      ExerciseProgressStatus.rising => 'no topo, sobe no próximo',
      ExerciseProgressStatus.steady =>
        'faltam ${((1 - item.completionRatio).clamp(0, 1) * item.repsMax).round()} repetições',
      ExerciseProgressStatus.stalled =>
        'travada há ${item.stalledSessions} treinos',
    };

    return Semantics(
      button: true,
      label: '${item.name}, $weight kg, $detail, $status',
      child: InkWell(
        onTap: () => ExerciseHistoryModal.show(
          context,
          exerciseId: item.id,
          exerciseName: item.name,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$weight kg',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: '  $detail',
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        ],
                      ),
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontFeatures: AppTypography.tabularFeatures,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight:
                            item.status == ExerciseProgressStatus.stalled
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                height: 40,
                child: CustomPaint(
                  painter: _RampPainter(
                    ink: colors.primary,
                    line: colors.divider,
                    isFlat: item.status == ExerciseProgressStatus.stalled,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RampPainter extends CustomPainter {
  const _RampPainter({
    required this.ink,
    required this.line,
    required this.isFlat,
  });

  final Color ink;
  final Color line;
  final bool isFlat;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 96;
    final scaleY = size.height / 40;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final basePaint = Paint()
      ..color = line
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final inkPaint = Paint()
      ..color = ink
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    if (isFlat) {
      path
        ..moveTo(4, 22)
        ..lineTo(18, 22)
        ..lineTo(32, 23)
        ..lineTo(46, 22)
        ..lineTo(60, 22)
        ..lineTo(74, 22);
    } else {
      path
        ..moveTo(4, 34)
        ..lineTo(16, 30)
        ..lineTo(28, 26)
        ..lineTo(28, 20)
        ..lineTo(40, 16)
        ..lineTo(52, 12)
        ..lineTo(52, 8)
        ..lineTo(64, 6);
    }
    final baseline = Path()
      ..moveTo(4, 34)
      ..lineTo(16, 30)
      ..lineTo(28, 26)
      ..lineTo(28, 20)
      ..lineTo(40, 16)
      ..lineTo(52, 12)
      ..lineTo(64, 12);
    canvas.drawPath(baseline, basePaint);
    if (isFlat) {
      for (var x = 4.0; x <= 74; x += 7) {
        canvas.drawCircle(Offset(x, 22), 1, Paint()..color = ink);
      }
    } else {
      canvas.drawPath(path, inkPaint);
    }
    canvas.drawCircle(
      Offset(isFlat ? 74 : 64, isFlat ? 22 : 6),
      3.5,
      Paint()..color = ink,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RampPainter oldDelegate) =>
      oldDelegate.ink != ink ||
      oldDelegate.line != line ||
      oldDelegate.isFlat != isFlat;
}
