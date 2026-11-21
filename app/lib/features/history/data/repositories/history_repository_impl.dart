import 'dart:io';

import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/history/data/datasources/history_remote_datasource.dart';
import 'package:personal_fitness_os/features/history/domain/entities/exercise_history_record.dart';
import 'package:personal_fitness_os/features/history/domain/entities/history_event_type.dart';
import 'package:personal_fitness_os/features/history/domain/entities/timeline_event.dart';
import 'package:personal_fitness_os/features/history/domain/repositories/history_repository.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  const HistoryRepositoryImpl(this._remoteDataSource);

  final HistoryRemoteDataSource _remoteDataSource;

  Future<Result<T, Failure>> _guard<T>(
    Future<T> Function() call,
    String fallbackMessage,
  ) async {
    try {
      final data = await call();
      return Success(data);
    } on AuthException catch (e, stack) {
      return Err(AuthFailure(e.message, stack));
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (_, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
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
        return models.map((m) => m.toDomain()).toList();
      },
      'Erro ao carregar histórico de treinos',
    );
  }

  @override
  Future<Result<List<WorkoutSession>, Failure>> getSessionsInRange({
    required DateTime start,
    required DateTime end,
  }) {
    return _guard(
      () async {
        final models = await _remoteDataSource.fetchSessionsInRange(
          start: start,
          end: end,
        );
        return models.map((m) => m.toDomain()).toList();
      },
      'Erro ao carregar dados do período',
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
    );
  }
}
