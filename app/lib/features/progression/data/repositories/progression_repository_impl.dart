import 'dart:io';

import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/progression/data/datasources/progression_remote_datasource.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/exercise_performance_history.dart';
import 'package:personal_fitness_os/features/progression/domain/repositories/progression_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressionRepositoryImpl implements ProgressionRepository {
  const ProgressionRepositoryImpl(this._remoteDataSource);

  final ProgressionRemoteDataSource _remoteDataSource;

  @override
  Future<Result<ExercisePerformanceHistory?, Failure>> getLastExercisePerformance(
    String exerciseId,
  ) async {
    try {
      final history = await _remoteDataSource.fetchLastExercisePerformance(exerciseId);
      return Success(history);
    } on AuthException catch (e, stack) {
      return Err(AuthFailure(e.message, stack));
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao buscar histórico de progressão: $e', stack));
    }
  }
}
