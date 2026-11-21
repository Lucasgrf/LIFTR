import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/goals/data/datasources/goal_remote_datasource.dart';
import 'package:personal_fitness_os/features/goals/data/models/goal_checkpoint_model.dart';
import 'package:personal_fitness_os/features/goals/data/models/goal_model.dart';
import 'package:personal_fitness_os/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_category.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_checkpoint.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGoalRemoteDataSource extends Mock implements GoalRemoteDataSource {}

void main() {
  late MockGoalRemoteDataSource mockDataSource;
  late GoalRepositoryImpl repository;

  final tGoalModel = GoalModel(
    id: 'g-1',
    title: 'Chegar a 80kg',
    category: GoalCategory.weight,
    initialValue: 86.0,
    targetValue: 80.0,
    currentValue: 83.0,
    unit: 'kg',
    startedAt: DateTime(2026, 8, 1),
    status: GoalStatus.active,
  );

  final tCheckpointModel = GoalCheckpointModel(
    id: 'gc-1',
    goalId: 'g-1',
    value: 83.0,
    recordedAt: DateTime(2026, 8, 23),
    notes: 'Check-in',
  );

  setUp(() {
    mockDataSource = MockGoalRemoteDataSource();
    repository = GoalRepositoryImpl(mockDataSource);
  });

  group('getGoals', () {
    test('should return goals list on success', () async {
      when(() => mockDataSource.fetchGoals(status: any(named: 'status')))
          .thenAnswer((_) async => [tGoalModel]);

      final result = await repository.getGoals(status: GoalStatus.active);

      expect(result.isSuccess, isTrue);
      expect((result as Success<List<Goal>, Failure>).value.length, 1);
    });

    test('should return AuthFailure on AuthException', () async {
      when(() => mockDataSource.fetchGoals(status: any(named: 'status')))
          .thenThrow(const AuthException('Unauthenticated'));

      final result = await repository.getGoals();

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<AuthFailure>());
    });

    test('should return ServerFailure on PostgrestException', () async {
      when(() => mockDataSource.fetchGoals(status: any(named: 'status')))
          .thenThrow(const PostgrestException(message: 'DB error'));

      final result = await repository.getGoals();

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ServerFailure>());
    });
  });

  group('getGoalById', () {
    test('should return goal by ID on success', () async {
      when(() => mockDataSource.fetchGoalById('g-1'))
          .thenAnswer((_) async => tGoalModel);

      final result = await repository.getGoalById('g-1');
      expect(result.isSuccess, isTrue);
      expect((result as Success<Goal, Failure>).value.id, 'g-1');
    });
  });

  group('createGoal', () {
    test('should create and return goal on success', () async {
      when(() => mockDataSource.insertGoal(any()))
          .thenAnswer((_) async => tGoalModel);

      final result = await repository.createGoal(tGoalModel.toDomain());
      expect(result.isSuccess, isTrue);
      expect((result as Success<Goal, Failure>).value.title, 'Chegar a 80kg');
    });
  });

  group('updateGoalStatus', () {
    test('should update status and return goal on success', () async {
      when(() => mockDataSource.updateGoalStatus('g-1', 'completed'))
          .thenAnswer((_) async => tGoalModel);

      final result = await repository.updateGoalStatus('g-1', GoalStatus.completed);
      expect(result.isSuccess, isTrue);
    });
  });

  group('addGoalCheckpoint', () {
    test('should add checkpoint and return model on success', () async {
      when(() => mockDataSource.insertGoalCheckpoint(
            goalId: 'g-1',
            value: 83.0,
            notes: any(named: 'notes'),
            recordedAt: any(named: 'recordedAt'),
          )).thenAnswer((_) async => tCheckpointModel);

      final result = await repository.addGoalCheckpoint(
        goalId: 'g-1',
        value: 83.0,
        notes: 'Check-in',
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success<GoalCheckpoint, Failure>).value.value, 83.0);
    });
  });

  group('deleteGoal', () {
    test('should succeed when deletion is successful', () async {
      when(() => mockDataSource.deleteGoal('g-1'))
          .thenAnswer((_) async => {});

      final result = await repository.deleteGoal('g-1');
      expect(result.isSuccess, isTrue);
    });
  });
}
