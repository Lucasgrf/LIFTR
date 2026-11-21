import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
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
    final radius = context.appRadius;
    final fitnessColors = context.fitnessColors;
    final compactHeight = MediaQuery.sizeOf(context).height < 700;

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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: fitnessColors.progressUp.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(radius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_rounded,
                        size: 14,
                        color: fitnessColors.progressUp,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'EM ANDAMENTO',
                        style: context.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: fitnessColors.progressUp,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
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
              'SESSÃO ATIVA',
              style: AppTypography.eyebrow(context),
            ),
            const SizedBox(height: 4),
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
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryMuted,
                      borderRadius: BorderRadius.circular(radius.full),
                    ),
                    child: Text(
                      chipText,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.primaryLight,
                        fontFeatures: AppTypography.tabularFeatures,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (onSkipOrSwap != null)
                  Semantics(
                    label: 'Pular ou trocar treino do dia',
                    button: true,
                    child: TextButton(
                      onPressed: onSkipOrSwap,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: colors.textSecondary,
                      ),
                      child: const Text('Pular / Trocar'),
                    ),
                  ),
              ],
            ),
            if (!compactHeight) ...[
              const SizedBox(height: 16),
              Transform.rotate(
                angle: -4 * math.pi / 180,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colors.primaryMuted,
                    borderRadius: BorderRadius.circular(radius.medium),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 22,
                    color: colors.primaryLight,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'TREINO DE HOJE',
              style: AppTypography.eyebrow(context),
            ),
            const SizedBox(height: 4),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: fitnessColors.progressNeutral.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(radius.full),
              ),
              child: Text(
                'FILA LIVRE',
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: fitnessColors.progressNeutral,
                ),
              ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(radius.full),
            ),
            child: Text(
              'SEM PROGRAMA ATIVO',
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
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
    final colors = context.appColors;
    final radius = context.appRadius;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius.xl),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radius.xl),
              border: Border.all(color: borderColor, width: 1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  glowColor.withValues(alpha: 0.11),
                  colors.surface,
                ],
                stops: const [0.0, 0.45],
              ),
            ),
            child: child,
          ),
          Positioned(
            top: -55,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 150,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withValues(alpha: 0.16),
                      glowColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
