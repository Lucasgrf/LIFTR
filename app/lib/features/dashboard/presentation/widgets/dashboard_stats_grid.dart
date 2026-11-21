import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/features/dashboard/domain/entities/weekly_stats.dart';

class DashboardStatsGrid extends StatelessWidget {
  const DashboardStatsGrid({
    super.key,
    required this.stats,
  });

  final WeeklyStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    return Row(
      children: [
        _buildStatCard(
          context,
          title: 'Volume Semanal',
          value: '${stats.totalVolumeKg.toStringAsFixed(0)} kg',
          icon: Icons.fitness_center_rounded,
          color: fitnessColors.progressUp,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          context,
          title: 'Treinos Feitos',
          value: '${stats.completedWorkoutsCount}',
          icon: Icons.checklist_rounded,
          color: colors.primary,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          context,
          title: 'Tempo Total',
          value: '${stats.totalDurationMinutes}m',
          icon: Icons.timer_outlined,
          color: fitnessColors.progressNeutral,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colors = context.appColors;

    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.textTertiary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
