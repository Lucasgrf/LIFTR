import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/features/history/domain/entities/history_event_type.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';

class TimelineFilterBar extends ConsumerWidget {
  const TimelineFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeType = ref.watch(timelineFilterTypeProvider);
    final activeDays = ref.watch(timelineFilterDaysProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: activeType == null,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(timelineFilterTypeProvider.notifier).state = null;
                  }
                },
              ),
              ...HistoryEventType.values.map((type) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(type.label),
                    selected: activeType == type,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(timelineFilterTypeProvider.notifier).state = type;
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Period filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Tudo'),
                selected: activeDays == null,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(timelineFilterDaysProvider.notifier).state = null;
                  }
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('7 dias'),
                selected: activeDays == 7,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(timelineFilterDaysProvider.notifier).state = 7;
                  }
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('30 dias'),
                selected: activeDays == 30,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(timelineFilterDaysProvider.notifier).state = 30;
                  }
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('90 dias'),
                selected: activeDays == 90,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(timelineFilterDaysProvider.notifier).state = 90;
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
