import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
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
  });

  final WorkoutSession? activeSession;
  final Workout? todayWorkout;
  final TrainingPlan? activePlan;
  final Future<void> Function(Workout? workout) onStartWorkout;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    // 1. If there's an ongoing session
    if (activeSession != null) {
      return AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: fitnessColors.progressMaintain.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(context.appRadius.small),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_rounded, size: 14, color: fitnessColors.progressMaintain),
                      const SizedBox(width: 4),
                      Text(
                        'EM ANDAMENTO',
                        style: context.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: fitnessColors.progressMaintain,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              activeSession!.workoutName,
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${activeSession!.totalCompletedSetsCount} séries registradas até o momento.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            AppButton.primary(
              label: 'Continuar Treino',
              icon: Icons.play_arrow_rounded,
              onPressed: () => context.push('/session/${activeSession!.id}'),
            ),
          ],
        ),
      );
    }

    // 2. If there is a scheduled workout for today in active plan
    if (todayWorkout != null) {
      return AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(context.appRadius.small),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fitness_center_rounded, size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'TREINO DE HOJE',
                        style: context.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  activePlan?.name ?? '',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              todayWorkout!.name,
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${todayWorkout!.exercises.length} exercícios • ~${todayWorkout!.totalWorkingSetsCount} séries válidas',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
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

    // 3. If there is an active plan but no workout scheduled for today
    if (activePlan != null) {
      return AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: fitnessColors.progressNeutral.withOpacity(0.15),
                borderRadius: BorderRadius.circular(context.appRadius.small),
              ),
              child: Text(
                'DESCANSO OU LIVRE',
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: fitnessColors.progressNeutral,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dia livre na sua divisão',
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Aproveite para descansar ou inicie um treino avulso.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
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

    // 4. If no active plan exists
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(context.appRadius.small),
            ),
            child: Text(
              'BEM-VINDO',
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhum programa ativo',
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Crie ou ative um programa de treino para prescrever sua rotina semanal.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          AppButton.primary(
            label: 'Explorar Programas',
            icon: Icons.list_alt_rounded,
            onPressed: () => context.push('/training'),
          ),
        ],
      ),
    );
  }
}
