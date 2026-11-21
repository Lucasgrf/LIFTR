import 'dart:io';

import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/workout_session/data/datasources/session_remote_datasource.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/logged_set_model.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/repositories/session_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(this._remoteDataSource);

  final SessionRemoteDataSource _remoteDataSource;

  @override
  Future<Result<WorkoutSession, Failure>> startSession({
    String? workoutId,
    String? workoutName,
    List<SessionExercise>? initialExercises,
  }) async {
    try {
      final sessionData = {
        if (workoutId != null) 'workout_id': workoutId,
        'started_at': DateTime.now().toIso8601String(),
        'status': 'in_progress',
      };

      final sessionModel = await _remoteDataSource.insertSession(sessionData);

      if (initialExercises != null && initialExercises.isNotEmpty) {
        for (var i = 0; i < initialExercises.length; i++) {
          final ex = initialExercises[i];
          await _remoteDataSource.insertSessionExercise({
            'session_id': sessionModel.id,
            'exercise_id': ex.exerciseId,
            'sort_order': i,
            if (ex.notes != null) 'notes': ex.notes,
          });
        }
        // Refetch full session with created exercises
        final fullSession = await _remoteDataSource.fetchSessionById(sessionModel.id);
        return Success(fullSession.toDomain());
      }

      return Success(sessionModel.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao iniciar treino: $e', stack));
    }
  }

  @override
  Future<Result<WorkoutSession?, Failure>> getActiveSession() async {
    try {
      final model = await _remoteDataSource.fetchActiveSession();
      return Success(model?.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao verificar sessão ativa: $e', stack));
    }
  }

  @override
  Future<Result<WorkoutSession, Failure>> getSessionById(String id) async {
    try {
      final model = await _remoteDataSource.fetchSessionById(id);
      return Success(model.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
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
    int? rirActual,
    double? rpeActual,
    int? restSecondsActual,
    ExecutionQuality? executionQuality,
    bool isWarmup = false,
    String? notes,
  }) async {
    try {
      final data = {
        'session_exercise_id': sessionExerciseId,
        'set_number': setNumber,
        'set_type': LoggedSetModel.setTypeToString(setType),
        'weight_kg': weightKg,
        'reps_completed': repsCompleted,
        if (rirActual != null) 'rir_actual': rirActual,
        if (rpeActual != null) 'rpe_actual': rpeActual,
        if (restSecondsActual != null) 'rest_seconds_actual': restSecondsActual,
        if (executionQuality != null)
          'execution_quality': LoggedSetModel.executionQualityToString(executionQuality),
        'is_warmup': isWarmup,
        if (notes != null) 'notes': notes,
        'completed_at': DateTime.now().toIso8601String(),
      };

      final model = await _remoteDataSource.insertLoggedSet(data);
      return Success(model.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao registrar série: $e', stack));
    }
  }

  @override
  Future<Result<void, Failure>> deleteLoggedSet(String setId) async {
    try {
      await _remoteDataSource.deleteLoggedSet(setId);
      return const Success(null);
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao excluir série: $e', stack));
    }
  }

  @override
  Future<Result<SessionExercise, Failure>> addExerciseToSession({
    required String sessionId,
    required String exerciseId,
    int sortOrder = 0,
    String? notes,
    int targetRestSeconds = 120,
    int targetSetsCount = 3,
  }) async {
    try {
      final data = {
        'session_id': sessionId,
        'exercise_id': exerciseId,
        'sort_order': sortOrder,
        if (notes != null) 'notes': notes,
      };

      final model = await _remoteDataSource.insertSessionExercise(data);
      return Success(model.toDomain().copyWith(
            targetRestSeconds: targetRestSeconds,
            targetSetsCount: targetSetsCount,
          ));
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao adicionar exercício ao treino: $e', stack));
    }
  }

  @override
  Future<Result<SessionExercise, Failure>> swapSessionExercise({
    required String sessionExerciseId,
    required String newExerciseId,
    String? replacedExerciseId,
  }) async {
    try {
      final data = {
        'exercise_id': newExerciseId,
        if (replacedExerciseId != null)
          'replaced_exercise_id': replacedExerciseId,
      };

      final model = await _remoteDataSource.updateSessionExercise(
        sessionExerciseId,
        data,
      );
      return Success(model.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao trocar exercício da sessão: $e', stack));
    }
  }

  @override
  Future<Result<WorkoutSession, Failure>> finishSession({
    required String sessionId,
    required int durationSeconds,
    double? perceivedExertion,
    Mood? mood,
    String? notes,
  }) async {
    try {
      final data = {
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'duration_seconds': durationSeconds,
        if (perceivedExertion != null) 'perceived_exertion': perceivedExertion,
        if (mood != null) 'mood': mood.name,
        if (notes != null) 'notes': notes,
      };

      final model = await _remoteDataSource.updateSession(sessionId, data);
      return Success(model.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao finalizar treino: $e', stack));
    }
  }

  @override
  Future<Result<void, Failure>> abandonSession(String sessionId) async {
    try {
      await _remoteDataSource.updateSession(sessionId, {
        'status': 'abandoned',
        'completed_at': DateTime.now().toIso8601String(),
      });
      return const Success(null);
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao descartar treino: $e', stack));
    }
  }
}
