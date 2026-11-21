import 'dart:io';

import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/goals/data/datasources/goal_remote_datasource.dart';
import 'package:personal_fitness_os/features/goals/data/models/goal_model.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_checkpoint.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';
import 'package:personal_fitness_os/features/goals/domain/repositories/goal_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoalRepositoryImpl implements GoalRepository {
  const GoalRepositoryImpl(this._remoteDataSource);

  final GoalRemoteDataSource _remoteDataSource;

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
    } catch (_, stack) {
      return Err(UnexpectedFailure(fallbackMessage, stack));
    }
  }

  @override
  Future<Result<List<Goal>, Failure>> getGoals({GoalStatus? status}) {
    return _guard(
      () async {
        final models = await _remoteDataSource.fetchGoals(status: status);
        return models.map((m) => m.toDomain()).toList();
      },
      'Erro ao listar metas.',
    );
  }

  @override
  Future<Result<Goal, Failure>> getGoalById(String goalId) {
    return _guard(
      () async {
        final model = await _remoteDataSource.fetchGoalById(goalId);
        return model.toDomain();
      },
      'Erro ao buscar detalhes da meta.',
    );
  }

  @override
  Future<Result<Goal, Failure>> createGoal(Goal goal) {
    return _guard(
      () async {
        final model = await _remoteDataSource.insertGoal(
          GoalModel.fromDomain(goal).toJson(),
        );
        return model.toDomain();
      },
      'Erro ao criar meta.',
    );
  }

  @override
  Future<Result<Goal, Failure>> updateGoalStatus(
      String goalId, GoalStatus status) {
    return _guard(
      () async {
        final model =
            await _remoteDataSource.updateGoalStatus(goalId, status.name);
        return model.toDomain();
      },
      'Erro ao atualizar status da meta.',
    );
  }

  @override
  Future<Result<GoalCheckpoint, Failure>> addGoalCheckpoint({
    required String goalId,
    required double value,
    String? notes,
    DateTime? recordedAt,
  }) {
    return _guard(
      () async {
        final model = await _remoteDataSource.insertGoalCheckpoint(
          goalId: goalId,
          value: value,
          notes: notes,
          recordedAt: recordedAt,
        );
        return model.toDomain();
      },
      'Erro ao registrar checkpoint da meta.',
    );
  }

  @override
  Future<Result<void, Failure>> deleteGoal(String goalId) {
    return _guard(
      () async {
        await _remoteDataSource.deleteGoal(goalId);
      },
      'Erro ao excluir meta.',
    );
  }
}
