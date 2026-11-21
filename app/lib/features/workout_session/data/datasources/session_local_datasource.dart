import 'dart:convert';

import 'package:personal_fitness_os/features/workout_session/data/models/workout_session_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PendingSessionOpType {
  startSession,
  logSet,
  updateSet,
  deleteSet,
  addExercise,
  swapExercise,
  finishSession,
  abandonSession,
}

class PendingSessionOp {
  const PendingSessionOp({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final PendingSessionOpType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PendingSessionOp.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'logSet';
    final parsedType = PendingSessionOpType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => PendingSessionOpType.logSet,
    );
    return PendingSessionOp(
      id: json['id'] as String,
      type: parsedType,
      payload: Map<String, dynamic>.from(
        json['payload'] as Map? ?? const {},
      ),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Offline-first local cache and outbox queue for workout sessions backed by
/// [SharedPreferences].
class SessionLocalDataSource {
  SessionLocalDataSource(this._prefs);

  static const String _sessionsKey = 'liftr_cached_sessions_v1';
  static const String _outboxKey = 'liftr_session_outbox_v1';

  final SharedPreferences _prefs;

  Map<String, Map<String, dynamic>> _readSessionsMap() {
    final raw = _prefs.getString(_sessionsKey);
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

  Future<void> _writeSessionsMap(Map<String, Map<String, dynamic>> map) async {
    // Retain up to 20 most recent sessions to bound storage size.
    if (map.length > 20) {
      final entries = map.entries.toList()
        ..sort((a, b) {
          final aTime = a.value['started_at'] as String? ?? '';
          final bTime = b.value['started_at'] as String? ?? '';
          return bTime.compareTo(aTime);
        });
      map = {for (final e in entries.take(20)) e.key: e.value};
    }
    await _prefs.setString(_sessionsKey, jsonEncode(map));
  }

  Future<void> saveSession(WorkoutSessionModel session) async {
    final map = _readSessionsMap();
    map[session.id] = session.toFullJson();
    await _writeSessionsMap(map);
  }

  WorkoutSessionModel? getSessionById(String sessionId) {
    final map = _readSessionsMap();
    final json = map[sessionId];
    if (json == null) return null;
    try {
      return WorkoutSessionModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  List<WorkoutSessionModel> getAllCachedSessions() {
    final map = _readSessionsMap();
    final sessions = <WorkoutSessionModel>[];
    for (final json in map.values) {
      try {
        sessions.add(WorkoutSessionModel.fromJson(json));
      } catch (_) {}
    }
    return sessions;
  }

  WorkoutSessionModel? getActiveSession() {
    final sessions = getAllCachedSessions()
        .where((s) => s.status == 'in_progress')
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions.firstOrNull;
  }

  WorkoutSessionModel? getLastCompletedSession() {
    final sessions = getAllCachedSessions()
        .where((s) => s.status == 'completed')
        .toList()
      ..sort((a, b) {
        final aDate = a.completedAt ?? a.startedAt;
        final bDate = b.completedAt ?? b.startedAt;
        return bDate.compareTo(aDate);
      });
    return sessions.firstOrNull;
  }

  List<PendingSessionOp> getPendingOps() {
    final raw = _prefs.getString(_outboxKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => PendingSessionOp.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  int get pendingCount => getPendingOps().length;

  Future<void> _writeOps(List<PendingSessionOp> ops) async {
    await _prefs.setString(
      _outboxKey,
      jsonEncode(ops.map((o) => o.toJson()).toList()),
    );
  }

  Future<void> enqueueOp(PendingSessionOp op) async {
    final ops = getPendingOps();
    ops.add(op);
    await _writeOps(ops);
  }

  Future<void> removeOp(String opId) async {
    final ops = getPendingOps()..removeWhere((o) => o.id == opId);
    await _writeOps(ops);
  }

  /// If a set was logged offline and deleted before sync, drop its pending
  /// `logSet`/`updateSet` ops directly and return `true` so no remote delete is needed.
  Future<bool> cancelPendingSetOpsIfUnsynced(String setId) async {
    final ops = getPendingOps();
    final hasUnsyncedInsert = ops.any(
      (o) => o.type == PendingSessionOpType.logSet && o.payload['id'] == setId,
    );
    if (!hasUnsyncedInsert) return false;
    ops.removeWhere(
      (o) =>
          (o.type == PendingSessionOpType.logSet &&
              o.payload['id'] == setId) ||
          (o.type == PendingSessionOpType.updateSet &&
              o.payload['set_id'] == setId),
    );
    await _writeOps(ops);
    return true;
  }
}
