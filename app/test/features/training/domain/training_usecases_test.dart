import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/domain/repositories/training_repository.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/add_exercise_to_workout.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/add_workout_to_plan.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/configure_set_templates.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/create_training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/delete_training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/get_active_training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/get_training_plan_by_id.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/get_training_plans.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/reorder_workout_exercises.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/set_active_training_plan.dart';

class MockTrainingRepository extends Mock implements TrainingRepository {}

void main() {
  late MockTrainingRepository mockRepository;

  const tPlan = TrainingPlan(
    id: 'plan-1',
    userId: 'user-1',
    name: 'Upper / Lower Especialização',
    isActive: true,
  );

  const tWorkout = Workout(
    id: 'workout-1',
    trainingPlanId: 'plan-1',
    name: 'Upper A',
    dayOfWeek: 1,
  );

  const tWorkoutExercise = WorkoutExercise(
    id: 'we-1',
    workoutId: 'workout-1',
    exerciseId: 'ex-1',
    sortOrder: 0,
  );

  const tSetTemplate = SetTemplate(
    id: 'st-1',
    workoutExerciseId: 'we-1',
    setNumber: 1,
    setType: SetType.working,
    targetRepsMin: 6,
    targetRepsMax: 10,
    targetRirMin: 1,
    targetRirMax: 2,
    restSeconds: 120,
  );

  setUp(() {
    mockRepository = MockTrainingRepository();
  });

  group('GetTrainingPlansUseCase', () {
    test('should return list of plans from repository', () async {
      when(() => mockRepository.getTrainingPlans())
          .thenAnswer((_) async => const Success([tPlan]));

      final useCase = GetTrainingPlansUseCase(mockRepository);
      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      expect((result as Success).value, [tPlan]);
      verify(() => mockRepository.getTrainingPlans()).called(1);
    });
  });

  group('GetActiveTrainingPlanUseCase', () {
    test('should return active plan when available', () async {
      when(() => mockRepository.getActiveTrainingPlan())
          .thenAnswer((_) async => const Success(tPlan));

      final useCase = GetActiveTrainingPlanUseCase(mockRepository);
      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      expect((result as Success).value, tPlan);
    });
  });

  group('GetTrainingPlanByIdUseCase', () {
    test('should return plan when ID is valid', () async {
      when(() => mockRepository.getTrainingPlanById('plan-1'))
          .thenAnswer((_) async => const Success(tPlan));

      final useCase = GetTrainingPlanByIdUseCase(mockRepository);
      final result = await useCase.execute('plan-1');

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.id, 'plan-1');
    });

    test('should return ValidationFailure when ID is empty', () async {
      final useCase = GetTrainingPlanByIdUseCase(mockRepository);
      final result = await useCase.execute('');

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });
  });

  group('CreateTrainingPlanUseCase', () {
    test('should create plan with valid name', () async {
      when(() => mockRepository.createTrainingPlan(
            name: any(named: 'name'),
            description: any(named: 'description'),
            isActive: any(named: 'isActive'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          )).thenAnswer((_) async => const Success(tPlan));

      final useCase = CreateTrainingPlanUseCase(mockRepository);
      final result = await useCase.execute(name: 'Upper / Lower Especialização');

      expect(result.isSuccess, isTrue);
    });

    test('should return ValidationFailure when name is empty', () async {
      final useCase = CreateTrainingPlanUseCase(mockRepository);
      final result = await useCase.execute(name: '   ');

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });
  });

  group('SetActiveTrainingPlanUseCase', () {
    test('should activate plan on valid ID', () async {
      when(() => mockRepository.setActiveTrainingPlan('plan-1'))
          .thenAnswer((_) async => const Success(tPlan));

      final useCase = SetActiveTrainingPlanUseCase(mockRepository);
      final result = await useCase.execute('plan-1');

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.isActive, isTrue);
    });
  });

  group('AddWorkoutToPlanUseCase', () {
    test('should add workout with valid inputs', () async {
      when(() => mockRepository.addWorkoutToPlan(
            trainingPlanId: 'plan-1',
            name: 'Upper A',
            dayOfWeek: 1,
            sortOrder: 0,
            notes: any(named: 'notes'),
            estimatedDurationMinutes: any(named: 'estimatedDurationMinutes'),
          )).thenAnswer((_) async => const Success(tWorkout));

      final useCase = AddWorkoutToPlanUseCase(mockRepository);
      final result = await useCase.execute(
        trainingPlanId: 'plan-1',
        name: 'Upper A',
        dayOfWeek: 1,
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.name, 'Upper A');
    });

    test('should return ValidationFailure when dayOfWeek is invalid', () async {
      final useCase = AddWorkoutToPlanUseCase(mockRepository);
      final result = await useCase.execute(
        trainingPlanId: 'plan-1',
        name: 'Upper A',
        dayOfWeek: 7, // Invalid, max 6
      );

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });
  });

  group('AddExerciseToWorkoutUseCase', () {
    test('should add exercise to workout', () async {
      when(() => mockRepository.addExerciseToWorkout(
            workoutId: 'workout-1',
            exerciseId: 'ex-1',
            sortOrder: 0,
            notes: any(named: 'notes'),
            initialSetTemplates: any(named: 'initialSetTemplates'),
          )).thenAnswer((_) async => const Success(tWorkoutExercise));

      final useCase = AddExerciseToWorkoutUseCase(mockRepository);
      final result = await useCase.execute(
        workoutId: 'workout-1',
        exerciseId: 'ex-1',
      );

      expect(result.isSuccess, isTrue);
    });
  });

  group('ConfigureSetTemplatesUseCase', () {
    test('should configure sets for workout exercise', () async {
      when(() => mockRepository.configureSetTemplates(
            workoutExerciseId: 'we-1',
            setTemplates: [tSetTemplate],
          )).thenAnswer((_) async => const Success([tSetTemplate]));

      final useCase = ConfigureSetTemplatesUseCase(mockRepository);
      final result = await useCase.execute(
        workoutExerciseId: 'we-1',
        setTemplates: [tSetTemplate],
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.length, 1);
    });

    test('should return ValidationFailure when set list is empty', () async {
      final useCase = ConfigureSetTemplatesUseCase(mockRepository);
      final result = await useCase.execute(
        workoutExerciseId: 'we-1',
        setTemplates: [],
      );

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });
  });

  group('ReorderWorkoutExercisesUseCase', () {
    test('should call repository reorder', () async {
      when(() => mockRepository.reorderWorkoutExercises(
            workoutId: 'workout-1',
            orderedWorkoutExerciseIds: ['we-2', 'we-1'],
          )).thenAnswer((_) async => const Success(null));

      final useCase = ReorderWorkoutExercisesUseCase(mockRepository);
      final result = await useCase.execute(
        workoutId: 'workout-1',
        orderedWorkoutExerciseIds: ['we-2', 'we-1'],
      );

      expect(result.isSuccess, isTrue);
    });
  });

  group('DeleteTrainingPlanUseCase', () {
    test('should soft delete plan', () async {
      when(() => mockRepository.deleteTrainingPlan('plan-1'))
          .thenAnswer((_) async => const Success(null));

      final useCase = DeleteTrainingPlanUseCase(mockRepository);
      final result = await useCase.execute('plan-1');

      expect(result.isSuccess, isTrue);
    });
  });
}
