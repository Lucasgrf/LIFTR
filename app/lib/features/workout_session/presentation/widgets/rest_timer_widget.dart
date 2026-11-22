import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_motion.dart';
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
      if (previous != null && !previous.isCompleted && next.isCompleted) {
        HapticFeedback.heavyImpact();
      }
    });

    final timerState = ref.watch(restTimerNotifierProvider);
    if (!timerState.isVisible) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    final radius = context.appRadius;
    final fitnessColors = context.fitnessColors;
    final motion = context.appMotion;
    final notifier = ref.read(restTimerNotifierProvider.notifier);

    final isCompleted = timerState.isCompleted;
    final isPaused = timerState.isPaused;
    final remainingRatio = isCompleted
        ? 1.0
        : (timerState.totalSeconds > 0
            ? (timerState.remainingSeconds / timerState.totalSeconds)
                .clamp(0.0, 1.0)
            : 0.0);

    final statusLabel = isCompleted
        ? 'DESCANSO CONCLUÍDO'
        : isPaused
            ? 'PAUSADO'
            : 'DESCANSO';
    final statusColor = isCompleted
        ? fitnessColors.progressUp
        : isPaused
            ? colors.textTertiary
            : colors.primaryLight;
    final borderColor = isCompleted
        ? fitnessColors.progressUp
        : isPaused
            ? colors.border
            : colors.primary.withValues(alpha: 0.48);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.05, end: 1.0),
      duration: motion.resolve(context, motion.standard),
      curve: motion.curveStandard,
      builder: (context, anim, child) {
        return Opacity(
          opacity: anim,
          child: Transform.translate(
            offset: Offset(0, (1.0 - anim) * 16),
            child: child,
          ),
        );
      },
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(radius.xl),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LiftrProgressBar(
                  progress: remainingRatio,
                  height: 3,
                  color: isCompleted
                      ? fitnessColors.progressUp
                      : isPaused
                          ? colors.textTertiary
                          : fitnessColors.timerActive,
                  trackColor: colors.surfaceVariant,
                  borderRadius: 0,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Row 1: State eyebrow + exercise context | Large countdown
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  statusLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.eyebrow(context).copyWith(
                                    color: statusColor,
                                  ),
                                ),
                                if (timerState.exerciseName != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    timerState.exerciseName!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        context.textTheme.labelSmall?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 112),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                isCompleted
                                    ? '00:00'
                                    : timerState.formattedRemaining,
                                maxLines: 1,
                                softWrap: false,
                                style:
                                    context.textTheme.displayMedium?.copyWith(
                                  fontSize: 28,
                                  height: 1.05,
                                  color: isCompleted
                                      ? fitnessColors.progressUp
                                      : colors.textPrimary,
                                  fontFeatures: AppTypography.tabularFeatures,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Row 2: Controls (safe at 320px + 1.3x scale)
                      if (isCompleted)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Pronto para a próxima série',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.labelMedium?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _TimerActionChip(
                              label: 'OK',
                              semanticLabel: 'Fechar aviso de descanso concluído',
                              isPrimary: true,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                notifier.dismissCompleted();
                              },
                            ),
                          ],
                        )
                      else
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _TimerActionChip(
                              label: '-${stepSeconds}s',
                              semanticLabel:
                                  'Diminuir descanso em $stepSeconds segundos',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                notifier.addSeconds(-stepSeconds);
                              },
                            ),
                            _TimerIconActionChip(
                              icon: isPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              semanticLabel: isPaused
                                  ? 'Retomar descanso'
                                  : 'Pausar descanso',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                notifier.togglePauseResume();
                              },
                            ),
                            _TimerActionChip(
                              label: '+${stepSeconds}s',
                              semanticLabel:
                                  'Aumentar descanso em $stepSeconds segundos',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                notifier.addSeconds(stepSeconds);
                              },
                            ),
                            _TimerActionChip(
                              label: 'Pular',
                              semanticLabel: 'Pular descanso',
                              isPrimary: true,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                notifier.stop();
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
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
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isPrimary ? colors.primaryMuted : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(radius.small),
            border: isPrimary
                ? Border.all(color: colors.primary.withValues(alpha: 0.35))
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
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

class _TimerIconActionChip extends StatelessWidget {
  const _TimerIconActionChip({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

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
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(radius.small),
          ),
          child: Icon(icon, size: 20, color: colors.textPrimary),
        ),
      ),
    );
  }
}
