import 'dart:io';

import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/core/network/network_info.dart';
import 'package:personal_fitness_os/features/training/data/datasources/training_local_datasource.dart';
import 'package:personal_fitness_os/features/training/data/datasources/training_remote_datasource.dart';
import 'package:personal_fitness_os/features/training/data/models/set_template_model.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainingRepositoryImpl implements TrainingRepository {
  const TrainingRepositoryImpl(
    this._remoteDataSource, {
    TrainingLocalDataSource? localDataSource,
    NetworkInfo? networkInfo,
    bool Function()? isOfflineMode,
    void Function(bool offline)? onConnectivityFallback,
  })  : _localDataSource = localDataSource,
        _networkInfo = networkInfo,
        _isOfflineMode = isOfflineMode,
        _onConnectivityFallback = onConnectivityFallback;

  final TrainingRemoteDataSource _remoteDataSource;
  final TrainingLocalDataSource? _localDataSource;
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
  Future<Result<List<TrainingPlan>, Failure>> getTrainingPlans() async {
    final local = _localDataSource;
    if (local != null && await _shouldUseOffline()) {
      try {
        return Success(local.getAllPlans().map((m) => m.toDomain()).toList());
      } catch (e, stack) {
        return Err(
          CacheFailure('Erro ao ler programas no cache local: $e', stack),
        );
      }
    }

    try {
      final models = await _remoteDataSource.fetchTrainingPlans();
      if (local != null) {
        try {
          await local.savePlans(models);
        } catch (e, stack) {
          return Err(
            CacheFailure('Erro ao salvar programas no cache local: $e', stack),
          );
        }
      }
      return Success(models.map((m) => m.toDomain()).toList());
    } on PostgrestException catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        try {
          return Success(local.getAllPlans().map((m) => m.toDomain()).toList());
        } catch (cacheErr, cacheStack) {
          return Err(
            CacheFailure(
              'Erro ao ler programas no cache local: $cacheErr',
              cacheStack,
            ),
          );
        }
      }
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        try {
          return Success(local.getAllPlans().map((m) => m.toDomain()).toList());
        } catch (cacheErr, cacheStack) {
          return Err(
            CacheFailure(
              'Erro ao ler programas no cache local: $cacheErr',
              cacheStack,
            ),
          );
        }
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(UnexpectedFailure('Erro ao carregar programas de treino: $e', stack));
    }
  }

  @override
  Future<Result<TrainingPlan?, Failure>> getActiveTrainingPlan() async {
    final local = _localDataSource;
    if (local != null && await _shouldUseOffline()) {
      try {
        return Success(local.getActivePlan()?.toDomain());
      } catch (e, stack) {
        return Err(
          CacheFailure('Erro ao ler programa ativo no cache local: $e', stack),
        );
      }
    }

    try {
      final model = await _remoteDataSource.fetchActiveTrainingPlan();
      if (local != null && model != null) {
        try {
          await local.savePlan(model);
        } catch (e, stack) {
          return Err(
            CacheFailure(
              'Erro ao salvar programa ativo no cache local: $e',
              stack,
            ),
          );
        }
      }
      return Success(model?.toDomain());
    } on PostgrestException catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        try {
          return Success(local.getActivePlan()?.toDomain());
        } catch (cacheErr, cacheStack) {
          return Err(
            CacheFailure(
              'Erro ao ler programa ativo no cache local: $cacheErr',
              cacheStack,
            ),
          );
        }
      }
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        try {
          return Success(local.getActivePlan()?.toDomain());
        } catch (cacheErr, cacheStack) {
          return Err(
            CacheFailure(
              'Erro ao ler programa ativo no cache local: $cacheErr',
              cacheStack,
            ),
          );
        }
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(UnexpectedFailure('Erro ao buscar programa ativo: $e', stack));
    }
  }

  @override
  Future<Result<TrainingPlan, Failure>> getTrainingPlanById(String id) async {
    final local = _localDataSource;
    if (local != null && await _shouldUseOffline()) {
      try {
        final cached = local.getPlanById(id);
        if (cached != null) {
          return Success(cached.toDomain());
        }
      } catch (e, stack) {
        return Err(
          CacheFailure('Erro ao ler programa no cache local: $e', stack),
        );
      }
    }

    try {
      final model = await _remoteDataSource.fetchTrainingPlanById(id);
      if (local != null) {
        try {
          await local.savePlan(model);
        } catch (e, stack) {
          return Err(
            CacheFailure('Erro ao salvar programa no cache local: $e', stack),
          );
        }
      }
      return Success(model.toDomain());
    } on PostgrestException catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        try {
          final cached = local.getPlanById(id);
          if (cached != null) {
            return Success(cached.toDomain());
          }
        } catch (cacheErr, cacheStack) {
          return Err(
            CacheFailure(
              'Erro ao ler programa no cache local: $cacheErr',
              cacheStack,
            ),
          );
        }
      }
      return Err(ServerFailure(e.message, stack));
    } catch (e, stack) {
      if (local != null && isNetworkError(e)) {
        _onConnectivityFallback?.call(true);
        try {
          final cached = local.getPlanById(id);
          if (cached != null) {
            return Success(cached.toDomain());
          }
        } catch (cacheErr, cacheStack) {
          return Err(
            CacheFailure(
              'Erro ao ler programa no cache local: $cacheErr',
              cacheStack,
            ),
          );
        }
      }
      if (e is SocketException) {
        return Err(NetworkFailure('Sem conexão com a internet.', stack));
      }
      return Err(UnexpectedFailure('Erro ao carregar programa de treino: $e', stack));
    }
  }

  @override
  Future<Result<TrainingPlan, Failure>> createTrainingPlan({
    required String name,
    String? description,
    bool isActive = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final data = {
        'name': name,
        if (description != null) 'description': description,
        'is_active': isActive,
        if (startDate != null) 'start_date': startDate.toIso8601String().split('T').first,
        if (endDate != null) 'end_date': endDate.toIso8601String().split('T').first,
      };

      final model = await _remoteDataSource.insertTrainingPlan(data);
      return Success(model.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao criar programa de treino: $e', stack));
    }
  }

  @override
  Future<Result<TrainingPlan, Failure>> setActiveTrainingPlan(String planId) async {
    try {
      final model = await _remoteDataSource.setActivePlan(planId);
      return Success(model.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao ativar programa de treino: $e', stack));
    }
  }

  @override
  Future<Result<Workout, Failure>> addWorkoutToPlan({
    required String trainingPlanId,
    required String name,
    int? dayOfWeek,
    int sortOrder = 0,
    String? notes,
    int? estimatedDurationMinutes,
  }) async {
    try {
      final data = {
        'training_plan_id': trainingPlanId,
        'name': name,
        if (dayOfWeek != null) 'day_of_week': dayOfWeek,
        'sort_order': sortOrder,
        if (notes != null) 'notes': notes,
        if (estimatedDurationMinutes != null)
          'estimated_duration_minutes': estimatedDurationMinutes,
      };

      final model = await _remoteDataSource.insertWorkout(data);
      return Success(model.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao adicionar treino: $e', stack));
    }
  }

  @override
  Future<Result<WorkoutExercise, Failure>> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
    int sortOrder = 0,
    String? notes,
    List<SetTemplate>? initialSetTemplates,
  }) async {
    try {
      final data = {
        'workout_id': workoutId,
        'exercise_id': exerciseId,
        'sort_order': sortOrder,
        if (notes != null) 'notes': notes,
      };

      final model = await _remoteDataSource.insertWorkoutExercise(data);

      if (initialSetTemplates != null && initialSetTemplates.isNotEmpty) {
        final templatePayloads = initialSetTemplates.asMap().entries.map((entry) {
          final idx = entry.key;
          final template = entry.value;
          return {
            'workout_exercise_id': model.id,
            'set_number': idx + 1,
            'set_type': SetTemplateModel.setTypeToString(template.setType),
            if (template.targetRepsMin != null) 'target_reps_min': template.targetRepsMin,
            if (template.targetRepsMax != null) 'target_reps_max': template.targetRepsMax,
            if (template.targetRirMin != null) 'target_rir_min': template.targetRirMin,
            if (template.targetRirMax != null) 'target_rir_max': template.targetRirMax,
            if (template.targetWeight != null) 'target_weight': template.targetWeight,
            'rest_seconds': template.restSeconds,
            if (template.notes != null) 'notes': template.notes,
          };
        }).toList();

        final setModels = await _remoteDataSource.setExerciseTemplates(
          model.id,
          templatePayloads,
        );

        final updatedEntity = model.toDomain().copyWith(
              setTemplates: setModels.map((s) => s.toDomain()).toList(),
            );
        return Success(updatedEntity);
      }

      return Success(model.toDomain());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao adicionar exercício ao treino: $e', stack));
    }
  }

  @override
  Future<Result<List<SetTemplate>, Failure>> configureSetTemplates({
    required String workoutExerciseId,
    required List<SetTemplate> setTemplates,
  }) async {
    try {
      final payloads = setTemplates.asMap().entries.map((entry) {
        final idx = entry.key;
        final template = entry.value;
        return {
          'workout_exercise_id': workoutExerciseId,
          'set_number': idx + 1,
          'set_type': SetTemplateModel.setTypeToString(template.setType),
          if (template.targetRepsMin != null) 'target_reps_min': template.targetRepsMin,
          if (template.targetRepsMax != null) 'target_reps_max': template.targetRepsMax,
          if (template.targetRirMin != null) 'target_rir_min': template.targetRirMin,
          if (template.targetRirMax != null) 'target_rir_max': template.targetRirMax,
          if (template.targetWeight != null) 'target_weight': template.targetWeight,
          'rest_seconds': template.restSeconds,
          if (template.notes != null) 'notes': template.notes,
        };
      }).toList();

      final models = await _remoteDataSource.setExerciseTemplates(
        workoutExerciseId,
        payloads,
      );

      return Success(models.map((m) => m.toDomain()).toList());
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao salvar séries: $e', stack));
    }
  }

  @override
  Future<Result<void, Failure>> reorderWorkoutExercises({
    required String workoutId,
    required List<String> orderedWorkoutExerciseIds,
  }) async {
    try {
      await _remoteDataSource.reorderWorkoutExercises(
        workoutId,
        orderedWorkoutExerciseIds,
      );
      return const Success(null);
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao reordenar exercícios: $e', stack));
    }
  }

  @override
  Future<Result<void, Failure>> reorderPlanWorkouts({
    required String trainingPlanId,
    required List<String> orderedWorkoutIds,
  }) async {
    try {
      await _remoteDataSource.reorderPlanWorkouts(
        trainingPlanId,
        orderedWorkoutIds,
      );
      return const Success(null);
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao reordenar fila de treinos: $e', stack));
    }
  }

  @override
  Future<Result<void, Failure>> deleteTrainingPlan(String planId) async {
    try {
      await _remoteDataSource.softDeleteTrainingPlan(planId);
      return const Success(null);
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao deletar plano: $e', stack));
    }
  }

  @override
  Future<Result<void, Failure>> deleteWorkout(String workoutId) async {
    try {
      await _remoteDataSource.deleteWorkout(workoutId);
      return const Success(null);
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao deletar treino: $e', stack));
    }
  }

  @override
  Future<Result<void, Failure>> deleteWorkoutExercise(String workoutExerciseId) async {
    try {
      await _remoteDataSource.deleteWorkoutExercise(workoutExerciseId);
      return const Success(null);
    } on PostgrestException catch (e, stack) {
      return Err(ServerFailure(e.message, stack));
    } on SocketException catch (e, stack) {
      return Err(NetworkFailure('Sem conexão com a internet.', stack));
    } catch (e, stack) {
      return Err(UnexpectedFailure('Erro ao remover exercício do treino: $e', stack));
    }
  }
}
