import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/training/data/datasources/training_remote_datasource.dart';
import 'package:personal_fitness_os/features/training/data/models/set_template_model.dart';
import 'package:personal_fitness_os/features/training/data/models/training_plan_model.dart';
import 'package:personal_fitness_os/features/training/data/models/workout_exercise_model.dart';
import 'package:personal_fitness_os/features/training/data/models/workout_model.dart';
import 'package:personal_fitness_os/features/training/data/repositories/training_repository_impl.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/add_exercise_to_workout.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/add_workout_to_plan.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/configure_set_templates.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/create_training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/reorder_workout_exercises.dart';
import 'package:personal_fitness_os/features/training/domain/usecases/set_active_training_plan.dart';

class MockTrainingRemoteDataSource extends Mock
    implements TrainingRemoteDataSource {}

void main() {
  late MockTrainingRemoteDataSource mockDataSource;
  late TrainingRepositoryImpl repository;

  late CreateTrainingPlanUseCase createTrainingPlanUseCase;
  late SetActiveTrainingPlanUseCase setActiveTrainingPlanUseCase;
  late AddWorkoutToPlanUseCase addWorkoutToPlanUseCase;
  late AddExerciseToWorkoutUseCase addExerciseToWorkoutUseCase;
  late ConfigureSetTemplatesUseCase configureSetTemplatesUseCase;
  late ReorderWorkoutExercisesUseCase reorderWorkoutExercisesUseCase;

  setUp(() {
    mockDataSource = MockTrainingRemoteDataSource();
    repository = TrainingRepositoryImpl(mockDataSource);

    createTrainingPlanUseCase = CreateTrainingPlanUseCase(repository);
    setActiveTrainingPlanUseCase = SetActiveTrainingPlanUseCase(repository);
    addWorkoutToPlanUseCase = AddWorkoutToPlanUseCase(repository);
    addExerciseToWorkoutUseCase = AddExerciseToWorkoutUseCase(repository);
    configureSetTemplatesUseCase = ConfigureSetTemplatesUseCase(repository);
    reorderWorkoutExercisesUseCase = ReorderWorkoutExercisesUseCase(repository);
  });

  group('Training Plan End-to-End Integration Flow', () {
    test('complete lifecycle: create plan -> add workout -> add exercise with sets -> configure sets -> activate plan', () async {
      // 1. Create plan
      const planModel = TrainingPlanModel(
        id: 'plan-101',
        userId: 'user-1',
        name: 'Hipertrofia ABCD',
        description: 'Programa focado em progressão de cargas',
        isActive: false,
      );

      when(() => mockDataSource.insertTrainingPlan(any()))
          .thenAnswer((_) async => planModel);

      final createResult = await createTrainingPlanUseCase.execute(
        name: 'Hipertrofia ABCD',
        description: 'Programa focado em progressão de cargas',
      );

      expect(createResult.isSuccess, isTrue);
      final createdPlan = (createResult as Success<TrainingPlan, Failure>).value;
      expect(createdPlan.id, 'plan-101');
      expect(createdPlan.name, 'Hipertrofia ABCD');

      // 2. Add workout to plan
      const workoutModel = WorkoutModel(
        id: 'workout-201',
        trainingPlanId: 'plan-101',
        name: 'Treino A - Peito e Tríceps',
        dayOfWeek: 1,
        estimatedDurationMinutes: 60,
      );

      when(() => mockDataSource.insertWorkout(any()))
          .thenAnswer((_) async => workoutModel);

      final addWorkoutResult = await addWorkoutToPlanUseCase.execute(
        trainingPlanId: 'plan-101',
        name: 'Treino A - Peito e Tríceps',
        dayOfWeek: 1,
        estimatedDurationMinutes: 60,
      );

      expect(addWorkoutResult.isSuccess, isTrue);
      final createdWorkout = (addWorkoutResult as Success<Workout, Failure>).value;
      expect(createdWorkout.id, 'workout-201');
      expect(createdWorkout.dayOfWeekLabel, 'Segunda-feira');

      // 3. Add exercise to workout with initial sets
      const workoutExerciseModel = WorkoutExerciseModel(
        id: 'we-301',
        workoutId: 'workout-201',
        exerciseId: 'ex-01',
      );

      const setModel1 = SetTemplateModel(
        id: 'set-1',
        workoutExerciseId: 'we-301',
        setNumber: 1,
        setType: 'warmup',
        targetRepsMin: 12,
        targetRepsMax: 15,
        restSeconds: 60,
      );

      const setModel2 = SetTemplateModel(
        id: 'set-2',
        workoutExerciseId: 'we-301',
        setNumber: 2,
        setType: 'working',
        targetRepsMin: 8,
        targetRepsMax: 12,
        targetRirMin: 1,
        targetRirMax: 2,
        restSeconds: 120,
      );

      when(() => mockDataSource.insertWorkoutExercise(any()))
          .thenAnswer((_) async => workoutExerciseModel);
      when(() => mockDataSource.setExerciseTemplates('we-301', any()))
          .thenAnswer((_) async => [setModel1, setModel2]);

      final addExerciseResult = await addExerciseToWorkoutUseCase.execute(
        workoutId: 'workout-201',
        exerciseId: 'ex-01',
        initialSetTemplates: [
          const SetTemplate(
            id: '',
            workoutExerciseId: '',
            setNumber: 1,
            setType: SetType.warmup,
            targetRepsMin: 12,
            targetRepsMax: 15,
            restSeconds: 60,
          ),
          const SetTemplate(
            id: '',
            workoutExerciseId: '',
            setNumber: 2,
            setType: SetType.working,
            targetRepsMin: 8,
            targetRepsMax: 12,
            targetRirMin: 1,
            targetRirMax: 2,
            restSeconds: 120,
          ),
        ],
      );

      expect(addExerciseResult.isSuccess, isTrue);
      final addedExercise = (addExerciseResult as Success<WorkoutExercise, Failure>).value;
      expect(addedExercise.id, 'we-301');
      expect(addedExercise.setTemplates.length, 2);
      expect(addedExercise.workingSetsCount, 1);

      // 4. Configure set templates (update sets)
      final updatedSetModel = setModel2.copyWith(targetRepsMin: 6, targetRepsMax: 10);
      when(() => mockDataSource.setExerciseTemplates('we-301', any()))
          .thenAnswer((_) async => [setModel1, updatedSetModel]);

      final configResult = await configureSetTemplatesUseCase.execute(
        workoutExerciseId: 'we-301',
        setTemplates: [
          setModel1.toDomain(),
          updatedSetModel.toDomain(),
        ],
      );

      expect(configResult.isSuccess, isTrue);
      final configuredSets = (configResult as Success<List<SetTemplate>, Failure>).value;
      expect(configuredSets.length, 2);

      // 5. Reorder exercises in workout
      when(() => mockDataSource.reorderWorkoutExercises('workout-201', ['we-301']))
          .thenAnswer((_) async {});

      final reorderResult = await reorderWorkoutExercisesUseCase.execute(
        workoutId: 'workout-201',
        orderedWorkoutExerciseIds: ['we-301'],
      );

      expect(reorderResult.isSuccess, isTrue);

      // 6. Set Active Plan
      final activePlanModel = planModel.copyWith(isActive: true);
      when(() => mockDataSource.setActivePlan('plan-101'))
          .thenAnswer((_) async => activePlanModel);

      final activeResult = await setActiveTrainingPlanUseCase.execute('plan-101');
      expect(activeResult.isSuccess, isTrue);
      expect((activeResult as Success<TrainingPlan, Failure>).value.isActive, isTrue);
    });
  });
}
