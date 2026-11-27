import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/charts/exercise_load_progression_chart.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet_header.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/history/presentation/mappers/exercise_chart_mapper.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';

class ExerciseHistoryModal extends ConsumerWidget {
  const ExerciseHistoryModal({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    this.embedded = false,
  });

  final String exerciseId;
  final String exerciseName;
  final bool embedded;

  static Future<void> show(
    BuildContext context, {
    required String exerciseId,
    required String exerciseName,
  }) {
    return showLiftrSheet<void>(
      context: context,
      isScrollable: false,
      heightFactor: 0.82,
      builder: (context) => ExerciseHistoryModal(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        embedded: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final radius = context.appRadius;
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseId));

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiftrSheetHeader(
          eyebrow: 'EVOLUÇÃO DE FORÇA',
          title: exerciseName,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: historyAsync.when(
            loading: () => const LiftrScreenSkeleton(showHero: false),
            error: (err, st) => ErrorStateWidget(
              message: userFacingMessage(
                err,
                stackTrace: st,
                context: 'ExerciseHistoryModal.build',
              ),
              safetyNote: offlineSafetyNoteFor(err),
              onRetry: () => ref.invalidate(exerciseHistoryProvider(exerciseId)),
            ),
            data: (records) {
              if (records.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.fitness_center_rounded,
                  title: 'Nenhum histórico encontrado',
                  subtitle:
                      'Execute este exercício em uma sessão de treino para visualizar seu progresso.',
                );
              }

              return ListView(
                children: [
                  ExerciseLoadProgressionChart(
                    series: mapExerciseHistoryToLoadSeries(
                      records,
                      loadColor: colors.primary,
                      e1rmColor: context.fitnessColors.progressUp,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'ÚLTIMAS SESSÕES',
                    style: AppTypography.eyebrow(context),
                  ),
                  const SizedBox(height: 10),
                  ...records.map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        padding: const EdgeInsets.all(14),
                        backgroundColor: colors.surfaceSubtle,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec.sessionName,
                                    style: context.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${rec.setsCount} séries · Top: ${rec.topWeightKg.toStringAsFixed(1)} kg × ${rec.topReps} reps',
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                      color: colors.textSecondary,
                                      fontFeatures:
                                          AppTypography.tabularFeatures,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '1RM ${rec.bestEstimated1Rm.toStringAsFixed(1)} kg',
                                  style: context.textTheme.labelSmall
                                      ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: fitnessColors.progressUp,
                                    fontFeatures:
                                        AppTypography.tabularFeatures,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  rec.date.formatShort(),
                                  style: context.textTheme.labelSmall
                                      ?.copyWith(
                                    color: colors.textTertiary,
                                    fontFeatures:
                                        AppTypography.tabularFeatures,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );

    if (embedded) {
      return content;
    }

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.82,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius.xl)),
        border: Border.all(color: colors.border),
      ),
      child: content,
    );
  }
}
