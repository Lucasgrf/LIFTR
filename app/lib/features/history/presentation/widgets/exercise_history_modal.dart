import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';

class ExerciseHistoryModal extends ConsumerWidget {
  const ExerciseHistoryModal({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  final String exerciseId;
  final String exerciseName;

  static Future<void> show(
    BuildContext context, {
    required String exerciseId,
    required String exerciseName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseHistoryModal(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.appRadius.large),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Histórico de Progressão',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            exerciseName,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: LoadingWidget()),
              error: (err, _) => Center(
                child: Text('Erro ao carregar histórico: $err'),
              ),
              data: (records) {
                if (records.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.fitness_center_rounded,
                    title: 'Nenhum histórico encontrado',
                    subtitle: 'Execute este exercício em uma sessão de treino para visualizar seu progresso.',
                  );
                }

                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final rec = records[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colors.surfaceVariant,
                                borderRadius: BorderRadius.circular(
                                    context.appRadius.small),
                              ),
                              child: Icon(Icons.fitness_center_rounded,
                                  size: 18, color: colors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec.sessionName,
                                    style: context.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${rec.setsCount} séries • Top: ${rec.topWeightKg.toStringAsFixed(1)} kg × ${rec.topReps} reps',
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '1RM est: ${rec.bestEstimated1Rm.toStringAsFixed(1)} kg',
                                  style: context.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: fitnessColors.progressUp,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  rec.date.formatShort(),
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: colors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
