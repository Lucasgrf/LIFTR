import 'dart:convert';

import 'package:personal_fitness_os/features/exercise_library/data/models/exercise_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-first local cache for the exercise library catalog, scoped per
/// authenticated [userId] so custom exercises stay isolated per account.
class ExerciseLocalDataSource {
  ExerciseLocalDataSource(
    this._prefs, {
    this.userId,
  });

  static const String _exercisesKey = 'liftr_cached_exercises_v1';

  final SharedPreferences _prefs;
  final String? userId;

  String get _effectiveKey {
    final trimmed = userId?.trim() ?? '';
    if (trimmed.isEmpty) return _exercisesKey;
    return '${_exercisesKey}_$trimmed';
  }

  Future<void> saveExercises(List<ExerciseModel> exercises) async {
    final payload = exercises
        .where((e) => e.deletedAt == null)
        .map((e) => e.toJson())
        .toList();
    await _prefs.setString(_effectiveKey, jsonEncode(payload));
  }

  Future<void> upsertExercise(ExerciseModel exercise) async {
    final current = getExercises();
    final idx = current.indexWhere((e) => e.id == exercise.id);
    if (idx >= 0) {
      current[idx] = exercise;
    } else {
      current.add(exercise);
    }
    current.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await saveExercises(current);
  }

  List<ExerciseModel> getExercises() {
    final raw = _prefs.getString(_effectiveKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final items = <ExerciseModel>[];
      for (final entry in decoded) {
        if (entry is Map) {
          try {
            final model =
                ExerciseModel.fromJson(Map<String, dynamic>.from(entry));
            if (model.deletedAt == null) {
              items.add(model);
            }
          } catch (_) {}
        }
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  ExerciseModel? getExerciseById(String id) {
    for (final ex in getExercises()) {
      if (ex.id == id) return ex;
    }
    return null;
  }
}
