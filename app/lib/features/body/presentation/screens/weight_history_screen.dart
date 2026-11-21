import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/widgets/charts/weight_evolution_chart.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';
import 'package:personal_fitness_os/features/body/presentation/widgets/log_weight_modal.dart';
import 'package:personal_fitness_os/features/body/presentation/widgets/weight_entry_list_tile.dart';

class WeightHistoryScreen extends ConsumerWidget {
  const WeightHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(weightHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Peso'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(weightHistoryProvider.future),
        child: historyAsync.when(
          data: (entries) {
            if (entries.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.monitor_weight_outlined,
                title: 'Nenhuma pesagem registrada',
                subtitle: 'Comece registrando seu peso diário para acompanhar médias móveis e evolução.',
                actionLabel: 'Registrar Peso',
                onAction: () => LogWeightModal.show(context),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: entries.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: WeightEvolutionChart(entries: entries),
                  );
                }

                final entry = entries[index - 1];
                return WeightEntryListTile(
                  entry: entry,
                  onDelete: () async {
                    final useCase = ref.read(deleteWeightEntryUseCaseProvider);
                    final result = await useCase.execute(entry.id);

                    if (!context.mounted) return;

                    result.fold(
                      (_) {
                        ref.invalidate(weightStatsProvider);
                        ref.invalidate(weightHistoryProvider);
                        context.showSnackBar('Pesagem excluída.');
                      },
                      (failure) => context.showSnackBar(failure.message, isError: true),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: LoadingWidget()),
          error: (err, _) => Center(
            child: AppErrorWidget(
              message: err.toString(),
              onRetry: () => ref.refresh(weightHistoryProvider),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => LogWeightModal.show(
          context,
          initialWeightKg: historyAsync.value?.isNotEmpty == true
              ? historyAsync.value!.first.weightKg
              : null,
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova Pesagem'),
      ),
    );
  }
}
