import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/workout_card_palette.dart';
import 'package:personal_fitness_os/core/utils/pt_br_copy_utils.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/liftr_workout_card.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

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
      return _WorkoutHeroCard(
        color: WorkoutCardPalette.forKey(activeSession!.workoutName),
        eyebrow: 'EM ANDAMENTO',
        title: activeSession!.workoutName,
        subtitle:
            '${pluralize(activeSession!.totalCompletedSetsCount, 'série', 'séries')} registradas · ${activeSession!.formattedDuration}',
        actionLabel: 'Continuar ${activeSession!.workoutName}',
        actionIcon: Icons.play_arrow_rounded,
        onPressed: () => context.push('/session/${activeSession!.id}'),
      );
    }

    if (todayWorkout != null) {
      final workout = todayWorkout!;
      final position = queuePosition ?? 1;
      final total = queueTotal ?? activePlan?.workouts.length ?? 1;
      final minutes = workout.estimatedDurationMinutes ?? 50;
      final preview = workout.exercises.take(3).map((exercise) {
        final name = exercise.exercise?.name ?? 'Exercício';
        final prescription =
            '${exercise.workingSetsCount} '
            '${exercise.workingSetsCount == 1 ? 'série' : 'séries'}';
        return '$name · $prescription';
      }).toList();
      final remaining = workout.exercises.length - preview.length;

      return _WorkoutHeroCard(
        color: WorkoutCardPalette.forKey(workout.id),
        eyebrow: total > 1
            ? 'FICHA $position DE $total · PRÓXIMA'
            : 'PRÓXIMA DA FILA',
        title: workout.name,
        subtitle:
            '${pluralize(workout.exercises.length, 'exercício', 'exercícios')} · ${pluralize(workout.totalWorkingSetsCount, 'série', 'séries')} · cerca de $minutes min',
        preview: preview,
        remainingCount: remaining,
        actionLabel: 'Começar ${workout.name}',
        actionIcon: Icons.play_arrow_rounded,
        onPressed: () => onStartWorkout(workout),
        onChooseWorkout: onSkipOrSwap,
      );
    }

    final colors = context.appColors;
    final radius = context.appRadius;
    final hasPlan = activePlan != null;
    return AppCard(
      variant: AppCardVariant.raised,
      borderRadius: radius.large,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasPlan ? 'FILA LIVRE' : 'SEM PROGRAMA ATIVO',
            style: context.textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasPlan ? 'Treino avulso pronto' : 'Monte sua fila rotativa',
            style: context.textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(
            hasPlan
                ? 'Adicione sessões ao programa ${activePlan!.name} ou comece um treino livre.'
                : 'Ative ou crie um programa para escolher seu próximo treino.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          AppButton.primary(
            label: hasPlan ? 'Começar treino avulso' : 'Escolher programa',
            icon: hasPlan ? Icons.add_rounded : Icons.fitness_center_rounded,
            isLoading: isLoading,
            onPressed: hasPlan
                ? () => onStartWorkout(null)
                : () => context.go('/training'),
          ),
        ],
      ),
    );
  }
}

class _WorkoutHeroCard extends StatelessWidget {
  const _WorkoutHeroCard({
    required this.color,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionIcon,
    required this.onPressed,
    this.preview = const [],
    this.remainingCount = 0,
    this.onChooseWorkout,
  });

  final Color color;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onPressed;
  final List<String> preview;
  final int remainingCount;
  final VoidCallback? onChooseWorkout;

  @override
  Widget build(BuildContext context) {
    const ink = WorkoutCardPalette.ink;
    const secondaryInk = WorkoutCardPalette.secondaryInk;

    return LiftrWorkoutCard(
      color: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: const TextStyle(
              color: secondaryInk,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onChooseWorkout != null)
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                label: 'Pular ou trocar treino da fila',
                button: true,
                child: TextButton(
                  onPressed: onChooseWorkout,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: ink,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Pular / Trocar'),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            title,
            style: context.textTheme.displayMedium?.copyWith(
              color: ink,
              fontSize: 48,
              height: 1,
              fontWeight: FontWeight.w700,
              fontFeatures: AppTypography.tabularFeatures,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: context.textTheme.bodyMedium?.copyWith(
              color: secondaryInk,
              fontFeatures: AppTypography.tabularFeatures,
            ),
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final item in preview) ...[
              Divider(height: 1, color: secondaryInk.withValues(alpha: 0.22)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  item,
                  style: TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            if (remainingCount > 0)
              Text(
                'Mais $remainingCount ${remainingCount == 1 ? 'exercício' : 'exercícios'}',
                style: TextStyle(color: secondaryInk, fontSize: 15),
              ),
          ],
          const SizedBox(height: 16),
          AppButton.primary(
            label: actionLabel,
            icon: actionIcon,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
