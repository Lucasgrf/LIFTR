import 'dart:convert';

import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/features/weekly_comparison/data/models/cardio_log_model.dart';
import 'package:personal_fitness_os/features/weekly_comparison/data/models/weekly_snapshot_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-first local cache for standalone cardio logs and weekly snapshots.
class WeeklyComparisonLocalDataSource {
  WeeklyComparisonLocalDataSource(this._prefs);

  static const String _cardioLogsKey = 'liftr_cardio_logs_v1';
  static const String _weeklySnapshotsKey = 'liftr_weekly_snapshots_v1';

  final SharedPreferences _prefs;

  List<CardioLogModel> getAllCardioLogs() {
    final raw = _prefs.getString(_cardioLogsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => CardioLogModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveCardioLog(CardioLogModel log) async {
    final existing = getAllCardioLogs().where((c) => c.id != log.id).toList();
    existing.add(log);
    existing.sort((a, b) => b.performedAt.compareTo(a.performedAt));
    final trimmed = existing.take(120).toList();
    await _prefs.setString(
      _cardioLogsKey,
      jsonEncode(trimmed.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> saveAllCardioLogsInRange({
    required DateTime start,
    required DateTime end,
    required List<CardioLogModel> remoteLogs,
  }) async {
    final outside = getAllCardioLogs().where((c) {
      return c.performedAt.isBefore(start) || c.performedAt.isAfter(end);
    }).toList();
    final combined = [...outside, ...remoteLogs]
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    final seen = <String>{};
    final deduped = combined.where((c) => seen.add(c.id)).take(120).toList();
    await _prefs.setString(
      _cardioLogsKey,
      jsonEncode(deduped.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> deleteCardioLog(String id) async {
    final filtered = getAllCardioLogs().where((c) => c.id != id).toList();
    await _prefs.setString(
      _cardioLogsKey,
      jsonEncode(filtered.map((c) => c.toJson()).toList()),
    );
  }

  List<CardioLogModel> getCardioLogsInRange({
    required DateTime start,
    required DateTime end,
  }) {
    return getAllCardioLogs()
        .where(
          (c) => !c.performedAt.isBefore(start) && !c.performedAt.isAfter(end),
        )
        .toList()
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
  }

  List<WeeklySnapshotModel> getRecentWeeklySnapshots() {
    final raw = _prefs.getString(_weeklySnapshotsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final list = decoded
          .whereType<Map>()
          .map(
            (e) =>
                WeeklySnapshotModel.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList()
        ..sort((a, b) => b.weekStart.compareTo(a.weekStart));
      return list;
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveWeeklySnapshot(WeeklySnapshotModel snapshot) async {
    final key = isoDateKey(snapshot.weekStart);
    final others = getRecentWeeklySnapshots()
        .where((s) => isoDateKey(s.weekStart) != key)
        .toList();
    others.add(snapshot);
    others.sort((a, b) => b.weekStart.compareTo(a.weekStart));
    await _prefs.setString(
      _weeklySnapshotsKey,
      jsonEncode(others.take(24).map((s) => s.toJson()).toList()),
    );
  }

  Future<void> saveWeeklySnapshots(List<WeeklySnapshotModel> snapshots) async {
    final map = <String, WeeklySnapshotModel>{};
    for (final s in getRecentWeeklySnapshots()) {
      map[isoDateKey(s.weekStart)] = s;
    }
    for (final s in snapshots) {
      map[isoDateKey(s.weekStart)] = s;
    }
    final sorted = map.values.toList()
      ..sort((a, b) => b.weekStart.compareTo(a.weekStart));
    await _prefs.setString(
      _weeklySnapshotsKey,
      jsonEncode(sorted.take(24).map((s) => s.toJson()).toList()),
    );
  }
}
