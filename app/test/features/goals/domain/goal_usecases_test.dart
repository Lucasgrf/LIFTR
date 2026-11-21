import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_category.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_checkpoint.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';
import 'package:personal_fitness_os/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/add_goal_checkpoint.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/create_goal.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/delete_goal.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/get_goal_by_id.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/get_goals.dart';
import 'package:personal_fitness_os/features/goals/domain/usecases/update_goal_status.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

void main() {
  late MockGoalRepository mockRepo;
  late GetGoalsUseCase getGoalsUseCase;
  late GetGoalByIdUseCase getGoalByIdUseCase;
  late CreateGoalUseCase createGoalUseCase;
  late UpdateGoalStatusUseCase updateGoalStatusUseCase;
  late AddGoalCheckpointUseCase addCheckpointUseCase;
  late DeleteGoalUseCase deleteGoalUseCase;

  final tGoal = Goal(
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

  final tCheckpoint = GoalCheckpoint(
    id: 'gc-1',
    goalId: 'g-1',
    value: 83.0,
    recordedAt: DateTime(2026, 8, 23),
    notes: 'Progresso da semana',
  );

  setUpAll(() {
    registerFallbackValue(tGoal);
    registerFallbackValue(GoalStatus.active);
  });

  setUp(() {
    mockRepo = MockGoalRepository();
    getGoalsUseCase = GetGoalsUseCase(mockRepo);
    getGoalByIdUseCase = GetGoalByIdUseCase(mockRepo);
    createGoalUseCase = CreateGoalUseCase(mockRepo);
    updateGoalStatusUseCase = UpdateGoalStatusUseCase(mockRepo);
    addCheckpointUseCase = AddGoalCheckpointUseCase(mockRepo);
    deleteGoalUseCase = DeleteGoalUseCase(mockRepo);
  });

  group('Goal Entity Progress Calculation', () {
    test('should calculate decreasing goal progress correctly (e.g. weight loss 86 -> 80, current 83 is 50%)', () {
      final goal = Goal(
        id: 'g-1',
        title: 'Emagrecimento',
        category: GoalCategory.weight,
        initialValue: 86.0,
        targetValue: 80.0,
        currentValue: 83.0,
        startedAt: DateTime(2026, 8, 1),
      );

      expect(goal.isIncreaseGoal, isFalse);
      expect(goal.progressPercentage, 0.5);
    });

    test('should calculate increasing goal progress correctly (e.g. bench press 80 -> 100, current 90 is 50%)', () {
      final goal = Goal(
        id: 'g-2',
        title: 'Supino',
        category: GoalCategory.exerciseWeight,
        initialValue: 80.0,
        targetValue: 100.0,
        currentValue: 90.0,
        startedAt: DateTime(2026, 8, 1),
      );

      expect(goal.isIncreaseGoal, isTrue);
      expect(goal.progressPercentage, 0.5);
    });
  });

  group('GetGoalsUseCase', () {
    test('should return goals from repository', () async {
      when(() => mockRepo.getGoals(status: any(named: 'status')))
          .thenAnswer((_) async => Success([tGoal]));

      final result = await getGoalsUseCase.execute(status: GoalStatus.active);

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.length, 1);
    });
  });

  group('GetGoalByIdUseCase', () {
    test('should return goal by ID', () async {
      when(() => mockRepo.getGoalById('g-1'))
          .thenAnswer((_) async => Success(tGoal));

      final result = await getGoalByIdUseCase.execute('g-1');
      expect(result.isSuccess, isTrue);
      expect((result as Success).value.id, 'g-1');
    });

    test('should reject empty ID', () async {
      final result = await getGoalByIdUseCase.execute('   ');
      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });
  });

  group('CreateGoalUseCase', () {
    test('should create valid goal successfully', () async {
      when(() => mockRepo.createGoal(any()))
          .thenAnswer((_) async => Success(tGoal));

      final result = await createGoalUseCase.execute(tGoal);
      expect(result.isSuccess, isTrue);
    });

    test('should reject empty title or non-finite values', () async {
      final emptyTitle = await createGoalUseCase.execute(
        tGoal.copyWith(title: '  '),
      );
      expect(emptyTitle.isError, isTrue);
      expect((emptyTitle as Err).failure, isA<ValidationFailure>());

      final nanTarget = await createGoalUseCase.execute(
        tGoal.copyWith(targetValue: double.nan),
      );
      expect(nanTarget.isError, isTrue);
      expect((nanTarget as Err).failure, isA<ValidationFailure>());
    });
  });

  group('UpdateGoalStatusUseCase', () {
    test('should update goal status', () async {
      when(() => mockRepo.updateGoalStatus('g-1', GoalStatus.completed))
          .thenAnswer((_) async => Success(tGoal.copyWith(status: GoalStatus.completed)));

      final result = await updateGoalStatusUseCase.execute('g-1', GoalStatus.completed);
      expect(result.isSuccess, isTrue);
      expect((result as Success).value.status, GoalStatus.completed);
    });
  });

  group('AddGoalCheckpointUseCase', () {
    test('should add checkpoint successfully', () async {
      when(() => mockRepo.addGoalCheckpoint(
            goalId: 'g-1',
            value: 83.0,
            notes: any(named: 'notes'),
            recordedAt: any(named: 'recordedAt'),
          )).thenAnswer((_) async => Success(tCheckpoint));

      final result = await addCheckpointUseCase.execute(
        goalId: 'g-1',
        value: 83.0,
        notes: 'Progresso da semana',
      );

      expect(result.isSuccess, isTrue);
    });

    test('should reject non-finite value or empty goalId', () async {
      final nanVal = await addCheckpointUseCase.execute(
        goalId: 'g-1',
        value: double.nan,
      );
      expect(nanVal.isError, isTrue);
      expect((nanVal as Err).failure, isA<ValidationFailure>());

      final emptyId = await addCheckpointUseCase.execute(
        goalId: '',
        value: 80.0,
      );
      expect(emptyId.isError, isTrue);
      expect((emptyId as Err).failure, isA<ValidationFailure>());
    });
  });

  group('DeleteGoalUseCase', () {
    test('should delete goal from repository', () async {
      when(() => mockRepo.deleteGoal('g-1'))
          .thenAnswer((_) async => const Success(null));

      final result = await deleteGoalUseCase.execute('g-1');
      expect(result.isSuccess, isTrue);
    });
  });
}
