import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/workout_card_palette.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_icon.dart';
import 'package:personal_fitness_os/core/widgets/liftr_completion_stamp.dart';
import 'package:personal_fitness_os/core/widgets/liftr_workout_card.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/offline_banner_widget.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/workout_queue_provider.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';

class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final sessionAsync = ref.watch(liveSessionDetailProvider(sessionId));
    final historyAsync = ref.watch(historyListProvider);
    final plans =
        ref.watch(trainingPlansStateProvider).asData?.value ?? const [];
    final offline = ref.watch(isOfflineModeProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final canPop = GoRouter.maybeOf(context)?.canPop() ?? false;

    return Scaffold(
      backgroundColor: colors.background,
      body: sessionAsync.when(
        loading: () => const SafeArea(child: LiftrScreenSkeleton()),
        error: (error, stack) => ErrorStateWidget(
          message: userFacingMessage(
            error,
            stackTrace: stack,
            context: 'SessionSummaryScreen.build',
          ),
          safetyNote: offlineSafetyNoteFor(error),
          onRetry: () => ref.invalidate(liveSessionDetailProvider(sessionId)),
        ),
        data: (session) {
          final completedAt = session.completedAt ?? session.startedAt;
          final date = ptBrDateFormat(
            "EEEE, d 'de' MMMM",
          ).format(completedAt).replaceFirst('-feira', '');
          final titleDate = date[0].toUpperCase() + date.substring(1);
          final minutes = math.max(1, session.durationSeconds ~/ 60);
          final targetSets = session.exercises
              .where((exercise) => !exercise.isCardio)
              .fold<int>(0, (sum, exercise) => sum + exercise.targetSetsCount);
          final topExercises = session.exercises.take(5).toList();
          final remainingExercises = session.exercises.skip(5).toList();
          final plan = plans
              .where(
                (item) => item.workouts.any(
                  (workout) => workout.id == session.workoutId,
                ),
              )
              .firstOrNull;
          final queue = plan == null
              ? const []
              : ref
                    .read(workoutQueueProvider.notifier)
                    .orderedWorkouts(plan.id, plan.workouts);
          final queueIndex = queue.indexWhere(
            (workout) => workout.id == session.workoutId,
          );
          final orderLabel = plan == null
              ? 'Ficha'
              : 'Ficha ${queueIndex < 0 ? 1 : queueIndex + 1} de ${queue.length}';
          final sessionWorkout = plan?.workouts
              .where((workout) => workout.id == session.workoutId)
              .firstOrNull;
          final cardColor = sessionWorkout == null
              ? WorkoutCardPalette.forWorkout(session.workoutName)
              : WorkoutCardPalette.forIndex(sessionWorkout.sortOrder);
          final previous = historyAsync.asData?.value
              .where(
                (item) =>
                    item.id != session.id &&
                    item.workoutId == session.workoutId &&
                    (item.completedAt ?? item.startedAt).isBefore(completedAt),
              )
              .firstOrNull;
          final comparison = previous == null
              ? 'Primeiro registro desta ficha.'
              : _comparison(session, previous);
          final secondaryMetrics = [
            if (session.perceivedExertion != null)
              'RPE médio ${session.perceivedExertion!.toStringAsFixed(1).replaceAll('.', ',')}',
            if (session.executionScore != null)
              'Execução ${session.executionScore}%',
          ];

          return SafeArea(
            child: Column(
              children: [
                if (offline)
                  OfflineBannerWidget(pendingChangesCount: pendingCount),
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: ResponsiveContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Semantics(
                          label: 'Voltar',
                          button: true,
                          child: InkWell(
                            onTap: canPop
                                ? () => context.pop()
                                : () => context.go('/'),
                            borderRadius: BorderRadius.circular(999),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: LiftrIcon(
                                    LiftrIconName.back,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            titleDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
                    children: [
                      ResponsiveContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LiftrWorkoutCard(
                              color: cardColor,
                              padding: const EdgeInsets.all(20),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              orderLabel,
                                              style: _metaStyle(context),
                                            ),
                                          ),
                                          Text(
                                            '$minutes min',
                                            style: _metaStyle(context),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 76,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            const SizedBox(height: 12),
                                            Text(
                                              session.workoutName,
                                              style: context
                                                  .textTheme
                                                  .displayMedium
                                                  ?.copyWith(
                                                    fontSize: 40,
                                                    height: 1,
                                                    letterSpacing: -1.2,
                                                    color:
                                                        WorkoutCardPalette.ink,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text.rich(
                                              TextSpan(
                                                style: context
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: WorkoutCardPalette
                                                          .ink,
                                                      fontFeatures:
                                                          AppTypography
                                                              .tabularFeatures,
                                                    ),
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        '${session.totalWorkingSetsCount}${targetSets > 0 ? ' de $targetSets' : ''} séries. ',
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        '${NumberFormat('#,##0', 'pt_BR').format(session.totalVolumeKg.round())} kg',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text: ' no total.',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      for (
                                        var index = 0;
                                        index < topExercises.length;
                                        index++
                                      )
                                        _SessionExerciseLine(
                                          exercise: topExercises[index],
                                          compact: index > 0,
                                        ),
                                      if (remainingExercises.isNotEmpty)
                                        _MoreExercisesRow(
                                          count: remainingExercises.length,
                                          exercises: remainingExercises,
                                        ),
                                      if (session.exercises.any(
                                        (exercise) => exercise.sets.isEmpty,
                                      ))
                                        _NotDoneLine(
                                          exercises: session.exercises
                                              .where(
                                                (exercise) =>
                                                    exercise.sets.isEmpty,
                                              )
                                              .toList(),
                                        ),
                                    ],
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: -4,
                                    child: LiftrCompletionStamp(
                                      date: ptBrDateFormat(
                                        'd MMM',
                                      ).format(completedAt).toUpperCase(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 23),
                            Text(
                              comparison,
                              style: context.textTheme.bodyLarge?.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            if (session.perceivedExertion != null ||
                                session.executionScore != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${secondaryMetrics.join('. ')}.',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                            if (session.notes?.trim().isNotEmpty ?? false) ...[
                              const SizedBox(height: 16),
                              Text(
                                session.notes!.trim(),
                                style: context.textTheme.bodyMedium,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                offline
                                    ? Icon(
                                        Icons.cloud_off_outlined,
                                        size: 16,
                                        color: colors.textSecondary,
                                      )
                                    : LiftrIcon(
                                        LiftrIconName.check,
                                        size: 16,
                                        color: colors.textSecondary,
                                      ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    offline
                                        ? 'Sem internet. O treino fica salvo no celular e sincroniza quando a conexão voltar.'
                                        : pendingCount == 0
                                        ? 'Sincronizado com o WhatsApp'
                                        : 'Sincronizando $pendingCount alterações.',
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(color: colors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _comparison(WorkoutSession current, WorkoutSession previous) {
    final currentVolume = current.totalVolumeKg;
    final previousVolume = previous.totalVolumeKg;
    final difference = currentVolume - previousVolume;
    if (difference.abs() < 0.5) return 'Mesmo volume da ficha anterior.';
    final direction = difference > 0 ? 'Acima' : 'Abaixo';
    return '$direction da ${current.workoutName} anterior.';
  }
}

TextStyle? _metaStyle(BuildContext context) =>
    context.textTheme.bodySmall?.copyWith(
      color: WorkoutCardPalette.secondaryInk,
      fontWeight: FontWeight.w600,
      fontFeatures: AppTypography.tabularFeatures,
    );

class _SessionExerciseLine extends StatelessWidget {
  const _SessionExerciseLine({required this.exercise, this.compact = false});

  final SessionExercise exercise;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sets = exercise.sets.where((set) => !set.isWarmup).toList();
    final reps = sets.map((set) => set.repsCompleted).join(', ');
    final load = sets.isEmpty ? null : sets.first.weightKg;
    final total = exercise.totalVolumeKg.round();
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: compact
                ? WorkoutCardPalette.ink.withValues(alpha: .22)
                : WorkoutCardPalette.ink,
            width: compact ? 1 : 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  exercise.exercise?.name ?? 'Exercício',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: WorkoutCardPalette.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${NumberFormat('#,##0', 'pt_BR').format(total)} kg',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: WorkoutCardPalette.ink,
                  fontWeight: FontWeight.w600,
                  fontFeatures: AppTypography.tabularFeatures,
                ),
              ),
            ],
          ),
          if (sets.isNotEmpty)
            Text(
              '${_weight(load!)} × $reps',
              style: context.textTheme.bodyMedium?.copyWith(
                color: WorkoutCardPalette.penInk,
                fontWeight: FontWeight.w600,
                fontFeatures: AppTypography.tabularFeatures,
              ),
            ),
          if (exercise.sets.any(
            (set) =>
                set.isWarmup ||
                set.hasDropSets ||
                (set.notes?.trim().isNotEmpty ?? false),
          ))
            Text(
              _detailNotes(exercise),
              style: context.textTheme.bodySmall?.copyWith(
                color: WorkoutCardPalette.secondaryInk,
              ),
            ),
        ],
      ),
    );
  }

  String _weight(double value) => value == value.roundToDouble()
      ? '${value.toInt()}'
      : value.toStringAsFixed(1).replaceAll('.', ',');

  String _detailNotes(SessionExercise exercise) {
    final warmups = exercise.sets.where((set) => set.isWarmup).length;
    final dropSets = exercise.sets.where((set) => set.hasDropSets).toList();
    final details = <String>[];
    if (warmups > 0) details.add('$warmups de aquecimento');
    if (dropSets.isNotEmpty) {
      final dropLoads = dropSets
          .expand((set) => set.dropSets)
          .map((drop) => _weight(drop.weightKg))
          .toSet();
      final loadNote = dropLoads.isEmpty
          ? ''
          : ' para ${dropLoads.map((weight) => '$weight kg').join(', ')}';
      details.add('${dropSets.length} com drop$loadNote');
    }
    final note = exercise.sets
        .map((set) => set.notes?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .firstOrNull;
    if (note != null) details.add(note);
    return details.join(', ');
  }
}

class _MoreExercisesRow extends StatelessWidget {
  const _MoreExercisesRow({required this.count, required this.exercises});

  final int count;
  final List<SessionExercise> exercises;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => showLiftrSheet<void>(
      context: context,
      title: 'Outros exercícios',
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final exercise in exercises)
            _SessionExerciseLine(exercise: exercise),
        ],
      ),
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: WorkoutCardPalette.ink.withValues(alpha: .22)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Mais $count exercícios',
              style: context.textTheme.bodyMedium?.copyWith(
                color: WorkoutCardPalette.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${NumberFormat('#,##0', 'pt_BR').format(exercises.fold<double>(0, (total, exercise) => total + exercise.totalVolumeKg).round())} kg',
            style: context.textTheme.bodyMedium?.copyWith(
              color: WorkoutCardPalette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _NotDoneLine extends StatelessWidget {
  const _NotDoneLine({required this.exercises});

  final List<SessionExercise> exercises;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 10, bottom: 6),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: WorkoutCardPalette.ink.withValues(alpha: .22)),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'Não feitos',
            style: context.textTheme.bodyMedium?.copyWith(
              color: WorkoutCardPalette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            exercises
                .map((item) => item.exercise?.name.toLowerCase() ?? 'cardio')
                .join(', '),
            textAlign: TextAlign.right,
            style: context.textTheme.bodyMedium?.copyWith(
              color: WorkoutCardPalette.ink,
            ),
          ),
        ),
      ],
    ),
  );
}
