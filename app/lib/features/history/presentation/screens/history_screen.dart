import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_consistency_view.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_exercises_view.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_segmented_control.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_weight_view.dart';

/// 0: Exercícios, 1: Peso, 2: Consistência
final historyViewModeProvider = StateProvider.autoDispose<int>((ref) => 0);

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final viewMode = ref.watch(historyViewModeProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        color: colors.primary,
        onRefresh: () async {
          if (viewMode == 1) {
            ref.invalidate(weightHistoryProvider);
            ref.invalidate(weightStatsProvider);
          } else {
            ref.invalidate(historyListProvider);
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 36),
          children: [
            ResponsiveContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EVOLUÇÃO OBJETIVA',
                          style: AppTypography.eyebrow(context),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Progresso',
                          style: context.textTheme.displayMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ProgressSegmentedControl(
                    selectedIndex: viewMode,
                    onChanged: (idx) =>
                        ref.read(historyViewModeProvider.notifier).state = idx,
                  ),
                  const SizedBox(height: 20),
                  if (viewMode == 0)
                    const ProgressExercisesView()
                  else if (viewMode == 1)
                    const ProgressWeightView()
                  else
                    const ProgressConsistencyView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
