import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
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
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    // 1. Ongoing active session
    if (activeSession != null) {
      return _HeroShell(
        borderColor: fitnessColors.progressUp.withValues(alpha: 0.45),
        glowColor: fitnessColors.progressUp,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const LiftrBadge(
                  label: 'EM ANDAMENTO',
                  tone: LiftrBadgeTone.success,
                  icon: Icons.timer_rounded,
                ),
                const Spacer(),
                Text(
                  activeSession!.formattedDuration,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontFeatures: AppTypography.tabularFeatures,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              activeSession!.workoutName,
              style: context.textTheme.displayMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '${activeSession!.totalCompletedSetsCount} séries registradas até o momento',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                fontFeatures: AppTypography.tabularFeatures,
              ),
            ),
            const SizedBox(height: 20),
            AppButton.primary(
              label: 'Continuar Treino',
              icon: Icons.play_arrow_rounded,
              onPressed: () => context.push('/session/${activeSession!.id}'),
            ),
          ],
        ),
      );
    }

    // 2. Prescribed next workout in rotating queue
    if (todayWorkout != null) {
      final pos = queuePosition ?? 1;
      final total = queueTotal ?? activePlan?.workouts.length ?? 1;
      final chipText = total > 1
          ? 'Treino $pos de $total · Próximo'
          : (activePlan?.name ?? 'Próximo na fila');
      final durationEst = todayWorkout!.estimatedDurationMinutes ?? 50;

      return _HeroShell(
        borderColor: colors.primary.withValues(alpha: 0.43),
        glowColor: colors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  LiftrBadge(
                    label: chipText,
                    tone: LiftrBadgeTone.brand,
                  ),
                  if (onSkipOrSwap != null)
                    Semantics(
                      label: 'Pular ou trocar treino do dia',
                      button: true,
                      child: TextButton(
                        onPressed: onSkipOrSwap,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          foregroundColor: colors.textSecondary,
                        ),
                        child: const Text('Pular / Trocar'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              todayWorkout!.name,
              style: context.textTheme.displayMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '${todayWorkout!.exercises.length} exercícios · ${todayWorkout!.totalWorkingSetsCount} séries · ~$durationEst min',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                fontFeatures: AppTypography.tabularFeatures,
              ),
            ),
            const SizedBox(height: 20),
            AppButton.primary(
              label: 'Iniciar Treino',
              icon: Icons.play_arrow_rounded,
              isLoading: isLoading,
              onPressed: () => onStartWorkout(todayWorkout),
            ),
          ],
        ),
      );
    }

    // 3. Active plan exists but has no workouts yet
    if (activePlan != null) {
      return _HeroShell(
        borderColor: colors.border,
        glowColor: fitnessColors.progressNeutral,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LiftrBadge(
              label: 'FILA LIVRE',
              tone: LiftrBadgeTone.neutral,
            ),
            const SizedBox(height: 14),
            Text(
              'Treino avulso pronto',
              style: context.textTheme.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Adicione sessões ao plano ${activePlan!.name} ou comece um treino livre.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            AppButton.secondary(
              label: 'Iniciar Treino Avulso',
              icon: Icons.add_rounded,
              isLoading: isLoading,
              onPressed: () => onStartWorkout(null),
            ),
          ],
        ),
      );
    }

    // 4. No active plan exists
    return _HeroShell(
      borderColor: colors.border,
      glowColor: colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LiftrBadge(
            label: 'SEM PROGRAMA ATIVO',
            tone: LiftrBadgeTone.neutral,
          ),
          const SizedBox(height: 14),
          Text(
            'Monte sua fila rotativa',
            style: context.textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Ative ou crie um programa para que o LIFTR prescreva seu próximo treino.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          AppButton.primary(
            label: 'Escolher Programa',
            icon: Icons.fitness_center_rounded,
            onPressed: () => context.go('/training'),
          ),
        ],
      ),
    );
  }
}

class _HeroShell extends StatelessWidget {
  const _HeroShell({
    required this.borderColor,
    required this.glowColor,
    required this.child,
  });

  final Color borderColor;
  final Color glowColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = context.appRadius;

    return AppCard(
      variant: AppCardVariant.accented,
      accentColor: glowColor,
      borderColor: borderColor,
      borderRadius: radius.xl,
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}
