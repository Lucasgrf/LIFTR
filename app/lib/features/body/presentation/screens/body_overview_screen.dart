import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/measurement_providers.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';
import 'package:personal_fitness_os/features/body/presentation/widgets/log_weight_modal.dart';
import 'package:personal_fitness_os/features/body/presentation/widgets/weight_stats_summary_card.dart';

class BodyOverviewScreen extends ConsumerWidget {
  const BodyOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final statsAsync = ref.watch(weightStatsProvider);
    final latestMeasurementAsync = ref.watch(latestMeasurementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Corpo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Histórico de Peso',
            onPressed: () => context.push('/body/weight'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weightStatsProvider);
          ref.invalidate(latestMeasurementProvider);
        },
        child: statsAsync.when(
          data: (stats) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Weight Stats Summary Card
                WeightStatsSummaryCard(
                  stats: stats,
                  onTapHistory: () => context.push('/body/weight'),
                ),
                const SizedBox(height: 16),

                // History Shortcut Card
                AppCard(
                  onTap: () => context.push('/body/weight'),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(context.appRadius.small),
                        ),
                        child: Icon(Icons.show_chart_rounded, color: colors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Histórico de Pesagens',
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ver todos os registros e evolução',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Measurements Card (Connected to /body/measurements)
                AppCard(
                  onTap: () => context.push('/body/measurements'),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(context.appRadius.small),
                        ),
                        child: Icon(Icons.straighten_rounded, color: colors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Medidas Corporais',
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            latestMeasurementAsync.when(
                              data: (m) {
                                if (m == null) {
                                  return Text(
                                    'Nenhuma medição registrada ainda',
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  );
                                }
                                final parts = <String>[];
                                if (m.waist != null) parts.add('Cintura: ${m.waist}cm');
                                if (m.chest != null) parts.add('Peito: ${m.chest}cm');
                                if (m.armRight != null) parts.add('Braço: ${m.armRight}cm');
                                return Text(
                                  parts.isNotEmpty ? parts.join(' • ') : 'Ver medições',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                              loading: () => const Text('Carregando...'),
                              error: (_, __) => const Text('Ver histórico de medidas'),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Evolution Photos Placeholder Card
                AppCard(
                  onTap: () => context.push('/body/photos'),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(context.appRadius.small),
                        ),
                        child: Icon(Icons.photo_library_outlined, color: colors.textSecondary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fotos de Evolução',
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Compare seu físico ao longo do tempo',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            );
          },
          loading: () => const Center(child: LoadingWidget()),
          error: (err, _) => Center(
            child: AppErrorWidget(
              message: err.toString(),
              onRetry: () => ref.refresh(weightStatsProvider),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => LogWeightModal.show(
          context,
          initialWeightKg: statsAsync.value?.currentWeightKg,
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Registrar Peso'),
      ),
    );
  }
}
