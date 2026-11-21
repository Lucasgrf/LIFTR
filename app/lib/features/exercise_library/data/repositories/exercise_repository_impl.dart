import 'dart:io';

import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/exercise_library/data/datasources/exercise_remote_datasource.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/repositories/exercise_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementation of the ExerciseRepository using Supabase remote data source.
class ExerciseRepositoryImpl implements ExerciseRepository {
  const ExerciseRepositoryImpl(this._remoteDataSource);

  final ExerciseRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Exercise>, Failure>> getExercises() async {
    try {
      final models = await _remoteDataSource.fetchExercises();
      final entities = models.map((m) => m.toDomain()).toList();
      return Success(entities);
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet. Verifique sua rede.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro inesperado ao carregar exercícios: $e', stack));
    }
  }

  @override
  Future<Result<Exercise, Failure>> getExerciseById(String id) async {
    try {
      final model = await _remoteDataSource.fetchExerciseById(id);
      return Success(model.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
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
