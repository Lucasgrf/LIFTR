import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/domain/services/session_performance_calculator.dart';

void main() {
  const exBench = Exercise(
    id: 'ex-bench',
    name: 'Supino Reto',
    primaryMuscleGroup: 'chest',
    equipment: 'barbell',
  );
  const exRow = Exercise(
    id: 'ex-row',
    name: 'Remada Curvada',
    primaryMuscleGroup: 'back',
    equipment: 'barbell',
  );
  const exCardio = Exercise(
    id: 'ex-cardio',
    name: 'Cardio',
    primaryMuscleGroup: 'Cardio',
    movementPattern: 'cardio',
    equipment: 'machine',
  );

  group('SessionPerformanceCalculator', () {
    test('returns 0% score and 5.0 RPE when no sets or cardio are logged', () {
      final session = WorkoutSession(
        id: 's-empty',
        userId: 'u-1',
        startedAt: DateTime(2026, 11, 21),
        exercises: const [
          SessionExercise(
            id: 'se-1',
            sessionId: 's-empty',
            exerciseId: 'ex-bench',
            exercise: exBench,
            targetSetsCount: 3,
          ),
        ],
      );

      final summary = SessionPerformanceCalculator.evaluate(session);
      expect(summary.executionScore, 0);
      expect(summary.autoRpe, 5.0);
      expect(summary.rpeSource, RpeEstimationSource.empty);
    });

    test(
        'yields high Execution Score (95-100%) and high auto-RPE when 100% sets completed with increased/maintained load and top reps',
        () {
      final session = WorkoutSession(
        id: 's-1',
        userId: 'u-1',
        startedAt: DateTime(2026, 11, 21),
        exercises: const [
          SessionExercise(
            id: 'se-1',
            sessionId: 's-1',
            exerciseId: 'ex-bench',
            exercise: exBench,
            targetSetsCount: 3,
            targetRepsMin: 8,
            targetRepsMax: 12,
            targetRir: 2,
            sets: [
              LoggedSet(
                id: 'l1',
                sessionExerciseId: 'se-1',
                setNumber: 1,
                weightKg: 82.5,
                repsCompleted: 12,
              ),
              LoggedSet(
                id: 'l2',
                sessionExerciseId: 'se-1',
                setNumber: 2,
                weightKg: 82.5,
                repsCompleted: 12,
              ),
              LoggedSet(
                id: 'l3',
                sessionExerciseId: 'se-1',
                setNumber: 3,
                weightKg: 82.5,
                repsCompleted: 12,
              ),
            ],
          ),
          SessionExercise(
            id: 'se-2',
            sessionId: 's-1',
            exerciseId: 'ex-row',
            exercise: exRow,
            targetSetsCount: 2,
            targetRepsMin: 12,
            targetRepsMax: 15,
            targetRir: 2,
            sets: [
              LoggedSet(
                id: 'l4',
                sessionExerciseId: 'se-2',
                setNumber: 1,
                weightKg: 70,
                repsCompleted: 15,
              ),
              LoggedSet(
                id: 'l5',
                sessionExerciseId: 'se-2',
                setNumber: 2,
                weightKg: 70,
                repsCompleted: 15,
              ),
            ],
          ),
        ],
      );

      final summary = SessionPerformanceCalculator.evaluate(
        session,
        previousMaxWeightByExerciseId: {
          'ex-bench': 80.0,
          'ex-row': 70.0,
        },
      );

      expect(summary.executionScore, 100);
      expect(summary.autoRpe, greaterThanOrEqualTo(8.5));
      expect(summary.exercisesWithLoadUp, 1);
      expect(summary.exercisesWithLoadMaintained, 1);
      expect(summary.exercisesWithLoadDrop, 0);
      expect(summary.setsBelowMinReps, 0);
      expect(
        summary.rpeSource,
        RpeEstimationSource.loadAndCompletionBased,
      );
    });

    test(
        'lowers both Execution Score and auto-RPE when load drops and reps fail minimum target (e.g. < 12 on 12-15 range)',
        () {
      final session = WorkoutSession(
        id: 's-drop',
        userId: 'u-1',
        startedAt: DateTime(2026, 11, 21),
        exercises: const [
          SessionExercise(
            id: 'se-1',
            sessionId: 's-drop',
            exerciseId: 'ex-bench',
            exercise: exBench,
            targetSetsCount: 3,
            targetRepsMin: 12,
            targetRepsMax: 15,
            targetRir: 2,
            sets: [
              LoggedSet(
                id: 'l1',
                sessionExerciseId: 'se-1',
                setNumber: 1,
                weightKg: 60.0, // dropped from 80 kg
                repsCompleted: 9, // below min 12
              ),
              LoggedSet(
                id: 'l2',
                sessionExerciseId: 'se-1',
                setNumber: 2,
                weightKg: 60.0,
                repsCompleted: 8, // below min 12
              ),
            ],
          ),
        ],
      );

      final summary = SessionPerformanceCalculator.evaluate(
        session,
        previousMaxWeightByExerciseId: {'ex-bench': 80.0},
      );

      expect(summary.executionScore, lessThan(70));
      expect(summary.autoRpe, lessThanOrEqualTo(7.5));
      expect(summary.exercisesWithLoadDrop, 1);
      expect(summary.setsBelowMinReps, 2);
    });

    test('computes scientific RPE from explicit RIR (10 - avg RIR) plus drop-set bump',
        () {
      final session = WorkoutSession(
        id: 's-rir',
        userId: 'u-1',
        startedAt: DateTime(2026, 11, 21),
        exercises: const [
          SessionExercise(
            id: 'se-1',
            sessionId: 's-rir',
            exerciseId: 'ex-bench',
            exercise: exBench,
            targetSetsCount: 2,
            targetRepsMin: 8,
            targetRepsMax: 12,
            sets: [
              LoggedSet(
                id: 'l1',
                sessionExerciseId: 'se-1',
                setNumber: 1,
                weightKg: 80.0,
                repsCompleted: 10,
                rirActual: 2,
              ),
              LoggedSet(
                id: 'l2',
                sessionExerciseId: 'se-1',
                setNumber: 2,
                setType: SetType.dropSet,
                weightKg: 80.0,
                repsCompleted: 10,
                rirActual: 1,
                dropSets: [DropSetEntry(weightKg: 60, repsCompleted: 6)],
              ),
            ],
          ),
        ],
      );

      final summary = SessionPerformanceCalculator.evaluate(session);
      // 10 - 1.5 + 0.3 = 8.8 -> rounded to nearest 0.5 = 9.0
      expect(summary.rpeSource, RpeEstimationSource.rirBased);
      expect(summary.averageRir, closeTo(1.5, 0.01));
      expect(summary.autoRpe, 9.0);
      expect(summary.executionScore, greaterThanOrEqualTo(90));
    });

    test('evaluates cardio-only sessions by time target', () {
      final session = WorkoutSession(
        id: 's-cardio',
        userId: 'u-1',
        startedAt: DateTime(2026, 11, 21),
        exercises: const [
          SessionExercise(
            id: 'se-c',
            sessionId: 's-cardio',
            exerciseId: 'ex-cardio',
            exercise: exCardio,
            targetSetsCount: 1,
            targetRepsMin: 15,
            targetRepsMax: 20,
            targetRestSeconds: 0,
            sets: [
              LoggedSet(
                id: 'lc-1',
                sessionExerciseId: 'se-c',
                setNumber: 1,
                weightKg: 0,
                repsCompleted: 0,
                durationSeconds: 1200, // 20 min
              ),
            ],
          ),
        ],
      );

      final summary = SessionPerformanceCalculator.evaluate(session);
      expect(summary.rpeSource, RpeEstimationSource.cardioOnly);
      expect(summary.executionScore, 100);
      expect(summary.autoRpe, 7.0);
      expect(summary.cardioMinutesLogged, 20);
      expect(session.totalVolumeKg, 0.0);
      expect(session.totalWorkingSetsCount, 0);
      expect(session.totalCardioDurationSeconds, 1200);
    });
  });
}
