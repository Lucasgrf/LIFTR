import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/history_workout_card.dart';

class ProgressWorkoutsView extends ConsumerWidget {
  const ProgressWorkoutsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final historyAsync = ref.watch(historyListProvider);

    return historyAsync.when(
      skipLoadingOnRefresh: true,
      skipError: true,
      loading: () => const LiftrScreenSkeleton(showHero: false, itemCount: 3),
      error: (err, st) => ErrorStateWidget(
        message: userFacingMessage(
          err,
          stackTrace: st,
          context: 'ProgressWorkoutsView.build',
        ),
        safetyNote: offlineSafetyNoteFor(err),
        onRetry: () => ref.invalidate(historyListProvider),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.history_rounded,
            title: 'Nenhum treino registrado ainda',
            subtitle:
                'Conclua seu primeiro treino para consultar séries, cargas e repetições realizadas.',
            actionLabel: 'Ir para Hoje',
            onAction: () => context.go('/'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Treinos finalizados',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '${sessions.length} ${sessions.length == 1 ? 'sessão' : 'sessões'}',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontFeatures: AppTypography.tabularFeatures,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...sessions.map(
              (session) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HistoryWorkoutCard(
                  session: session,
                  onTap: () => context.push('/session/${session.id}/summary'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
