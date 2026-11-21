import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/training/data/datasources/training_remote_datasource.dart';
import 'package:personal_fitness_os/features/training/data/models/training_plan_model.dart';
import 'package:personal_fitness_os/features/training/data/models/workout_exercise_model.dart';
import 'package:personal_fitness_os/features/training/data/models/workout_model.dart';
import 'package:personal_fitness_os/features/training/data/repositories/training_repository_impl.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockTrainingRemoteDataSource extends Mock
    implements TrainingRemoteDataSource {}

void main() {
  late MockTrainingRemoteDataSource mockRemoteDataSource;
  late TrainingRepositoryImpl repository;

  const tPlanModel = TrainingPlanModel(
    id: 'plan-1',
    userId: 'user-1',
    name: 'Upper/Lower Split',
    isActive: true,
  );

  const tWorkoutModel = WorkoutModel(
    id: 'workout-1',
    trainingPlanId: 'plan-1',
    name: 'Upper A',
    dayOfWeek: 1,
  );

  const tWorkoutExerciseModel = WorkoutExerciseModel(
    id: 'we-1',
    workoutId: 'workout-1',
    exerciseId: 'ex-1',
  );

  setUp(() {
    mockRemoteDataSource = MockTrainingRemoteDataSource();
    repository = TrainingRepositoryImpl(mockRemoteDataSource);
  });

  group('getTrainingPlans', () {
    test('should return list of TrainingPlan entities on success', () async {
      when(() => mockRemoteDataSource.fetchTrainingPlans())
          .thenAnswer((_) async => [tPlanModel]);

      final result = await repository.getTrainingPlans();

      expect(result.isSuccess, isTrue);
      final list = (result as Success<List<TrainingPlan>, Failure>).value;
      expect(list.length, 1);
      expect(list.first.id, 'plan-1');
      expect(list.first.name, 'Upper/Lower Split');
      verify(() => mockRemoteDataSource.fetchTrainingPlans()).called(1);
    });

    test('should return ServerFailure on PostgrestException', () async {
      when(() => mockRemoteDataSource.fetchTrainingPlans()).thenThrow(
        const PostgrestException(message: 'Database query failed'),
      );

      final result = await repository.getTrainingPlans();

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ServerFailure>());
    });

    test('should return NetworkFailure on SocketException', () async {
      when(() => mockRemoteDataSource.fetchTrainingPlans()).thenThrow(
        const SocketException('Failed host lookup'),
      );

      final result = await repository.getTrainingPlans();

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<NetworkFailure>());
    });
  });

  group('getActiveTrainingPlan', () {
    test('should return active plan when exists', () async {
      when(() => mockRemoteDataSource.fetchActiveTrainingPlan())
          .thenAnswer((_) async => tPlanModel);

      final result = await repository.getActiveTrainingPlan();

      expect(result.isSuccess, isTrue);
      expect((result as Success<TrainingPlan?, Failure>).value?.isActive, isTrue);
    });

    test('should return null when no plan is active', () async {
      when(() => mockRemoteDataSource.fetchActiveTrainingPlan())
          .thenAnswer((_) async => null);

      final result = await repository.getActiveTrainingPlan();

      expect(result.isSuccess, isTrue);
      expect((result as Success<TrainingPlan?, Failure>).value, isNull);
    });
  });

  group('setActiveTrainingPlan', () {
    test('should activate plan on success', () async {
      when(() => mockRemoteDataSource.setActivePlan('plan-1'))
          .thenAnswer((_) async => tPlanModel);

      final result = await repository.setActiveTrainingPlan('plan-1');

      expect(result.isSuccess, isTrue);
      expect((result as Success<TrainingPlan, Failure>).value.id, 'plan-1');
    });
  });

  group('addWorkoutToPlan', () {
    test('should insert workout and return domain entity', () async {
      when(() => mockRemoteDataSource.insertWorkout(any()))
          .thenAnswer((_) async => tWorkoutModel);

      final result = await repository.addWorkoutToPlan(
        trainingPlanId: 'plan-1',
        name: 'Upper A',
        dayOfWeek: 1,
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.name, 'Upper A');
    });
  });

  group('addExerciseToWorkout', () {
    test('should insert workout exercise', () async {
      when(() => mockRemoteDataSource.insertWorkoutExercise(any()))
          .thenAnswer((_) async => tWorkoutExerciseModel);

      final result = await repository.addExerciseToWorkout(
        workoutId: 'workout-1',
        exerciseId: 'ex-1',
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.id, 'we-1');
    });
  });
}
