import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

class SessionTimerHeader extends StatelessWidget {
  const SessionTimerHeader({
    super.key,
    required this.session,
    required this.elapsedSeconds,
  });

  final WorkoutSession session;
  final int elapsedSeconds;

  String get _formattedDuration {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Timer
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 20, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                _formattedDuration,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          Container(
            height: 24,
            width: 1,
            color: colors.border,
          ),

          // Working Sets Count
          Row(
            children: [
              Icon(Icons.checklist_rounded, size: 20, color: fitnessColors.progressNeutral),
              const SizedBox(width: 6),
              Text(
                '${session.totalWorkingSetsCount} séries válidas',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),

          Container(
            height: 24,
            width: 1,
            color: colors.border,
          ),

          // Volume / Tonelagem
          Row(
            children: [
              Icon(Icons.fitness_center_rounded, size: 18, color: fitnessColors.muscleArms),
              const SizedBox(width: 6),
              Text(
                '${session.totalVolumeKg.toStringAsFixed(0)} kg',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
