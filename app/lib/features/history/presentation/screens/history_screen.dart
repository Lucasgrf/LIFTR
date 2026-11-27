import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_consistency_view.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_exercises_view.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_segmented_control.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_weight_view.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_workouts_view.dart';
import 'package:personal_fitness_os/features/weekly_comparison/presentation/providers/weekly_comparison_providers.dart';

/// 0: Exercícios, 1: Peso, 2: Consistência, 3: Treinos
final historyViewModeProvider = StateProvider.autoDispose<int>((ref) => 0);

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final viewMode = ref.watch(historyViewModeProvider);
    final weekSummary = ref.watch(currentWeekSummaryProvider).asData?.value;

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        color: colors.primary,
        onRefresh: () async {
          final hadPrimaryData = viewMode == 1
              ? ref.read(weightHistoryProvider).hasValue
              : ref.read(historyListProvider).hasValue;
          var primaryFailed = false;
          final summaryFuture = ref
              .refresh(currentWeekSummaryProvider.future)
              .then<void>((_) {}, onError: (Object _, StackTrace _) {});
          if (viewMode == 1) {
            await Future.wait<void>([
              summaryFuture,
              ref.refresh(weightHistoryProvider.future).then<void>(
                (_) {},
                onError: (Object _, StackTrace _) {
                  primaryFailed = true;
                },
              ),
              ref
                  .refresh(weightStatsProvider.future)
                  .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
            ]);
          } else {
            await Future.wait<void>([
              summaryFuture,
              ref.refresh(historyListProvider.future).then<void>(
                (_) {},
                onError: (Object _, StackTrace _) {
                  primaryFailed = true;
                },
              ),
            ]);
          }
          if (primaryFailed && hadPrimaryData && context.mounted) {
            context.showSnackBar('Sem conexão. Mostrando dados salvos.');
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  const SizedBox(height: 8),
                  Semantics(
                    label: 'Abrir comparação semanal e cardio',
                    button: true,
                    child: AppCard(
                      onTap: () => context.push('/weekly-comparison'),
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: colors.primaryMuted,
                                borderRadius:
                                    BorderRadius.circular(radius.small),
                              ),
                              child: Icon(
                                Icons.compare_arrows_rounded,
                                size: 18,
                                color: colors.primaryLight,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Comparação semanal & Cardio',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.titleSmall,
                                  ),
                                  if (weekSummary != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${formatCardioSeconds(weekSummary.currentWeek.cardioDurationSeconds)} cardio · ${weekSummary.currentWeek.workoutsCompleted} treinos esta semana',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                        color: colors.textSecondary,
                                        fontFeatures:
                                            AppTypography.tabularFeatures,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: colors.textTertiary,
                            ),
                          ],
                        ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  else if (viewMode == 2)
                    const ProgressConsistencyView()
                  else
                    const ProgressWorkoutsView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
