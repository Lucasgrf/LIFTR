import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/liftr_progress_bar.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';

class RestTimerWidget extends ConsumerWidget {
  const RestTimerWidget({
    super.key,
    this.stepSeconds = 30,
  });

  final int stepSeconds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<RestTimerState>(restTimerNotifierProvider, (previous, next) {
      if (previous != null &&
          previous.isRunning &&
          previous.remainingSeconds == 1 &&
          !next.isRunning) {
        HapticFeedback.heavyImpact();
      }
    });

    final timerState = ref.watch(restTimerNotifierProvider);
    if (!timerState.isRunning) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    final radius = context.appRadius;
    final fitnessColors = context.fitnessColors;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final remainingRatio = timerState.totalSeconds > 0
        ? (timerState.remainingSeconds / timerState.totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, anim, child) {
        return Opacity(
          opacity: anim,
          child: Transform.translate(
            offset: Offset(0, (1.0 - anim) * 24),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(radius.xl),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.48),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.background.withValues(alpha: 0.72),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LiftrProgressBar(
                progress: remainingRatio,
                height: 3,
                color: fitnessColors.timerActive,
                trackColor: colors.surfaceVariant,
                borderRadius: 0,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'DESCANSO',
                            style: AppTypography.eyebrow(context),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timerState.formattedRemaining,
                            style: context.textTheme.displayMedium?.copyWith(
                              fontSize: 28,
                              fontFeatures: AppTypography.tabularFeatures,
                            ),
                          ),
                          if (timerState.exerciseName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              timerState.exerciseName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TimerActionChip(
                      label: '-${stepSeconds}s',
                      semanticLabel: 'Diminuir descanso em $stepSeconds segundos',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(restTimerNotifierProvider.notifier)
                            .addSeconds(-stepSeconds);
                      },
                    ),
                    const SizedBox(width: 6),
                    _TimerActionChip(
                      label: '+${stepSeconds}s',
                      semanticLabel: 'Aumentar descanso em $stepSeconds segundos',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(restTimerNotifierProvider.notifier)
                            .addSeconds(stepSeconds);
                      },
                    ),
                    const SizedBox(width: 6),
                    _TimerActionChip(
                      label: 'Pular',
                      semanticLabel: 'Pular descanso',
                      isPrimary: true,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.read(restTimerNotifierProvider.notifier).stop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerActionChip extends StatelessWidget {
  const _TimerActionChip({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Semantics(
      label: semanticLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius.small),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 46),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isPrimary ? colors.primaryMuted : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(radius.small),
          ),
          child: Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: isPrimary ? colors.primaryLight : colors.textSecondary,
              fontWeight: FontWeight.w700,
              fontFeatures: AppTypography.tabularFeatures,
            ),
          ),
        ),
      ),
    );
  }
}
