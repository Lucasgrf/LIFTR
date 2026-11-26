import 'dart:io';

import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/network/network_info.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_local_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_remote_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/logged_set_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/session_exercise_model.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/workout_session_model.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(
    this._remoteDataSource, {
    SessionLocalDataSource? localDataSource,
    NetworkInfo? networkInfo,
    bool Function()? isOfflineMode,
    void Function(bool offline)? onConnectivityFallback,
    void Function(int count)? onPendingCountChanged,
  })  : _localDataSource = localDataSource,
        _networkInfo = networkInfo,
        _isOfflineMode = isOfflineMode,
        _onConnectivityFallback = onConnectivityFallback,
        _onPendingCountChanged = onPendingCountChanged;

  final SessionRemoteDataSource _remoteDataSource;
  final SessionLocalDataSource? _localDataSource;
  final NetworkInfo? _networkInfo;
  final bool Function()? _isOfflineMode;
  final void Function(bool offline)? _onConnectivityFallback;
  final void Function(int count)? _onPendingCountChanged;

  static const _uuid = Uuid();

  Future<bool> _shouldUseOffline() async {
    if (_localDataSource == null) return false;
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

  void _notifyPendingCount() {
    final local = _localDataSource;
    if (local == null) return;
    _onPendingCountChanged?.call(local.pendingCount);
  }

  WorkoutSessionModel _mergePrescribedTargets(
    WorkoutSessionModel remote, {
    List<SessionExercise>? initialExercises,
    WorkoutSessionModel? cached,
  }) {
    final mergedExercises = remote.exercises.map((se) {
      SessionExercise? initMatch;
      if (initialExercises != null) {
        initMatch = initialExercises
                .where(
                  (i) =>
                      i.exerciseId == se.exerciseId &&
                      i.sortOrder == se.sortOrder,
                )
                .firstOrNull ??
            initialExercises
                .where((i) => i.exerciseId == se.exerciseId)
                .firstOrNull;
      }

      final cachedMatch = cached?.exercises
          .where((c) => c.id == se.id)
          .firstOrNull;

      final resolvedExercise = se.exercise ??
          (initMatch?.exercise != null
              ? cachedMatch?.exercise ??
                  SessionExerciseModel.fromDomain(initMatch!).exercise
              : cachedMatch?.exercise);

      final hasRemoteTemplate = se.prescribedSetTypes.isNotEmpty;

      if (initMatch != null) {
        return se.copyWith(
          exercise: resolvedExercise,
          targetRestSeconds: initMatch.targetRestSeconds,
          targetSetsCount: initMatch.targetSetsCount,
          targetRepsMin: initMatch.targetRepsMin,
          targetRepsMax: initMatch.targetRepsMax,
          targetRir: initMatch.targetRir,
          prescribedSetTypes: initMatch.prescribedSetTypes.isNotEmpty
              ? initMatch.prescribedSetTypes
              : se.prescribedSetTypes,
        );
      }

      if (!hasRemoteTemplate && cachedMatch != null) {
        return se.copyWith(
          exercise: resolvedExercise,
          targetRestSeconds: cachedMatch.targetRestSeconds,
          targetSetsCount: cachedMatch.targetSetsCount,
          targetRepsMin: cachedMatch.targetRepsMin,
          targetRepsMax: cachedMatch.targetRepsMax,
          targetRir: cachedMatch.targetRir,
          prescribedSetTypes: cachedMatch.prescribedSetTypes,
        );
      }

      return resolvedExercise != se.exercise
          ? se.copyWith(exercise: resolvedExercise)
          : se;
    }).toList();

    return remote.copyWith(exercises: mergedExercises);
  }

  Future<WorkoutSessionModel> _startSessionOffline({
    String? workoutId,
    String? workoutName,
    List<SessionExercise>? initialExercises,
  }) async {
    final local = _localDataSource!;
    final now = DateTime.now();
    final sessionId = _uuid.v4();
    final exercises = [
      for (var i = 0; i < (initialExercises?.length ?? 0); i++)
        SessionExerciseModel.fromDomain(
          initialExercises![i].copyWith(
            id: _uuid.v4(),
            sessionId: sessionId,
            sortOrder: i,
          ),
        ),
    ];

    final model = WorkoutSessionModel(
      id: sessionId,
      userId: 'offline_user',
      workoutId: workoutId,
      workoutName: workoutName ?? 'Treino Avulso',
      startedAt: now,
      status: 'in_progress',
      exercises: exercises,
      createdAt: now,
    );

    await local.saveSession(model);
    await local.enqueueOp(
      PendingSessionOp(
        id: _uuid.v4(),
        type: PendingSessionOpType.startSession,
        payload: {
          'session': {
            'id': sessionId,
            if (workoutId != null) 'workout_id': workoutId,
            if (workoutName != null) 'workout_name': workoutName,
            'started_at': now.toIso8601String(),
            'status': 'in_progress',
          },
          'exercises': exercises
              .map(
                (ex) => {
                  'id': ex.id,
                  'session_id': sessionId,
                  'exercise_id': ex.exerciseId,
                  'sort_order': ex.sortOrder,
                  if (ex.notes != null) 'notes': ex.notes,
                  'target_sets_count': ex.targetSetsCount,
                  'target_reps_min': ex.targetRepsMin,
                  'target_reps_max': ex.targetRepsMax,
                  'target_rir': ex.targetRir,
                  'target_rest_seconds': ex.targetRestSeconds,
                },
              )
              .toList(),
        },
        createdAt: now,
      ),
    );
    _notifyPendingCount();
    return model;
  }

  Future<void> _upsertSetInCache(
    String sessionExerciseId,
    LoggedSetModel setModel,
  ) async {
    final local = _localDataSource;
    if (local == null) return;
    for (final session in local.getAllCachedSessions()) {
      var changed = false;
      final nextExercises = session.exercises.map((se) {
        if (se.id != sessionExerciseId) return se;
        changed = true;
        final existingIdx = se.sets.indexWhere((s) => s.id == setModel.id);
        final nextSets = [...se.sets];
        if (existingIdx >= 0) {
          nextSets[existingIdx] = setModel;
        } else {
          nextSets.add(setModel);
        }
        nextSets.sort((a, b) => a.setNumber.compareTo(b.setNumber));
        return se.copyWith(sets: nextSets);
      }).toList();
      if (changed) {
        await local.saveSession(session.copyWith(exercises: nextExercises));
        return;
      }
    }
  }

  Future<void> _removeSetFromCache(String setId) async {
    final local = _localDataSource;
    if (local == null) return;
    for (final session in local.getAllCachedSessions()) {
      var changed = false;
      final nextExercises = session.exercises.map((se) {
        final filtered = se.sets.where((s) => s.id != setId).toList();
        if (filtered.length != se.sets.length) {
          changed = true;
          return se.copyWith(sets: filtered);
        }
        return se;
      }).toList();
      if (changed) {
        await local.saveSession(session.copyWith(exercises: nextExercises));
        return;
      }
    }
  }

  Future<SessionExerciseModel?> _swapExerciseInCache({
    required String sessionExerciseId,
    required String newExerciseId,
    String? replacedExerciseId,
  }) async {
    final local = _localDataSource;
    if (local == null) return null;
    for (final session in local.getAllCachedSessions()) {
      SessionExerciseModel? updated;
      final nextExercises = session.exercises.map((se) {
        if (se.id != sessionExerciseId) return se;
        updated = se.copyWith(
          exerciseId: newExerciseId,
          replacedExerciseId: replacedExerciseId ?? se.replacedExerciseId,
        );
        return updated!;
      }).toList();
      if (updated != null) {
        await local.saveSession(session.copyWith(exercises: nextExercises));
        return updated;
      }
    }
    return null;
  }

  /// Flushes locally queued workout operations to Supabase in FIFO order.
  /// Returns true if all operations were synced (or queue was empty).
  Future<bool> syncPendingOperations() async {
    final local = _localDataSource;
    if (local == null) return true;
    final ops = local.getPendingOps();
    if (ops.isEmpty) {
      _notifyPendingCount();
      return true;
    }

    if (_isOfflineMode?.call() == true && _networkInfo != null) {
      try {
        if (!(await _networkInfo.isConnected)) return false;
      } catch (_) {
        return false;
      }
    }

    while (true) {
      final ops = local.getPendingOps();
      if (ops.isEmpty) break;

      for (final op in ops) {
        if (!local.hasPendingOp(op.id)) continue;
        local.markOpInFlight(op);
        try {
          switch (op.type) {
            case PendingSessionOpType.startSession:
              final sessionPayload = Map<String, dynamic>.from(
                op.payload['session'] as Map? ?? const {},
              );
              try {
                await _remoteDataSource.insertSession(sessionPayload);
              } on PostgrestException catch (e) {
                if (e.code != '23505') rethrow;
              }
              final exList =
                  (op.payload['exercises'] as List<dynamic>?) ?? const [];
              for (final exRaw in exList) {
                if (exRaw is Map) {
                  try {
                    await _remoteDataSource.insertSessionExercise(
                      Map<String, dynamic>.from(exRaw),
                    );
                  } on PostgrestException catch (e) {
                    if (e.code != '23505') rethrow;
                  }
                }
              }
              break;

            case PendingSessionOpType.logSet:
              try {
                await _remoteDataSource.insertLoggedSet(op.payload);
              } on PostgrestException catch (e) {
                if (e.code != '23505') rethrow;
              }
              break;

            case PendingSessionOpType.updateSet:
              final setId = op.payload['set_id'] as String?;
              final data = Map<String, dynamic>.from(
                op.payload['data'] as Map? ?? const {},
              );
              if (setId != null) {
                await _remoteDataSource.updateLoggedSet(setId, data);
              }
              break;

            case PendingSessionOpType.deleteSet:
              final setId = op.payload['set_id'] as String?;
              if (setId != null) {
                await _remoteDataSource.deleteLoggedSet(setId);
              }
              break;

            case PendingSessionOpType.addExercise:
              try {
                await _remoteDataSource.insertSessionExercise(op.payload);
              } on PostgrestException catch (e) {
                if (e.code != '23505') rethrow;
              }
              break;

            case PendingSessionOpType.swapExercise:
              final seId = op.payload['session_exercise_id'] as String?;
              final data = Map<String, dynamic>.from(
                op.payload['data'] as Map? ?? const {},
              );
              if (seId != null) {
                await _remoteDataSource.updateSessionExercise(seId, data);
              }
              break;

            case PendingSessionOpType.finishSession:
            case PendingSessionOpType.abandonSession:
              final sessionId = op.payload['session_id'] as String?;
              final data = Map<String, dynamic>.from(
                op.payload['data'] as Map? ?? const {},
              );
              if (sessionId != null) {
                await _remoteDataSource.updateSession(sessionId, data);
              }
              break;
          }
          await local.removeOp(op.id);
        } catch (e) {
          if (isNetworkError(e)) {
            _onConnectivityFallback?.call(true);
            _notifyPendingCount();
            return false;
          }
          // Keep other errors isolated; stop further dependent ops for safety.
          _notifyPendingCount();
          return false;
        } finally {
          local.clearOpInFlight(op);
        }
      }
    }

    _onConnectivityFallback?.call(false);
    _notifyPendingCount();
    return true;
  }

  @override
  Future<Result<WorkoutSession, Failure>> startSession({
    String? workoutId,
    String? workoutName,
    List<SessionExercise>? initialExercises,
  }) async {
    if (await _shouldUseOffline()) {
      final offlineModel = await _startSessionOffline(
        workoutId: workoutId,
        workoutName: workoutName,
        initialExercises: initialExercises,
      );
      return Success(offlineModel.toDomain());
    }

    try {
      final sessionData = {
        if (workoutId != null) 'workout_id': workoutId,
        if (workoutName != null) 'workout_name': workoutName,
        'started_at': DateTime.now().toIso8601String(),
        'status': 'in_progress',
      };

      final sessionModel = await _remoteDataSource.insertSession(sessionData);

      WorkoutSessionModel resolvedModel = sessionModel;
      if (initialExercises != null && initialExercises.isNotEmpty) {
        for (var i = 0; i < initialExercises.length; i++) {
          final ex = initialExercises[i];
          await _remoteDataSource.insertSessionExercise({
            'session_id': sessionModel.id,
            'exercise_id': ex.exerciseId,
            'sort_order': i,
            if (ex.notes != null) 'notes': ex.notes,
            'target_sets_count': ex.targetSetsCount,
            'target_reps_min': ex.targetRepsMin,
            'target_reps_max': ex.targetRepsMax,
            'target_rir': ex.targetRir,
            'target_rest_seconds': ex.targetRestSeconds,
          });
        }
        final fullSession =
            await _remoteDataSource.fetchSessionById(sessionModel.id);
        resolvedModel = _mergePrescribedTargets(
          fullSession,
          initialExercises: initialExercises,
        );
      }

      if (_localDataSource != null) {
        await _localDataSource.saveSession(resolvedModel);
      }
      return Success(resolvedModel.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (_localDataSource != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        final offlineModel = await _startSessionOffline(
          workoutId: workoutId,
          workoutName: workoutName,
          initialExercises: initialExercises,
        );
        return Success(offlineModel.toDomain());
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(UnexpectedFailure('Erro ao iniciar treino: $e', stack));
    }
  }

  @override
  Future<Result<WorkoutSession?, Failure>> getActiveSession() async {
    final local = _localDataSource;
    if (local != null && await _shouldUseOffline()) {
      try {
        return Success(local.getActiveSession()?.toDomain());
      } catch (e, stack) {
        return Err(
          CacheFailure('Erro ao ler sessão ativa no cache local: $e', stack),
        );
      }
    }

    try {
      if (local != null && local.pendingCount > 0) {
        await syncPendingOperations();
      }
      final model = await _remoteDataSource.fetchActiveSession();
      if (model == null) {
        return Success(local?.getActiveSession()?.toDomain());
      }
      final merged = _mergePrescribedTargets(
        model,
        cached: local?.getSessionById(model.id),
      );
      if (local != null) {
        try {
          await local.saveSession(merged);
        } catch (e, stack) {
          return Err(
            CacheFailure('Erro ao salvar sessão no cache local: $e', stack),
          );
        }
      }
      return Success(merged.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        try {
          return Success(local.getActiveSession()?.toDomain());
        } catch (cacheErr, cacheStack) {
          return Err(
            CacheFailure(
              'Erro ao ler sessão ativa no cache local: $cacheErr',
              cacheStack,
            ),
          );
        }
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(UnexpectedFailure('Erro ao verificar sessão ativa: $e', stack));
    }
  }

  @override
  Future<Result<WorkoutSession, Failure>> getSessionById(String id) async {
    final local = _localDataSource;
    final WorkoutSessionModel? cached;
    try {
      cached = local?.getSessionById(id);
    } catch (e, stack) {
      return Err(
        CacheFailure('Erro ao ler sessão no cache local: $e', stack),
      );
    }

    if (local != null && await _shouldUseOffline() && cached != null) {
      return Success(cached.toDomain());
    }

    try {
      if (local != null && local.pendingCount > 0) {
        final synced = await syncPendingOperations();
        if (!synced && cached != null) {
          return Success(cached.toDomain());
        }
      }
      final model = await _remoteDataSource.fetchSessionById(id);
      final merged = _mergePrescribedTargets(model, cached: cached);
      if (local != null) {
        try {
          await local.saveSession(merged);
        } catch (e, stack) {
          return Err(
            CacheFailure('Erro ao salvar sessão no cache local: $e', stack),
          );
        }
      }
      return Success(merged.toDomain());
    } on PostgrestException catch (e, stack) {
      if (cached != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        return Success(cached.toDomain());
      }
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        if (cached != null) {
          return Success(cached.toDomain());
        }
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(UnexpectedFailure('Erro ao carregar sessão de treino: $e', stack));
    }
  }

  @override
  Future<Result<LoggedSet, Failure>> logSet({
    required String sessionExerciseId,
    required int setNumber,
    SetType setType = SetType.working,
    required double weightKg,
    required int repsCompleted,
    int? durationSeconds,
    int? rirActual,
    double? rpeActual,
    int? restSecondsActual,
    ExecutionQuality? executionQuality,
    bool isWarmup = false,
    String? notes,
    List<DropSetEntry> dropSets = const [],
    String? existingSetId,
  }) async {
    final now = DateTime.now();
    final local = _localDataSource;
    final effectiveIsWarmup = isWarmup || setType == SetType.warmup;
    final resolvedSetId =
        existingSetId ?? (local != null ? _uuid.v4() : null);

    final data = <String, dynamic>{
      if (resolvedSetId != null && existingSetId == null) 'id': resolvedSetId,
      'session_exercise_id': sessionExerciseId,
      'set_number': setNumber,
      'set_type': LoggedSetModel.setTypeToString(setType),
      'weight_kg': weightKg,
      'reps_completed': repsCompleted,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (rirActual != null) 'rir_actual': rirActual,
      if (rpeActual != null) 'rpe_actual': rpeActual,
      if (restSecondsActual != null) 'rest_seconds_actual': restSecondsActual,
      if (executionQuality != null)
        'execution_quality':
            LoggedSetModel.executionQualityToString(executionQuality),
      'is_warmup': effectiveIsWarmup,
      if (notes != null) 'notes': notes,
      if (dropSets.isNotEmpty)
        'drop_sets': dropSets.map((d) => d.toJson()).toList()
      else if (existingSetId != null)
        'drop_sets': const <Map<String, dynamic>>[],
      'completed_at': now.toIso8601String(),
    };

    final localFallbackModel = LoggedSetModel(
      id: resolvedSetId ?? 'local-$setNumber',
      sessionExerciseId: sessionExerciseId,
      setNumber: setNumber,
      setType: LoggedSetModel.setTypeToString(setType),
      weightKg: weightKg,
      repsCompleted: repsCompleted,
      durationSeconds: durationSeconds,
      rirActual: rirActual,
      rpeActual: rpeActual,
      restSecondsActual: restSecondsActual,
      executionQuality:
          LoggedSetModel.executionQualityToString(executionQuality),
      isWarmup: effectiveIsWarmup,
      notes: notes,
      dropSets: dropSets,
      completedAt: now,
    );

    if (local != null && await _shouldUseOffline()) {
      await _upsertSetInCache(sessionExerciseId, localFallbackModel);
      await local.enqueueOp(
        PendingSessionOp(
          id: _uuid.v4(),
          type: existingSetId != null
              ? PendingSessionOpType.updateSet
              : PendingSessionOpType.logSet,
          payload: existingSetId != null
              ? {'set_id': existingSetId, 'data': data}
              : data,
          createdAt: now,
        ),
      );
      _notifyPendingCount();
      return Success(localFallbackModel.toDomain());
    }

    try {
      final model = existingSetId != null
          ? await _remoteDataSource.updateLoggedSet(existingSetId, data)
          : await _remoteDataSource.insertLoggedSet(data);
      await _upsertSetInCache(sessionExerciseId, model);
      return Success(model.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        await _upsertSetInCache(sessionExerciseId, localFallbackModel);
        await local.enqueueOp(
          PendingSessionOp(
            id: _uuid.v4(),
            type: existingSetId != null
                ? PendingSessionOpType.updateSet
                : PendingSessionOpType.logSet,
            payload: existingSetId != null
                ? {'set_id': existingSetId, 'data': data}
                : data,
            createdAt: now,
          ),
        );
        _notifyPendingCount();
        return Success(localFallbackModel.toDomain());
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(UnexpectedFailure('Erro ao registrar série: $e', stack));
    }
  }

  @override
  Future<Result<void, Failure>> deleteLoggedSet(String setId) async {
    final local = _localDataSource;

    Future<Result<void, Failure>> enqueueDeleteOffline() async {
      await _removeSetFromCache(setId);
      final canceledLocal = await local!.cancelPendingSetOpsIfUnsynced(setId);
      if (!canceledLocal) {
        await local.enqueueOp(
          PendingSessionOp(
            id: _uuid.v4(),
            type: PendingSessionOpType.deleteSet,
            payload: {'set_id': setId},
            createdAt: DateTime.now(),
          ),
        );
      }
      _notifyPendingCount();
      return const Success(null);
    }

    if (local != null && await _shouldUseOffline()) {
      return enqueueDeleteOffline();
    }

    try {
      await _remoteDataSource.deleteLoggedSet(setId);
      await _removeSetFromCache(setId);
      return const Success(null);
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        return enqueueDeleteOffline();
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(UnexpectedFailure('Erro ao excluir série: $e', stack));
    }
  }

  @override
  Future<Result<LoggedSet, Failure>> restoreLoggedSet(LoggedSet set) async {
    final local = _localDataSource;
    final restoredModel = LoggedSetModel.fromDomain(set);
    final effectiveIsWarmup = set.isWarmup || set.setType == SetType.warmup;
    final data = <String, dynamic>{
      'id': set.id,
      'session_exercise_id': set.sessionExerciseId,
      'set_number': set.setNumber,
      'set_type': LoggedSetModel.setTypeToString(set.setType),
      'weight_kg': set.weightKg,
      'reps_completed': set.repsCompleted,
      if (set.durationSeconds != null) 'duration_seconds': set.durationSeconds,
      if (set.rirActual != null) 'rir_actual': set.rirActual,
      if (set.rpeActual != null) 'rpe_actual': set.rpeActual,
      if (set.restSecondsActual != null)
        'rest_seconds_actual': set.restSecondsActual,
      if (set.executionQuality != null)
        'execution_quality':
            LoggedSetModel.executionQualityToString(set.executionQuality),
      'is_warmup': effectiveIsWarmup,
      if (set.notes != null) 'notes': set.notes,
      if (set.dropSets.isNotEmpty)
        'drop_sets': set.dropSets.map((d) => d.toJson()).toList(),
      if (set.completedAt != null)
        'completed_at': set.completedAt!.toIso8601String(),
    };

    Future<Result<LoggedSet, Failure>> restoreOffline() async {
      await _upsertSetInCache(set.sessionExerciseId, restoredModel);
      final canceledDelete = await local!.cancelPendingDeleteOp(set.id);
      if (!canceledDelete) {
        await local.enqueueOp(
          PendingSessionOp(
            id: _uuid.v4(),
            type: PendingSessionOpType.logSet,
            payload: data,
            createdAt: set.completedAt ?? DateTime.now(),
          ),
        );
      }
      _notifyPendingCount();
      return Success(restoredModel.toDomain());
    }

    if (local != null &&
        (await _shouldUseOffline() || local.isDeleteInFlight(set.id))) {
      return restoreOffline();
    }

    try {
      LoggedSetModel model;
      try {
        model = await _remoteDataSource.insertLoggedSet(data);
      } on PostgrestException catch (e) {
        if (e.code != '23505') rethrow;
        // Row still exists remotely (e.g., an earlier delete didn't land); update in place.
        model = await _remoteDataSource.updateLoggedSet(set.id, data);
      }
      await _upsertSetInCache(set.sessionExerciseId, model);
      return Success(model.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        return restoreOffline();
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(UnexpectedFailure('Erro ao restaurar série: $e', stack));
    }
  }

  @override
  Future<Result<SessionExercise, Failure>> addExerciseToSession({
    required String sessionId,
    required String exerciseId,
    int sortOrder = 0,
    String? notes,
    int targetRestSeconds = AppConstants.defaultRestSeconds,
    int targetSetsCount = 3,
  }) async {
    final local = _localDataSource;
    final data = {
      if (local != null) 'id': _uuid.v4(),
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'sort_order': sortOrder,
      if (notes != null) 'notes': notes,
      'target_rest_seconds': targetRestSeconds,
      'target_sets_count': targetSetsCount,
    };

    if (local != null && await _shouldUseOffline()) {
      final offlineModel = SessionExerciseModel(
        id: data['id'] as String,
        sessionId: sessionId,
        exerciseId: exerciseId,
        sortOrder: sortOrder,
        notes: notes,
        targetRestSeconds: targetRestSeconds,
        targetSetsCount: targetSetsCount,
      );
      final cached = local.getSessionById(sessionId);
      if (cached != null) {
        await local.saveSession(
          cached.copyWith(exercises: [...cached.exercises, offlineModel]),
        );
      }
      await local.enqueueOp(
        PendingSessionOp(
          id: _uuid.v4(),
          type: PendingSessionOpType.addExercise,
          payload: data,
          createdAt: DateTime.now(),
        ),
      );
      _notifyPendingCount();
      return Success(offlineModel.toDomain());
    }

    try {
      final model = await _remoteDataSource.insertSessionExercise(data);
      final domain = model.toDomain().copyWith(
            targetRestSeconds: targetRestSeconds,
            targetSetsCount: targetSetsCount,
          );
      final cached = local?.getSessionById(sessionId);
      if (cached != null) {
        await local?.saveSession(
          cached.copyWith(
            exercises: [
              ...cached.exercises,
              SessionExerciseModel.fromDomain(domain),
            ],
          ),
        );
      }
      return Success(domain);
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        final offlineModel = SessionExerciseModel(
          id: data['id'] as String,
          sessionId: sessionId,
          exerciseId: exerciseId,
          sortOrder: sortOrder,
          notes: notes,
          targetRestSeconds: targetRestSeconds,
          targetSetsCount: targetSetsCount,
        );
        final cached = local.getSessionById(sessionId);
        if (cached != null) {
          await local.saveSession(
            cached.copyWith(exercises: [...cached.exercises, offlineModel]),
          );
        }
        await local.enqueueOp(
          PendingSessionOp(
            id: _uuid.v4(),
            type: PendingSessionOpType.addExercise,
            payload: data,
            createdAt: DateTime.now(),
          ),
        );
        _notifyPendingCount();
        return Success(offlineModel.toDomain());
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(
        UnexpectedFailure('Erro ao adicionar exercício ao treino: $e', stack),
      );
    }
  }

  @override
  Future<Result<SessionExercise, Failure>> swapSessionExercise({
    required String sessionExerciseId,
    required String newExerciseId,
    String? replacedExerciseId,
  }) async {
    final local = _localDataSource;
    final data = {
      'exercise_id': newExerciseId,
      if (replacedExerciseId != null)
        'replaced_exercise_id': replacedExerciseId,
    };

    if (local != null && await _shouldUseOffline()) {
      final updated = await _swapExerciseInCache(
        sessionExerciseId: sessionExerciseId,
        newExerciseId: newExerciseId,
        replacedExerciseId: replacedExerciseId,
      );
      await local.enqueueOp(
        PendingSessionOp(
          id: _uuid.v4(),
          type: PendingSessionOpType.swapExercise,
          payload: {
            'session_exercise_id': sessionExerciseId,
            'data': data,
          },
          createdAt: DateTime.now(),
        ),
      );
      _notifyPendingCount();
      return Success(
        updated?.toDomain() ??
            SessionExercise(
              id: sessionExerciseId,
              sessionId: '',
              exerciseId: newExerciseId,
              replacedExerciseId: replacedExerciseId,
            ),
      );
    }

    try {
      final model = await _remoteDataSource.updateSessionExercise(
        sessionExerciseId,
        data,
      );
      await _swapExerciseInCache(
        sessionExerciseId: sessionExerciseId,
        newExerciseId: newExerciseId,
        replacedExerciseId: replacedExerciseId,
      );
      return Success(model.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        final updated = await _swapExerciseInCache(
          sessionExerciseId: sessionExerciseId,
          newExerciseId: newExerciseId,
          replacedExerciseId: replacedExerciseId,
        );
        await local.enqueueOp(
          PendingSessionOp(
            id: _uuid.v4(),
            type: PendingSessionOpType.swapExercise,
            payload: {
              'session_exercise_id': sessionExerciseId,
              'data': data,
            },
            createdAt: DateTime.now(),
          ),
        );
        _notifyPendingCount();
        return Success(
          updated?.toDomain() ??
              SessionExercise(
                id: sessionExerciseId,
                sessionId: '',
                exerciseId: newExerciseId,
                replacedExerciseId: replacedExerciseId,
              ),
        );
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(
        UnexpectedFailure('Erro ao trocar exercício da sessão: $e', stack),
      );
    }
  }

  @override
  Future<Result<WorkoutSession, Failure>> finishSession({
    required String sessionId,
    required int durationSeconds,
    double? perceivedExertion,
    int? executionScore,
    Mood? mood,
    String? notes,
  }) async {
    final local = _localDataSource;
    final completedAt = DateTime.now();
    final data = {
      'status': 'completed',
      'completed_at': completedAt.toIso8601String(),
      'duration_seconds': durationSeconds,
      if (perceivedExertion != null) 'perceived_exertion': perceivedExertion,
      if (executionScore != null) 'execution_score': executionScore,
      if (mood != null) 'mood': mood.name,
      if (notes != null) 'notes': notes,
    };

    Future<WorkoutSessionModel> saveCompletedOffline() async {
      final cached = local!.getSessionById(sessionId);
      final updated = (cached ??
              WorkoutSessionModel(
                id: sessionId,
                userId: 'offline_user',
                startedAt: completedAt.subtract(
                  Duration(seconds: durationSeconds),
                ),
              ))
          .copyWith(
        status: 'completed',
        completedAt: completedAt,
        durationSeconds: durationSeconds,
        perceivedExertion: perceivedExertion,
        executionScore: executionScore,
        mood: mood?.name,
        notes: notes,
      );
      await local.saveSession(updated);
      await local.enqueueOp(
        PendingSessionOp(
          id: _uuid.v4(),
          type: PendingSessionOpType.finishSession,
          payload: {
            'session_id': sessionId,
            'data': data,
          },
          createdAt: completedAt,
        ),
      );
      _notifyPendingCount();
      return updated;
    }

    if (local != null && await _shouldUseOffline()) {
      final updated = await saveCompletedOffline();
      return Success(updated.toDomain());
    }

    try {
      if (local != null && local.pendingCount > 0) {
        final synced = await syncPendingOperations();
        if (!synced) {
          final updated = await saveCompletedOffline();
          return Success(updated.toDomain());
        }
      }
      final model = await _remoteDataSource.updateSession(sessionId, data);
      final merged = _mergePrescribedTargets(
        model,
        cached: local?.getSessionById(sessionId),
      );
      await local?.saveSession(merged);
      return Success(merged.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        final updated = await saveCompletedOffline();
        return Success(updated.toDomain());
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(UnexpectedFailure('Erro ao finalizar treino: $e', stack));
    }
  }

  @override
  Future<Result<void, Failure>> abandonSession(String sessionId) async {
    final local = _localDataSource;
    final now = DateTime.now();
    final data = {
      'status': 'abandoned',
      'completed_at': now.toIso8601String(),
    };

    Future<void> saveAbandonOffline() async {
      final cached = local!.getSessionById(sessionId);
      if (cached != null) {
        await local.saveSession(
          cached.copyWith(status: 'abandoned', completedAt: now),
        );
      }
      await local.enqueueOp(
        PendingSessionOp(
          id: _uuid.v4(),
          type: PendingSessionOpType.abandonSession,
          payload: {'session_id': sessionId, 'data': data},
          createdAt: now,
        ),
      );
      _notifyPendingCount();
    }

    if (local != null && await _shouldUseOffline()) {
      await saveAbandonOffline();
      return const Success(null);
    }

    try {
      await _remoteDataSource.updateSession(sessionId, data);
      final cached = local?.getSessionById(sessionId);
      if (cached != null) {
        await local?.saveSession(
          cached.copyWith(status: 'abandoned', completedAt: now),
        );
      }
      return const Success(null);
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        await saveAbandonOffline();
        return const Success(null);
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(UnexpectedFailure('Erro ao descartar treino: $e', stack));
    }
  }
}
