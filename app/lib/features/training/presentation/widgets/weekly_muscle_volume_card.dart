import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/liftr_progress_bar.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';

class _MuscleVolumeEntry {
  const _MuscleVolumeEntry({
    required this.label,
    required this.sets,
  });

  final String label;
  final int sets;
}

class WeeklyMuscleVolumeCard extends StatelessWidget {
  const WeeklyMuscleVolumeCard({
    super.key,
    required this.plan,
  });

  final TrainingPlan plan;

  static const int _targetWeeklySets = 10;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{
      'chest': 0,
      'back': 0,
      'legs': 0,
      'shoulders': 0,
      'arms': 0,
      'core': 0,
    };

    for (final workout in plan.workouts) {
      for (final we in workout.exercises) {
        final rawGroup =
            (we.exercise?.primaryMuscleGroup ?? '').toLowerCase().trim();
        final sets = we.workingSetsCount > 0 ? we.workingSetsCount : 3;
        final bucket = _mapMuscleBucket(rawGroup);
        if (bucket != null) {
          counts[bucket] = (counts[bucket] ?? 0) + sets;
        }
      }
    }

    final entries = [
      _MuscleVolumeEntry(label: 'Peito', sets: counts['chest']!),
      _MuscleVolumeEntry(label: 'Costas', sets: counts['back']!),
      _MuscleVolumeEntry(label: 'Pernas', sets: counts['legs']!),
      _MuscleVolumeEntry(label: 'Ombros', sets: counts['shoulders']!),
      _MuscleVolumeEntry(label: 'Braços', sets: counts['arms']!),
      _MuscleVolumeEntry(label: 'Core', sets: counts['core']!),
    ];

    final maxSets = entries.fold<int>(
      16,
      (prev, e) => e.sets > prev ? e.sets : prev,
    );

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Volume semanal',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Text(
                  'SÉRIES VÁLIDAS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppTypography.eyebrow(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (int row = 0; row < 3; row++) ...[
            Row(
              children: [
                Expanded(
                  child: _MuscleBarItem(
                    entry: entries[row * 2],
                    maxSets: maxSets,
                    targetSets: _targetWeeklySets,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _MuscleBarItem(
                    entry: entries[row * 2 + 1],
                    maxSets: maxSets,
                    targetSets: _targetWeeklySets,
                  ),
                ),
              ],
            ),
            if (row < 2) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  String? _mapMuscleBucket(String raw) {
    if (raw.contains('chest') || raw.contains('peito')) return 'chest';
    if (raw.contains('back') || raw.contains('costa') || raw.contains('dorsal')) {
      return 'back';
    }
    if (raw.contains('leg') ||
        raw.contains('quad') ||
        raw.contains('ham') ||
        raw.contains('glute') ||
        raw.contains('calf') ||
        raw.contains('calves') ||
        raw.contains('perna')) {
      return 'legs';
    }
    if (raw.contains('shoulder') || raw.contains('ombro') || raw.contains('delt')) {
      return 'shoulders';
    }
    if (raw.contains('arm') ||
        raw.contains('bicep') ||
        raw.contains('tricep') ||
        raw.contains('braço')) {
      return 'arms';
    }
    if (raw.contains('core') || raw.contains('abs') || raw.contains('abdom')) {
      return 'core';
    }
    return null;
  }
}

class _MuscleBarItem extends StatelessWidget {
  const _MuscleBarItem({
    required this.entry,
    required this.maxSets,
    required this.targetSets,
  });

  final _MuscleVolumeEntry entry;
  final int maxSets;
  final int targetSets;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ratio = maxSets > 0 ? (entry.sets / maxSets).clamp(0.0, 1.0) : 0.0;
    final barColor = entry.sets >= targetSets
        ? colors.primary
        : entry.sets > 0
            ? colors.textSecondary
            : colors.textTertiary;

    return Semantics(
      container: true,
      label: '${entry.label}: ${entry.sets} séries válidas na semana',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${entry.sets} séries',
                style: context.textTheme.labelSmall?.copyWith(
                  color: entry.sets >= targetSets
                      ? colors.primaryLight
                      : colors.textTertiary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: AppTypography.tabularFeatures,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LiftrProgressBar(
            progress: ratio,
            height: 5,
            color: barColor,
            trackColor: colors.surfaceElevated,
          ),
        ],
      ),
    );
  }
}
