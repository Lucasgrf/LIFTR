import 'dart:io';
import 'dart:math' as math;

import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/network/network_info.dart';
import 'package:personal_fitness_os/core/utils/pt_br_copy_utils.dart';
import 'package:personal_fitness_os/features/history/data/datasources/history_remote_datasource.dart';
import 'package:personal_fitness_os/features/history/domain/entities/exercise_history_record.dart';
import 'package:personal_fitness_os/features/history/domain/entities/history_event_type.dart';
import 'package:personal_fitness_os/features/history/domain/entities/timeline_event.dart';
import 'package:personal_fitness_os/features/history/domain/repositories/history_repository.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_local_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/workout_session_model.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  const HistoryRepositoryImpl(
    this._remoteDataSource, {
    SessionLocalDataSource? localSessionDataSource,
    NetworkInfo? networkInfo,
    bool Function()? isOfflineMode,
    void Function(bool offline)? onConnectivityFallback,
  })  : _localSessionDataSource = localSessionDataSource,
        _networkInfo = networkInfo,
        _isOfflineMode = isOfflineMode,
        _onConnectivityFallback = onConnectivityFallback;

  final HistoryRemoteDataSource _remoteDataSource;
  final SessionLocalDataSource? _localSessionDataSource;
  final NetworkInfo? _networkInfo;
  final bool Function()? _isOfflineMode;
  final void Function(bool offline)? _onConnectivityFallback;

  Future<bool> _shouldUseOffline() async {
    if (_localSessionDataSource == null) return false;
    if (_isOfflineMode?.call() == true) return true;
    if (_networkInfo != null) {
      try {
        final connected = await _networkInfo.isConnected;
        if (!connected) {
          _onConnectivityFallback?.call(true);
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  List<WorkoutSession> _localCompletedSessions() {
    final local = _localSessionDataSource;
    if (local == null) return const [];
    final list = local
        .getAllCachedSessions()
        .where((s) => s.status == 'completed')
        .map((m) => m.toDomain())
        .toList()
      ..sort((a, b) {
        final aDate = a.completedAt ?? a.startedAt;
        final bDate = b.completedAt ?? b.startedAt;
        return bDate.compareTo(aDate);
      });
    return list;
  }

  List<WorkoutSession> _mergeWithLocal(
    List<WorkoutSessionModel> remoteModels,
  ) {
    final byId = <String, WorkoutSession>{};
    for (final m in remoteModels) {
      final d = m.toDomain();
      byId[d.id] = d;
    }
    // Local cache preserves unsynced or more richly hydrated sessions.
    for (final localSession in _localCompletedSessions()) {
      final existing = byId[localSession.id];
      if (existing == null ||
          (existing.exercises.isEmpty && localSession.exercises.isNotEmpty) ||
          localSession.totalWorkingSetsCount > existing.totalWorkingSetsCount) {
        byId[localSession.id] = localSession;
      }
    }
    final merged = byId.values.toList()
      ..sort((a, b) {
        final aDate = a.completedAt ?? a.startedAt;
        final bDate = b.completedAt ?? b.startedAt;
        return bDate.compareTo(aDate);
      });
    return merged;
  }

  List<ExerciseHistoryRecord> _localExerciseHistory(
    String exerciseId, {
    int limit = 30,
  }) {
    final records = <ExerciseHistoryRecord>[];
    for (final session in _localCompletedSessions()) {
      for (final se in session.exercises) {
        if (se.exerciseId != exerciseId || se.sets.isEmpty) continue;
        double maxWeight = 0.0;
        int maxReps = 0;
        double max1Rm = 0.0;
        for (final s in se.sets) {
          if (s.weightKg > maxWeight) maxWeight = s.weightKg;
          if (s.repsCompleted > maxReps) maxReps = s.repsCompleted;
          final est = s.weightKg * (1.0 + s.repsCompleted / 30.0);
          if (est > max1Rm) max1Rm = est;
        }
        records.add(
          ExerciseHistoryRecord(
            sessionId: session.id,
            sessionName: session.workoutName,
            date: session.completedAt ?? session.startedAt,
            setsCount: se.sets.length,
            topWeightKg: maxWeight,
            topReps: maxReps,
            bestEstimated1Rm: max1Rm,
          ),
        );
      }
    }
    records.sort((a, b) => b.date.compareTo(a.date));
    return records.length > limit ? records.sublist(0, limit) : records;
  }

  Future<Result<T, Failure>> _guard<T>(
    Future<T> Function() call,
    String fallbackMessage, {
    T Function()? onOfflineFallback,
  }) async {
    if (onOfflineFallback != null && await _shouldUseOffline()) {
      try {
        return Success(onOfflineFallback());
      } catch (e, stack) {
        return Err(
          CacheFailure('Erro ao ler histórico no cache local: $e', stack),
        );
      }
    }
    try {
      final data = await call();
      return Success(data);
    } on AuthException catch (e, stack) {
      return Err(AuthFailure(e.message, stack));
    } on PostgrestException catch (e, stack) {
      if (onOfflineFallback != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        try {
          return Success(onOfflineFallback());
        } catch (cacheErr, cacheStack) {
          return Err(
            CacheFailure(
              'Erro ao ler histórico no cache local: $cacheErr',
              cacheStack,
            ),
          );
        }
      }
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (onOfflineFallback != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        try {
          return Success(onOfflineFallback());
        } catch (cacheErr, cacheStack) {
          return Err(
            CacheFailure(
              'Erro ao ler histórico no cache local: $cacheErr',
              cacheStack,
            ),
          );
        }
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(UnexpectedFailure('$fallbackMessage: $e', stack));
    }
  }

  @override
  Future<Result<List<WorkoutSession>, Failure>> getCompletedSessions({
    int limit = 50,
    int offset = 0,
  }) {
    return _guard(
      () async {
        final models = await _remoteDataSource.fetchCompletedSessions(
          limit: limit,
          offset: offset,
        );
        final local = _localSessionDataSource;
        if (local != null && offset == 0) {
          for (final model in models.take(20)) {
            await local.saveSession(model);
          }
        }
        final merged = offset == 0
            ? _mergeWithLocal(models)
            : models.map((m) => m.toDomain()).toList();
        return merged.length > limit ? merged.sublist(0, limit) : merged;
      },
      'Erro ao carregar histórico de treinos',
      onOfflineFallback: _localSessionDataSource != null
          ? () {
              final localList = _localCompletedSessions();
              if (offset >= localList.length) return const [];
              final end = math.min(offset + limit, localList.length);
              return localList.sublist(offset, end);
            }
          : null,
    );
  }

  @override
  Future<Result<List<WorkoutSession>, Failure>> getSessionsInRange({
    required DateTime start,
    required DateTime end,
  }) {
    List<WorkoutSession> localInRange() {
      return _localCompletedSessions().where((s) {
        final d = s.completedAt ?? s.startedAt;
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList();
    }

    return _guard(
      () async {
        final models = await _remoteDataSource.fetchSessionsInRange(
          start: start,
          end: end,
        );
        final merged = _mergeWithLocal(models).where((s) {
          final d = s.completedAt ?? s.startedAt;
          return !d.isBefore(start) && !d.isAfter(end);
        }).toList()
          ..sort((a, b) {
            final aDate = a.completedAt ?? a.startedAt;
            final bDate = b.completedAt ?? b.startedAt;
            return aDate.compareTo(bDate);
          });
        return merged;
      },
      'Erro ao carregar dados do período',
      onOfflineFallback:
          _localSessionDataSource != null ? localInRange : null,
    );
  }

  @override
  Future<Result<List<TimelineEvent>, Failure>> getUnifiedTimeline({
    HistoryEventType? type,
    DateTime? start,
    DateTime? end,
    int limit = 50,
  }) {
    return _guard(
      () => _remoteDataSource.fetchUnifiedTimeline(
        type: type,
        start: start,
        end: end,
        limit: limit,
      ),
      'Erro ao carregar linha do tempo unificada',
      onOfflineFallback: _localSessionDataSource != null
          ? () {
              if (type != null && type != HistoryEventType.workout) {
                return const [];
              }
              return _localCompletedSessions()
                  .where((s) {
                    final d = s.completedAt ?? s.startedAt;
                    if (start != null && d.isBefore(start)) return false;
                    if (end != null && d.isAfter(end)) return false;
                    return true;
                  })
                  .take(limit)
                  .map(
                    (s) => TimelineEvent(
                      id: 'ws-${s.id}',
                      type: HistoryEventType.workout,
                      timestamp: s.completedAt ?? s.startedAt,
                      title: s.workoutName,
                      subtitle:
                          '${pluralize(s.exercises.length, 'exercício', 'exercícios')} • ${s.durationSeconds ~/ 60} min',
                      referenceId: s.id,
                      metadata: {'durationSeconds': s.durationSeconds},
                    ),
                  )
                  .toList();
            }
          : null,
    );
  }

  @override
  Future<Result<List<ExerciseHistoryRecord>, Failure>> getExerciseHistory(
    String exerciseId, {
    int limit = 30,
  }) {
    return _guard(
      () => _remoteDataSource.fetchExerciseHistory(
        exerciseId,
        limit: limit,
      ),
      'Erro ao carregar histórico do exercício',
      onOfflineFallback: _localSessionDataSource != null
          ? () => _localExerciseHistory(exerciseId, limit: limit)
          : null,
    );
  }
}
