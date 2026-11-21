import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';

/// Holds custom rotating queue order per training plan ID.
/// Keeps the rotating queue non-punitive and user-reorderable without breaking
/// domain persistence contracts.
class WorkoutQueueNotifier extends StateNotifier<Map<String, List<String>>> {
  WorkoutQueueNotifier() : super(const {});

  List<Workout> orderedWorkouts(String planId, List<Workout> workouts) {
    if (workouts.isEmpty) return const [];
    final customOrder = state[planId];
    if (customOrder == null || customOrder.isEmpty) {
      final sorted = [...workouts]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return sorted;
    }

    final byId = {for (final w in workouts) w.id: w};
    final ordered = <Workout>[];
    for (final id in customOrder) {
      final match = byId.remove(id);
      if (match != null) ordered.add(match);
    }
    if (byId.isNotEmpty) {
      final remaining = byId.values.toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      ordered.addAll(remaining);
    }
    return ordered;
  }

  void reorder(
    String planId,
    List<Workout> current,
    int oldIndex,
    int newIndex,
  ) {
    if (current.length < 2) return;
    final list = [...current];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);
    state = {
      ...state,
      planId: list.map((w) => w.id).toList(),
    };
  }

  void skipFirstToEnd(String planId, List<Workout> current) {
    if (current.length < 2) return;
    final list = [...current];
    final first = list.removeAt(0);
    list.add(first);
    state = {
      ...state,
      planId: list.map((w) => w.id).toList(),
    };
  }

  void selectNext(String planId, List<Workout> current, String workoutId) {
    if (current.isEmpty) return;
    final idx = current.indexWhere((w) => w.id == workoutId);
    if (idx <= 0) return;
    final list = [...current];
    final selected = list.removeAt(idx);
    list.insert(0, selected);
    state = {
      ...state,
      planId: list.map((w) => w.id).toList(),
    };
  }
}

final workoutQueueProvider =
    StateNotifierProvider<WorkoutQueueNotifier, Map<String, List<String>>>(
        (ref) {
  return WorkoutQueueNotifier();
});
