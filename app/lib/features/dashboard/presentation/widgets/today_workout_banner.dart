import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/workout_card_palette.dart';
import 'package:personal_fitness_os/core/utils/pt_br_copy_utils.dart';
import 'package:personal_fitness_os/core/widgets/liftr_blank_fiche.dart';
import 'package:personal_fitness_os/core/widgets/liftr_workout_card.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/today_exercise_preview_card.dart';

class TodayWorkoutBanner extends StatelessWidget {
  const TodayWorkoutBanner({
    super.key,
    this.activeSession,
    this.todayWorkout,
    this.activePlan,
    required this.onStartWorkout,
    this.isLoading = false,
    this.queuePosition,
    this.queueTotal,
    this.onSkipOrSwap,
  });

  final WorkoutSession? activeSession;
  final Workout? todayWorkout;
  final TrainingPlan? activePlan;
  final Future<void> Function(Workout? workout) onStartWorkout;
  final bool isLoading;
  final int? queuePosition;
  final int? queueTotal;
  final VoidCallback? onSkipOrSwap;

  @override
  Widget build(BuildContext context) {
    if (activeSession != null) {
      final session = activeSession!;
      final cardColor = WorkoutCardPalette.forWorkout(session.workoutName);
      return LiftrWorkoutCard(
        color: cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FichaHeading(
              left: 'SESSÃO EM ANDAMENTO',
              right: session.formattedDuration,
            ),
            const SizedBox(height: 12),
            Text(
              session.workoutName,
              style: context.textTheme.displayMedium?.copyWith(
                color: WorkoutCardPalette.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${session.totalCompletedSetsCount} séries registradas.',
              style: context.textTheme.bodyLarge?.copyWith(
                color: WorkoutCardPalette.ink,
              ),
            ),
          ],
        ),
      );
    }

    final workout = todayWorkout;
    if (workout == null) return _EmptyTodayCard(activePlan: activePlan);

    final cardColor = WorkoutCardPalette.forIndex(workout.sortOrder);
    final position = queuePosition ?? 1;
    final total = queueTotal ?? activePlan?.workouts.length ?? 1;
    final duration = workout.estimatedDurationMinutes;
    final metadata =
        '${[pluralize(workout.exercises.length, 'exercício', 'exercícios'), pluralize(workout.totalWorkingSetsCount, 'série', 'séries'), if (duration != null) 'cerca de $duration min'].join(', ')}.';
    final titleStyle = workout.name.length <= 8
        ? context.textTheme.displayLarge
        : context.textTheme.displayMedium;

    return LiftrWorkoutCard(
      color: cardColor,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FichaHeading(
            left: 'Ficha $position de $total',
            right: 'próxima da fila',
          ),
          const SizedBox(height: 12),
          Text(
            workout.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: titleStyle?.copyWith(
              color: WorkoutCardPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metadata,
            style: context.textTheme.bodyLarge?.copyWith(
              color: WorkoutCardPalette.ink,
              fontFeatures: AppTypography.tabularFeatures,
            ),
          ),
          if (workout.exercises.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Em azul, o que você fez da última vez.',
              style: context.textTheme.bodySmall?.copyWith(
                color: WorkoutCardPalette.secondaryInk,
              ),
            ),
            const SizedBox(height: 7),
            for (final exercise in workout.exercises.take(3))
              TodayExercisePreviewCard(
                index: workout.exercises.take(3).toList().indexOf(exercise),
                workoutExercise: exercise,
                embedded: true,
              ),
            if (workout.exercises.length > 3)
              _MoreExercisesRow(
                count: workout.exercises.length - 3,
                onView: () => _openWorkout(context, workout),
              ),
          ],
        ],
      ),
    );
  }

  void _openWorkout(BuildContext context, Workout workout) {
    final plan = activePlan;
    if (plan == null) return;
    context.push('/training/${plan.id}/workout/${workout.id}');
  }
}

class _FichaHeading extends StatelessWidget {
  const _FichaHeading({required this.left, required this.right});

  final String left;
  final String right;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        child: Text(
          left,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(
            color: WorkoutCardPalette.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          right,
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(
            color: WorkoutCardPalette.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _MoreExercisesRow extends StatelessWidget {
  const _MoreExercisesRow({required this.count, required this.onView});

  final int count;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: WorkoutCardPalette.ink.withValues(alpha: .22)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Mais $count ${count == 1 ? 'exercício' : 'exercícios'}',
              style: context.textTheme.bodyMedium?.copyWith(
                color: WorkoutCardPalette.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onView,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: WorkoutCardPalette.ink,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              textStyle: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
            child: const Text('Ver a ficha'),
          ),
        ],
      ),
    );
  }
}

class _EmptyTodayCard extends StatelessWidget {
  const _EmptyTodayCard({this.activePlan});

  final TrainingPlan? activePlan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiftrBlankFiche(
          title: 'Nenhuma\nficha ainda',
          description: activePlan == null
              ? 'Monte seu programa ou cole o código de um programa que alguém te mandou.'
              : 'Adicione fichas ao programa ${activePlan!.name} para preencher o baralho.',
        ),
      ],
    );
  }
}
