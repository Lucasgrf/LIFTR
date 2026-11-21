import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/goals/data/datasources/goal_remote_datasource.dart';
import 'package:personal_fitness_os/features/goals/data/models/goal_checkpoint_model.dart';
import 'package:personal_fitness_os/features/goals/data/models/goal_model.dart';
import 'package:personal_fitness_os/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_category.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_checkpoint.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/add_goal_checkpoint.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/create_goal.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/delete_goal.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/get_goal_by_id.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/get_goals.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/update_goal_status.dart';

class MockGoalRemoteDataSource extends Mock implements GoalRemoteDataSource {}

void main() {
  late MockGoalRemoteDataSource mockDataSource;
  late GoalRepositoryImpl repository;
  late CreateGoalUseCase createGoalUseCase;
  late GetGoalsUseCase getGoalsUseCase;
  late GetGoalByIdUseCase getGoalByIdUseCase;
  late AddGoalCheckpointUseCase addCheckpointUseCase;
  late UpdateGoalStatusUseCase updateStatusUseCase;
  late DeleteGoalUseCase deleteGoalUseCase;

  final tGoalModel = GoalModel(
    id: 'g-1',
    title: 'Chegar a 80kg',
    category: GoalCategory.weight,
    initialValue: 86.0,
    targetValue: 80.0,
    currentValue: 86.0,
    unit: 'kg',
    startedAt: DateTime(2026, 8, 1),
    status: GoalStatus.active,
  );

  final tCheckpointModel = GoalCheckpointModel(
    id: 'gc-1',
    goalId: 'g-1',
    value: 83.0,
    recordedAt: DateTime(2026, 8, 23),
    notes: 'Check-in 1',
  );

  setUp(() {
    mockDataSource = MockGoalRemoteDataSource();
    repository = GoalRepositoryImpl(mockDataSource);

    createGoalUseCase = CreateGoalUseCase(repository);
    getGoalsUseCase = GetGoalsUseCase(repository);
    getGoalByIdUseCase = GetGoalByIdUseCase(repository);
    addCheckpointUseCase = AddGoalCheckpointUseCase(repository);
    updateStatusUseCase = UpdateGoalStatusUseCase(repository);
    deleteGoalUseCase = DeleteGoalUseCase(repository);
  });

  group('Goals End-to-End Integration Flow', () {
    test('should create goal, add checkpoint, update status and delete goal', () async {
      // 1. Create goal
      when(() => mockDataSource.insertGoal(any()))
          .thenAnswer((_) async => tGoalModel);

      final createResult = await createGoalUseCase.execute(tGoalModel.toDomain());
      expect(createResult.isSuccess, isTrue);
      final created = (createResult as Success<Goal, dynamic>).value;
      expect(created.title, 'Chegar a 80kg');
      expect(created.progressPercentage, 0.0);

      // 2. Add checkpoint (83kg)
      when(() => mockDataSource.insertGoalCheckpoint(
            goalId: 'g-1',
            value: 83.0,
            notes: 'Check-in 1',
            recordedAt: any(named: 'recordedAt'),
          )).thenAnswer((_) async => tCheckpointModel);

      final cpResult = await addCheckpointUseCase.execute(
        goalId: 'g-1',
        value: 83.0,
        notes: 'Check-in 1',
      );
      expect(cpResult.isSuccess, isTrue);
      final cp = (cpResult as Success<GoalCheckpoint, dynamic>).value;
      expect(cp.value, 83.0);

      // 3. Fetch goal by ID with updated progress
      final updatedGoalModel = GoalModel(
        id: 'g-1',
        title: 'Chegar a 80kg',
        category: GoalCategory.weight,
        initialValue: 86.0,
        targetValue: 80.0,
        currentValue: 83.0,
        unit: 'kg',
        startedAt: DateTime(2026, 8, 1),
        status: GoalStatus.active,
        checkpoints: [tCheckpointModel],
      );

      when(() => mockDataSource.fetchGoalById('g-1'))
          .thenAnswer((_) async => updatedGoalModel);

      final detailResult = await getGoalByIdUseCase.execute('g-1');
      expect(detailResult.isSuccess, isTrue);
      final detail = (detailResult as Success<Goal, dynamic>).value;
      expect(detail.currentValue, 83.0);
      expect(detail.progressPercentage, 0.5); // (86 - 83) / (86 - 80) = 3 / 6 = 50%

      // 4. Update status to completed
      when(() => mockDataSource.updateGoalStatus('g-1', 'completed'))
          .thenAnswer((_) async => updatedGoalModel);

      final statusResult = await updateStatusUseCase.execute('g-1', GoalStatus.completed);
      expect(statusResult.isSuccess, isTrue);

      // 5. Delete goal
      when(() => mockDataSource.deleteGoal('g-1'))
          .thenAnswer((_) async => {});

      final deleteResult = await deleteGoalUseCase.execute('g-1');
      expect(deleteResult.isSuccess, isTrue);
    });
  });
}
