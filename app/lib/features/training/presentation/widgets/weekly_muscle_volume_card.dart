import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/utils/pt_br_copy_utils.dart';
import 'package:personal_fitness_os/core/widgets/liftr_icon.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';

class WeeklyMuscleVolumeCard extends StatelessWidget {
  const WeeklyMuscleVolumeCard({super.key, required this.plan});

  final TrainingPlan plan;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{
      'Peito': 0,
      'Costas': 0,
      'Pernas': 0,
      'Ombros': 0,
      'Braços': 0,
      'Core': 0,
    };

    for (final workout in plan.workouts) {
      for (final exercise in workout.exercises) {
        final group = exercise.exercise?.primaryMuscleGroup ?? '';
        final label = _labelFor(group);
        if (label != null) {
          counts[label] =
              counts[label]! +
              (exercise.workingSetsCount > 0 ? exercise.workingSetsCount : 3);
        }
      }
    }

    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Volume semanal',
                style: context.textTheme.titleLarge,
              ),
            ),
            Text(
              'Séries válidas',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Meta: 10+ séries/semana',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        for (final entry in counts.entries) ...[
          if (entry.key != counts.keys.first)
            Divider(height: 1, color: colors.divider),
          Semantics(
            container: true,
            excludeSemantics: true,
            label:
                '${entry.key}: ${pluralize(entry.value, 'série válida', 'séries válidas')} na semana${entry.value >= 10 ? ' (meta atingida)' : ''}',
            checked: entry.value >= 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.key, style: context.textTheme.bodyMedium),
                  ),
                  Text(
                    '${entry.value}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontFeatures: AppTypography.tabularFeatures,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (entry.value >= 10) ...[
                    const SizedBox(width: 8),
                    LiftrIcon(
                      LiftrIconName.check,
                      size: 18,
                      color: colors.textPrimary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String? _labelFor(String group) {
    final raw = group.toLowerCase().trim();
    if (raw.contains('chest') || raw.contains('peito')) return 'Peito';
    if (raw.contains('back') || raw.contains('costa') || raw.contains('dorsal'))
      return 'Costas';
    if (raw.contains('leg') ||
        raw.contains('quad') ||
        raw.contains('ham') ||
        raw.contains('glute') ||
        raw.contains('calf') ||
        raw.contains('perna'))
      return 'Pernas';
    if (raw.contains('shoulder') ||
        raw.contains('ombro') ||
        raw.contains('delt'))
      return 'Ombros';
    if (raw.contains('arm') ||
        raw.contains('bicep') ||
        raw.contains('tricep') ||
        raw.contains('braço'))
      return 'Braços';
    if (raw.contains('core') || raw.contains('abs') || raw.contains('abdom'))
      return 'Core';
    return null;
  }
}
