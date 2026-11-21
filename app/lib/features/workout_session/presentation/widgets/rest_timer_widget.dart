import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';

class RestTimerWidget extends ConsumerWidget {
  const RestTimerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerNotifierProvider);

    if (!timerState.isRunning) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(context.appRadius.medium),
        border: Border.all(color: colors.primary.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.appRadius.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linear Progress Bar
            LinearProgressIndicator(
              value: timerState.progress,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              minHeight: 4,
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                children: [
                  // Timer Icon & Countdown
                  Icon(Icons.hourglass_top_rounded, color: colors.primary, size: 22),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timerState.formattedRemaining,
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (timerState.exerciseName != null)
                        Text(
                          timerState.exerciseName!,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),

                  const Spacer(),

                  // -30s Button
                  IconButton(
                    onPressed: () => ref
                        .read(restTimerNotifierProvider.notifier)
                        .addSeconds(-30),
                    tooltip: '-30s',
                    icon: const Text('-30s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),

                  // +30s Button
                  IconButton(
                    onPressed: () => ref
                        .read(restTimerNotifierProvider.notifier)
                        .addSeconds(30),
                    tooltip: '+30s',
                    icon: const Text('+30s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),

                  // Skip Button
                  TextButton(
                    onPressed: () =>
                        ref.read(restTimerNotifierProvider.notifier).stop(),
                    style: TextButton.styleFrom(
                      foregroundColor: fitnessColors.progressDown,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Pular', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
