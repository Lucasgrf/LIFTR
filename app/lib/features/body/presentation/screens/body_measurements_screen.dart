import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/body/domain/entities/body_measurement.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/measurement_providers.dart';
import 'package:personal_fitness_os/features/body/presentation/widgets/log_measurement_modal.dart';

class BodyMeasurementsScreen extends ConsumerWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(measurementsListProvider);
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medidas Corporais'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(measurementsListProvider.future),
        child: listAsync.when(
          data: (measurements) {
            if (measurements.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.straighten_rounded,
                title: 'Nenhuma medida registrada',
                subtitle: 'Acompanhe circunferências de braço, cintura, peito e coxas para ver sua real evolução.',
                actionLabel: 'Registrar Medidas',
                onAction: () => LogMeasurementModal.show(context),
              );
            }

            final latest = measurements.first;
            final previous = measurements.length > 1 ? measurements[1] : null;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                // Latest Summary Comparison Card
                _buildComparisonCard(context, latest, previous),
                const SizedBox(height: 20),

                Text(
                  'HISTÓRICO DE MEDIÇÕES',
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),

                ...measurements.map((m) => _buildMeasurementTile(context, ref, m)),
              ],
            );
          },
          loading: () => const Center(child: LoadingWidget()),
          error: (err, _) => Center(
            child: ErrorStateWidget(
              message: err.toString(),
              onRetry: () => ref.refresh(measurementsListProvider),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => LogMeasurementModal.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova Medição'),
      ),
    );
  }

  Widget _buildComparisonCard(
    BuildContext context,
    BodyMeasurement latest,
    BodyMeasurement? previous,
  ) {
    final colors = context.appColors;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ÚLTIMA AVALIAÇÃO',
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                latest.measuredAt.formatMedium(),
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              if (latest.waist != null)
                _buildMetricItem(context, 'Cintura', latest.waist!, previous?.waist, isDecreasingGood: true),
              if (latest.chest != null)
                _buildMetricItem(context, 'Peito', latest.chest!, previous?.chest),
              if (latest.armRight != null)
                _buildMetricItem(context, 'Braço D.', latest.armRight!, previous?.armRight),
              if (latest.thighRight != null)
                _buildMetricItem(context, 'Coxa D.', latest.thighRight!, previous?.thighRight),
              if (latest.hip != null)
                _buildMetricItem(context, 'Quadril', latest.hip!, previous?.hip, isDecreasingGood: true),
              if (latest.shoulder != null)
                _buildMetricItem(context, 'Ombros', latest.shoulder!, previous?.shoulder),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    double value,
    double? prevValue, {
    bool isDecreasingGood = false,
  }) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    String? deltaText;
    Color deltaColor = colors.textTertiary;

    if (prevValue != null) {
      final diff = value - prevValue;
      if (diff != 0) {
        final sign = diff > 0 ? '+' : '';
        deltaText = '$sign${diff.toStringAsFixed(1)} cm';

        if (diff > 0) {
          deltaColor = isDecreasingGood ? fitnessColors.progressDown : fitnessColors.progressUp;
        } else {
          deltaColor = isDecreasingGood ? fitnessColors.progressUp : fitnessColors.progressDown;
        }
      }
    }

    return SizedBox(
      width: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${value.toStringAsFixed(1)} cm',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          if (deltaText != null)
            Text(
              deltaText,
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: deltaColor,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeasurementTile(
    BuildContext context,
    WidgetRef ref,
    BodyMeasurement m,
  ) {
    final colors = context.appColors;

    final parts = <String>[];
    if (m.waist != null) parts.add('Cintura: ${m.waist}cm');
    if (m.chest != null) parts.add('Peito: ${m.chest}cm');
    if (m.armRight != null) parts.add('Braço: ${m.armRight}cm');
    if (m.thighRight != null) parts.add('Coxa: ${m.thighRight}cm');
    if (m.hip != null) parts.add('Quadril: ${m.hip}cm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.straighten_rounded,
                size: 20,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.measuredAt.formatMedium(),
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    parts.join(' • '),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (m.notes != null && m.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      m.notes!,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: context.fitnessColors.progressDown, size: 20),
              onPressed: () async {
                final useCase = ref.read(deleteMeasurementUseCaseProvider);
                final result = await useCase.execute(m.id);
                if (!context.mounted) return;

                result.fold(
                  (_) {
                    ref.invalidate(measurementsListProvider);
                    ref.invalidate(latestMeasurementProvider);
                    context.showSnackBar('Medição excluída.');
                  },
                  (failure) => context.showSnackBar(failure.message, isError: true),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
