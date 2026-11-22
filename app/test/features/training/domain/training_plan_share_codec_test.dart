import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/training_plan.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout_exercise.dart';
import 'package:personal_fitness_os/features/training/domain/services/training_plan_share_codec.dart';

void main() {
  const tBench = Exercise(
    id: 'ex-bench',
    name: 'Supino Reto com Barra',
    primaryMuscleGroup: 'chest',
    equipment: 'barbell',
    movementPattern: 'horizontal_push',
  );

  const tCardio = Exercise(
    id: 'ex-treadmill',
    name: 'Esteira / Cardio',
    primaryMuscleGroup: 'cardio',
    equipment: 'machine',
    movementPattern: 'cardio',
  );

  final tPlan = TrainingPlan(
    id: 'plan-1',
    userId: 'user-1',
    name: 'Upper / Lower do Lucas',
    description: 'Divisão de 4 dias com cardio ao final',
    isActive: true,
    workouts: const [
      Workout(
        id: 'w-1',
        trainingPlanId: 'plan-1',
        name: 'Upper A',
        dayOfWeek: 1,
        estimatedDurationMinutes: 60,
        notes: 'Foco em carga progressiva',
        exercises: [
          WorkoutExercise(
            id: 'we-1',
            workoutId: 'w-1',
            exerciseId: 'ex-bench',
            exercise: tBench,
            notes: 'Pausa de 1s no peito',
            setTemplates: [
              SetTemplate(
                id: 'st-1',
                workoutExerciseId: 'we-1',
                setNumber: 1,
                setType: SetType.warmup,
                targetRepsMin: 10,
                targetRepsMax: 12,
                restSeconds: 60,
              ),
              SetTemplate(
                id: 'st-2',
                workoutExerciseId: 'we-1',
                setNumber: 2,
                setType: SetType.working,
                targetRepsMin: 8,
                targetRepsMax: 10,
                targetRirMin: 1,
                targetRirMax: 2,
                targetWeight: 80,
                restSeconds: 180,
              ),
            ],
          ),
          WorkoutExercise(
            id: 'we-2',
            workoutId: 'w-1',
            exerciseId: 'ex-treadmill',
            exercise: tCardio,
            setTemplates: [
              SetTemplate(
                id: 'st-3',
                workoutExerciseId: 'we-2',
                setNumber: 1,
                setType: SetType.working,
                restSeconds: 0,
                notes: '20 min',
              ),
            ],
          ),
        ],
      ),
    ],
  );

  group('TrainingPlanShareCodec', () {
    test('round-trips plan with strength + warmup + cardio sets losslessly', () {
      final code = TrainingPlanShareCodec.encode(tPlan);
      expect(code, startsWith(TrainingPlanShareCodec.prefix));

      final decoded = TrainingPlanShareCodec.decode(code);
      expect(decoded.planName, 'Upper / Lower do Lucas');
      expect(decoded.description, 'Divisão de 4 dias com cardio ao final');
      expect(decoded.workouts, hasLength(1));

      final workout = decoded.workouts.first;
      expect(workout.name, 'Upper A');
      expect(workout.dayOfWeek, 1);
      expect(workout.estimatedDurationMinutes, 60);
      expect(workout.exercises, hasLength(2));

      final bench = workout.exercises[0];
      expect(bench.exerciseName, 'Supino Reto com Barra');
      expect(bench.isCardio, isFalse);
      expect(bench.exactSets, hasLength(2));
      expect(bench.exactSets![0].setType, SetType.warmup);
      expect(bench.exactSets![1].setType, SetType.working);
      expect(bench.exactSets![1].targetRepsMin, 8);
      expect(bench.exactSets![1].targetRepsMax, 10);
      expect(bench.exactSets![1].targetWeight, 80);

      final cardio = workout.exercises[1];
      expect(cardio.exerciseName, 'Esteira / Cardio');
      expect(cardio.isCardio, isTrue);
      expect(cardio.targetDurationMinutes, 20);
      expect(cardio.restSeconds, 0);
    });

    test('decodes share code embedded inside a full WhatsApp message', () {
      final whatsappMsg = TrainingPlanShareCodec.buildShareMessage(tPlan);
      expect(whatsappMsg, contains('Upper / Lower do Lucas'));

      final decoded = TrainingPlanShareCodec.decode(whatsappMsg);
      expect(decoded.planName, 'Upper / Lower do Lucas');
      expect(decoded.workouts.first.exercises, hasLength(2));
    });

    test('throws FormatException on empty or invalid code', () {
      expect(
        () => TrainingPlanShareCodec.decode('   '),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => TrainingPlanShareCodec.decode('codigo-invalido-123'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => TrainingPlanShareCodec.decode('LIFTR-PLAN-V1:!!!corrompido!!!'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
