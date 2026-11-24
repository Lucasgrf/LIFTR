import 'dart:convert';

import 'package:personal_fitness_os/features/training/data/models/training_plan_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-first local cache for training plans (including workouts, exercises,
/// and set templates), scoped per authenticated [userId].
class TrainingLocalDataSource {
  TrainingLocalDataSource(
    this._prefs, {
    this.userId,
  });

  static const String _plansKey = 'liftr_cached_training_plans_v1';

  final SharedPreferences _prefs;
  final String? userId;

  String get _effectivePlansKey {
    final trimmed = userId?.trim() ?? '';
    if (trimmed.isEmpty) return _plansKey;
    return '${_plansKey}_$trimmed';
  }

  bool _belongsToActiveUser(TrainingPlanModel plan) {
    final active = userId?.trim() ?? '';
    if (active.isEmpty) return true;
    final owner = plan.userId.trim();
    if (owner.isEmpty || owner == 'offline_user') return true;
    return owner == active;
  }

  Map<String, Map<String, dynamic>> _readPlansMap() {
    final raw = _prefs.getString(_effectivePlansKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <String, Map<String, dynamic>>{};
      for (final entry in decoded.entries) {
        if (entry.key is String && entry.value is Map) {
          result[entry.key as String] =
              Map<String, dynamic>.from(entry.value as Map);
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> _writePlansMap(Map<String, Map<String, dynamic>> map) async {
    await _prefs.setString(_effectivePlansKey, jsonEncode(map));
  }

  Future<void> savePlans(List<TrainingPlanModel> plans) async {
    final map = <String, Map<String, dynamic>>{};
    for (final plan in plans) {
      if (_belongsToActiveUser(plan) && plan.deletedAt == null) {
        map[plan.id] = plan.toFullJson();
      }
    }
    await _writePlansMap(map);
  }

  Future<void> savePlan(TrainingPlanModel plan) async {
    if (!_belongsToActiveUser(plan)) return;
    final map = _readPlansMap();
    if (plan.isActive) {
      for (final key in map.keys.toList()) {
        if (key != plan.id) {
          map[key] = {...map[key]!, 'is_active': false};
        }
      }
    }
    if (plan.deletedAt != null) {
      map.remove(plan.id);
    } else {
      map[plan.id] = plan.toFullJson();
    }
    await _writePlansMap(map);
  }

  Future<void> removePlan(String planId) async {
    final map = _readPlansMap();
    map.remove(planId);
    await _writePlansMap(map);
  }

  List<TrainingPlanModel> getAllPlans() {
    final map = _readPlansMap();
    final plans = <TrainingPlanModel>[];
    for (final json in map.values) {
      try {
        final model = TrainingPlanModel.fromJson(json);
        if (_belongsToActiveUser(model) && model.deletedAt == null) {
          plans.add(model);
        }
      } catch (_) {}
    }
    plans.sort((a, b) {
      if (a.isActive != b.isActive) {
        return a.isActive ? -1 : 1;
      }
      final aDate = a.createdAt ?? DateTime(2000);
      final bDate = b.createdAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return plans;
  }

  TrainingPlanModel? getActivePlan() {
    final plans = getAllPlans();
    return plans.where((p) => p.isActive).firstOrNull;
  }

  TrainingPlanModel? getPlanById(String id) {
    final map = _readPlansMap();
    final json = map[id];
    if (json == null) return null;
    try {
      final model = TrainingPlanModel.fromJson(json);
      if (!_belongsToActiveUser(model) || model.deletedAt != null) return null;
      return model;
    } catch (_) {
      return null;
    }
  }
}
