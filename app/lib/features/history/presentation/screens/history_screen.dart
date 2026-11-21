import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/history/domain/entities/history_event_type.dart';
import 'package:personal_fitness_os/features/history/domain/entities/timeline_event.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/history_workout_card.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/timeline_event_card.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/timeline_filter_bar.dart';

final historyViewModeProvider = StateProvider.autoDispose<int>((ref) => 0); // 0: Timeline, 1: Treinos

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  void _onEventTap(BuildContext context, TimelineEvent event) {
    switch (event.type) {
      case HistoryEventType.workout:
        context.push('/session/${event.referenceId}/summary');
        break;
      case HistoryEventType.weight:
        context.push('/body/weight');
        break;
      case HistoryEventType.nutrition:
        context.go('/nutrition');
        break;
      case HistoryEventType.goalCheckpoint:
        context.push('/goals/${event.referenceId}');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final viewMode = ref.watch(historyViewModeProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Histórico & Timeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Calendário de Atividades',
            onPressed: () => context.push('/calendar'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
            onPressed: () {
              if (viewMode == 0) {
                ref.invalidate(unifiedTimelineProvider);
              } else {
                ref.invalidate(historyListProvider);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // View Mode Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                  value: 0,
                  icon: Icon(Icons.timeline_rounded),
                  label: Text('Linha do Tempo'),
                ),
                ButtonSegment<int>(
                  value: 1,
                  icon: Icon(Icons.fitness_center_rounded),
                  label: Text('Treinos'),
                ),
              ],
              selected: {viewMode},
              onSelectionChanged: (set) {
                ref.read(historyViewModeProvider.notifier).state = set.first;
              },
            ),
          ),
          const SizedBox(height: 4),

          if (viewMode == 0) ...[
            const TimelineFilterBar(),
            const SizedBox(height: 8),
            Expanded(
              child: _buildTimelineView(context, ref),
            ),
          ] else ...[
            Expanded(
              child: _buildWorkoutsView(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineView(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(unifiedTimelineProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(unifiedTimelineProvider.future),
      child: timelineAsync.when(
        loading: () => const Center(child: LoadingWidget()),
        error: (err, _) {
          final message = err is Failure ? err.message : err.toString();
          return Center(
            child: AppErrorWidget(
              message: message,
              onRetry: () => ref.refresh(unifiedTimelineProvider),
            ),
          );
        },
        data: (events) {
          if (events.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.timeline_rounded,
              title: 'Nenhum registro na linha do tempo',
              subtitle:
                  'Suas atividades (treinos, pesagens, refeições e metas) aparecerão aqui cronologicamente.',
              actionLabel: 'Ir para o Início',
              onAction: () => context.go('/'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TimelineEventCard(
                  event: event,
                  onTap: () => _onEventTap(context, event),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWorkoutsView(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyListProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(historyListProvider.future),
      child: historyAsync.when(
        loading: () => const Center(child: LoadingWidget()),
        error: (err, _) {
          final message = err is Failure ? err.message : err.toString();
          return Center(
            child: AppErrorWidget(
              message: message,
              onRetry: () => ref.refresh(historyListProvider),
            ),
          );
        },
        data: (sessions) {
          if (sessions.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.history_rounded,
              title: 'Nenhum treino no histórico',
              subtitle:
                  'Seus treinos finalizados aparecerão aqui com métricas e detalhes.',
              actionLabel: 'Ir para o Início',
              onAction: () => context.go('/'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HistoryWorkoutCard(
                  session: session,
                  onTap: () => context.push('/session/${session.id}/summary'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
