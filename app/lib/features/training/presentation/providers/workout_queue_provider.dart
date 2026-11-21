import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/constants/supabase_config.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/presentation/providers/training_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds custom rotating queue order per training plan ID.
/// Keeps the rotating queue non-punitive and user-reorderable, persisting
/// custom order locally via [SharedPreferences] and syncing to Supabase when configured.
class WorkoutQueueNotifier extends StateNotifier<Map<String, List<String>>> {
  WorkoutQueueNotifier({
    SharedPreferences? prefs,
    Future<void> Function(String planId, List<String> orderedIds)? onRemoteSync,
  }) : _prefs = prefs,
       _onRemoteSync = onRemoteSync,
       super(_load(prefs));

  static const String _storageKey = 'liftr_workout_queue_v1';

  final SharedPreferences? _prefs;
  final Future<void> Function(String planId, List<String> orderedIds)?
      _onRemoteSync;

  static Map<String, List<String>> _load(SharedPreferences? prefs) {
    final raw = prefs?.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final result = <String, List<String>>{};
      for (final entry in decoded.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is List) {
          result[key] = value.whereType<String>().toList();
        }
      }
      return result;
    } catch (_) {
      return const {};
    }
  }

  void _saveAndSync(String planId, List<String> orderedIds) {
    state = {
      ...state,
      planId: orderedIds,
    };
    _prefs?.setString(_storageKey, jsonEncode(state));
    final sync = _onRemoteSync;
    if (sync != null) {
      unawaited(sync(planId, orderedIds).catchError((_) {}));
    }
  }

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
    _saveAndSync(planId, list.map((w) => w.id).toList());
  }

  void skipFirstToEnd(String planId, List<Workout> current) {
    if (current.length < 2) return;
    final list = [...current];
    final first = list.removeAt(0);
    list.add(first);
    _saveAndSync(planId, list.map((w) => w.id).toList());
  }

  void selectNext(String planId, List<Workout> current, String workoutId) {
    if (current.isEmpty) return;
    final idx = current.indexWhere((w) => w.id == workoutId);
    if (idx <= 0) return;
    final list = [...current];
    final selected = list.removeAt(idx);
    list.insert(0, selected);
    _saveAndSync(planId, list.map((w) => w.id).toList());
  }
}

final workoutQueueProvider =
    StateNotifierProvider<WorkoutQueueNotifier, Map<String, List<String>>>(
        (ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WorkoutQueueNotifier(
    prefs: prefs,
    onRemoteSync: SupabaseConfig.isConfigured
        ? (planId, orderedIds) => ref
            .read(reorderPlanWorkoutsUseCaseProvider)
            .execute(
              trainingPlanId: planId,
              orderedWorkoutIds: orderedIds,
            )
            .then((_) {})
        : null,
  );
});
