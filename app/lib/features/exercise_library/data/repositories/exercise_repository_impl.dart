import 'dart:io';

import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/network/network_info.dart';
import 'package:personal_fitness_os/features/exercise_library/data/datasources/exercise_local_datasource.dart';
import 'package:personal_fitness_os/features/exercise_library/data/datasources/exercise_remote_datasource.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/repositories/exercise_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementation of the ExerciseRepository using Supabase remote data source
/// with offline-first local cache fallback.
class ExerciseRepositoryImpl implements ExerciseRepository {
  const ExerciseRepositoryImpl(
    this._remoteDataSource, {
    ExerciseLocalDataSource? localDataSource,
    NetworkInfo? networkInfo,
    bool Function()? isOfflineMode,
    void Function(bool offline)? onConnectivityFallback,
  })  : _localDataSource = localDataSource,
        _networkInfo = networkInfo,
        _isOfflineMode = isOfflineMode,
        _onConnectivityFallback = onConnectivityFallback;

  final ExerciseRemoteDataSource _remoteDataSource;
  final ExerciseLocalDataSource? _localDataSource;
  final NetworkInfo? _networkInfo;
  final bool Function()? _isOfflineMode;
  final void Function(bool offline)? _onConnectivityFallback;

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

  @override
  Future<Result<List<Exercise>, Failure>> getExercises() async {
    final local = _localDataSource;
    if (local != null && await _shouldUseOffline()) {
      return Success(local.getExercises().map((m) => m.toDomain()).toList());
    }

    try {
      final models = await _remoteDataSource.fetchExercises();
      await local?.saveExercises(models);
      final entities = models.map((m) => m.toDomain()).toList();
      return Success(entities);
    } on PostgrestException catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        return Success(local.getExercises().map((m) => m.toDomain()).toList());
      }
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        return Success(local.getExercises().map((m) => m.toDomain()).toList());
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet. Verifique sua rede.', stack));
      }
      return Err(UnexpectedFailure('Erro inesperado ao carregar exercícios: $e', stack));
    }
  }

  @override
  Future<Result<Exercise, Failure>> getExerciseById(String id) async {
    final local = _localDataSource;
    if (local != null && await _shouldUseOffline()) {
      final cached = local.getExerciseById(id);
      if (cached != null) return Success(cached.toDomain());
    }

    try {
      final model = await _remoteDataSource.fetchExerciseById(id);
      await local?.upsertExercise(model);
      return Success(model.toDomain());
    } on PostgrestException catch (e, stack) {
      final cached = local?.getExerciseById(id);
      if (cached != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        return Success(cached.toDomain());
      }
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        final cached = local.getExerciseById(id);
        if (cached != null) return Success(cached.toDomain());
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(UnexpectedFailure('Erro ao buscar exercício: $e', stack));
    }
  }

  @override
  Future<Result<Exercise, Failure>> createCustomExercise({
    required String name,
    required String primaryMuscleGroup,
    List<String>? secondaryMuscles,
    String? equipment,
    String? movementPattern,
    String? instructions,
    String? commonMistakes,
    String? videoUrl,
    String? personalNotes,
  }) async {
    try {
      final data = {
        'name': name,
        'primary_muscle_group': primaryMuscleGroup,
        if (secondaryMuscles != null && secondaryMuscles.isNotEmpty)
          'secondary_muscles': secondaryMuscles,
        if (equipment != null && equipment.isNotEmpty) 'equipment': equipment,
        if (movementPattern != null && movementPattern.isNotEmpty)
          'movement_pattern': movementPattern,
        if (instructions != null && instructions.isNotEmpty)
          'instructions': instructions,
        if (commonMistakes != null && commonMistakes.isNotEmpty)
          'common_mistakes': commonMistakes,
        if (videoUrl != null && videoUrl.isNotEmpty) 'video_url': videoUrl,
        if (personalNotes != null && personalNotes.isNotEmpty)
          'personal_notes': personalNotes,
      };

      final model = await _remoteDataSource.insertCustomExercise(data);
      return Success(model.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet ao salvar exercício.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao criar exercício customizado: $e', stack));
    }
  }

  @override
  Future<Result<Exercise, Failure>> updateExerciseNotes({
    required String exerciseId,
    required String notes,
  }) async {
    try {
      final model = await _remoteDataSource.updateExerciseNotes(exerciseId, notes);
      return Success(model.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao atualizar notas: $e', stack));
    }
  }

  @override
  Future<Result<void, Failure>> deleteCustomExercise(String id) async {
    try {
      await _remoteDataSource.softDeleteExercise(id);
      return const Success(null);
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao deletar exercício: $e', stack));
    }
  }
}
