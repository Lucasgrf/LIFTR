import 'dart:io';

import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/data/datasources/weight_remote_datasource.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/weight_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeightRepositoryImpl implements WeightRepository {
  const WeightRepositoryImpl(this._remoteDataSource);

  final WeightRemoteDataSource _remoteDataSource;

  @override
  Future<Result<WeightEntry, Failure>> logWeight({
    required double weightKg,
    required DateTime measuredAt,
    String? notes,
  }) async {
    try {
      final model = await _remoteDataSource.insertWeightEntry({
        'weight': weightKg,
        'measured_at': measuredAt.toIso8601String(),
        if (notes != null) 'notes': notes,
      });
      return Success(model.toDomain());
    } on AuthException catch (e, stack) {
      return Err(AuthFailure(e.message, stack));
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao registrar peso: $e', stack));
    }
  }

  @override
  Future<Result<List<WeightEntry>, Failure>> getWeightHistory({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final models = await _remoteDataSource.fetchWeightHistory(
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toDomain()).toList());
    } on AuthException catch (e, stack) {
      return Err(AuthFailure(e.message, stack));
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao carregar histórico de peso: $e', stack));
    }
  }

  @override
  Future<Result<List<WeightEntry>, Failure>> getWeightEntriesInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final models = await _remoteDataSource.fetchWeightEntriesInRange(
        start: start,
        end: end,
      );
      return Success(models.map((m) => m.toDomain()).toList());
    } on AuthException catch (e, stack) {
      return Err(AuthFailure(e.message, stack));
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao buscar registros de peso do período: $e', stack));
    }
  }

  @override
  Future<Result<void, Failure>> deleteWeightEntry(String entryId) async {
    try {
      await _remoteDataSource.deleteWeightEntry(entryId);
      return const Success(null);
    } on AuthException catch (e, stack) {
      return Err(AuthFailure(e.message, stack));
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao excluir registro de peso: $e', stack));
    }
  }
}
