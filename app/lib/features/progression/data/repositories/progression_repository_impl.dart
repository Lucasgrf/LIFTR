import 'dart:io';

import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/network/network_info.dart';
import 'package:personal_fitness_os/features/progression/data/datasources/progression_remote_datasource.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/progression/domain/repositories/progression_repository.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_local_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressionRepositoryImpl implements ProgressionRepository {
  const ProgressionRepositoryImpl(
    this._remoteDataSource, {
    SessionLocalDataSource? localSessionDataSource,
    NetworkInfo? networkInfo,
    bool Function()? isOfflineMode,
    void Function(bool offline)? onConnectivityFallback,
  })  : _localSessionDataSource = localSessionDataSource,
        _networkInfo = networkInfo,
        _isOfflineMode = isOfflineMode,
        _onConnectivityFallback = onConnectivityFallback;

  final ProgressionRemoteDataSource _remoteDataSource;
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

  List<ExercisePerformanceHistory> _getLocalPerformances(
    String exerciseId, {
    int limit = 2,
  }) {
    final local = _localSessionDataSource;
    if (local == null) return const [];
    final completed = local
        .getAllCachedSessions()
        .where((s) => s.status == 'completed')
        .map((m) => m.toDomain())
        .toList()
      ..sort((a, b) {
        final aDate = a.completedAt ?? a.startedAt;
        final bDate = b.completedAt ?? b.startedAt;
        return bDate.compareTo(aDate);
      });

    final results = <ExercisePerformanceHistory>[];
    for (final session in completed) {
      for (final se in session.exercises) {
        if (se.exerciseId == exerciseId && se.sets.isNotEmpty) {
          results.add(
            ExercisePerformanceHistory(
              exerciseId: exerciseId,
              workoutSessionId: session.id,
              workoutName: session.workoutName,
              date: session.completedAt ?? session.startedAt,
              loggedSets: se.sets,
            ),
          );
          break;
        }
      }
      if (results.length >= limit) break;
    }
    return results;
  }

  ExercisePerformanceHistory? _getLocalPerformance(String exerciseId) {
    final list = _getLocalPerformances(exerciseId, limit: 1);
    return list.isEmpty ? null : list.first;
  }

  List<ExercisePerformanceHistory> _mergePerformances(
    List<ExercisePerformanceHistory> remote,
    List<ExercisePerformanceHistory> local,
    int limit,
  ) {
    final bySessionId = <String, ExercisePerformanceHistory>{};
    for (final h in remote) {
      bySessionId[h.workoutSessionId] = h;
    }
    for (final h in local) {
      final existing = bySessionId[h.workoutSessionId];
      if (existing == null || h.date.isAfter(existing.date)) {
        bySessionId[h.workoutSessionId] = h;
      }
    }
    final merged = bySessionId.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return merged.take(limit).toList();
  }

  @override
  Future<Result<ExercisePerformanceHistory?, Failure>> getLastExercisePerformance(
    String exerciseId,
  ) async {
    if (_localSessionDataSource != null && await _shouldUseOffline()) {
      return Success(_getLocalPerformance(exerciseId));
    }

    try {
      final history =
          await _remoteDataSource.fetchLastExercisePerformance(exerciseId);
      final localHistory = _getLocalPerformance(exerciseId);
      if (localHistory != null &&
          (history == null || localHistory.date.isAfter(history.date))) {
        return Success(localHistory);
      }
      return Success(history);
    } on AuthException catch (e, stack) {
      return Err(AuthFailure(e.message, stack));
    } on PostgrestException catch (e, stack) {
      if (_localSessionDataSource != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        return Success(_getLocalPerformance(exerciseId));
      }
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (_localSessionDataSource != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        return Success(_getLocalPerformance(exerciseId));
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(UnexpectedFailure('Erro ao buscar histórico de progressão: $e', stack));
    }
  }

  @override
  Future<Result<List<ExercisePerformanceHistory>, Failure>>
      getRecentExercisePerformances(
    String exerciseId, {
    int limit = 2,
  }) async {
    if (_localSessionDataSource != null && await _shouldUseOffline()) {
      return Success(_getLocalPerformances(exerciseId, limit: limit));
    }

    try {
      final remote = await _remoteDataSource.fetchRecentExercisePerformances(
        exerciseId,
        limit: limit,
      );
      final local = _getLocalPerformances(exerciseId, limit: limit);
      return Success(_mergePerformances(remote, local, limit));
    } on AuthException catch (e, stack) {
      return Err(AuthFailure(e.message, stack));
    } on PostgrestException catch (e, stack) {
      if (_localSessionDataSource != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        return Success(_getLocalPerformances(exerciseId, limit: limit));
      }
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (_localSessionDataSource != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        return Success(_getLocalPerformances(exerciseId, limit: limit));
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(UnexpectedFailure('Erro ao buscar histórico recente de progressão: $e', stack));
    }
  }
}
