import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_consistency_view.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_exercises_view.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_segmented_control.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_weight_view.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_workouts_view.dart';

/// 0: Exercícios, 1: Peso, 2: Consistência, 3: Treinos
final historyViewModeProvider = StateProvider.autoDispose<int>((ref) => 0);

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(historyViewModeProvider);

    Future<void> refreshHistory() async {
      final hadPrimaryData = viewMode == 1
          ? ref.read(weightHistoryProvider).hasValue
          : ref.read(historyListProvider).hasValue;
      Object? refreshError;
      StackTrace? refreshStack;
      if (viewMode == 1) {
        await Future.wait<void>([
          ref
              .refresh(weightHistoryProvider.future)
              .then<void>(
                (_) {},
                onError: (Object error, StackTrace stack) {
                  refreshError = error;
                  refreshStack = stack;
                },
              ),
          ref
              .refresh(weightStatsProvider.future)
              .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
        ]);
      } else {
        await ref
            .refresh(historyListProvider.future)
            .then<void>(
              (_) {},
              onError: (Object error, StackTrace stack) {
                refreshError = error;
                refreshStack = stack;
              },
            );
      }
      if (refreshError != null && hadPrimaryData && context.mounted) {
        final message = userFacingMessage(
          refreshError!,
          stackTrace: refreshStack,
          context: 'HistoryScreen.refreshHistory',
        );
        context.showSnackBar('$message Mostrando dados salvos.');
      }
    }

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: RefreshIndicator(
        color: context.appColors.primary,
        onRefresh: refreshHistory,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 32, 0, 36),
          children: [
            ResponsiveContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Progresso', style: context.textTheme.displayMedium),
                  const SizedBox(height: 24),
                  ProgressSegmentedControl(
                    selectedIndex: viewMode,
                    onChanged: (index) {
                      ref.read(historyViewModeProvider.notifier).state = index;
                    },
                  ),
                  const SizedBox(height: 16),
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
