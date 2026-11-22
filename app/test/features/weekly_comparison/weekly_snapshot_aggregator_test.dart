import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/utils/duration_formatter.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/cardio_log.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/entities/weekly_comparison_data.dart';
import 'package:personal_fitness_os/features/weekly_comparison/domain/services/weekly_snapshot_aggregator.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

void main() {
  group('DurationFormatter & ISO week helpers', () {
    test('formats cardio durations cleanly in min and Xh Ym', () {
      expect(formatCardioSeconds(0), '0 min');
      expect(formatCardioSeconds(2700), '45 min');
      expect(formatCardioSeconds(3600), '1h');
      expect(formatCardioSeconds(4500), '1h 15m');
      expect(formatCardioSeconds(7500), '2h 5m');
    });

    test('formats signed deltas cleanly', () {
      expect(formatCardioDeltaSeconds(0), 'Igual');
      expect(formatCardioDeltaSeconds(900), '+15 min');
      expect(formatCardioDeltaSeconds(-600), '-10 min');
      expect(formatCardioDeltaSeconds(4500), '+1h 15m');
    });

    test('formats Monday-Sunday week ranges across months', () {
      expect(
        formatWeekRange(DateTime(2026, 11, 18)), // Wed Nov 18 -> 16-22 nov
        '16–22 nov',
      );
      expect(
        formatWeekRange(DateTime(2026, 12, 2)), // Wed Dec 2 -> 30 nov-6 dez
        '30 nov–6 dez',
      );
    });
  });

  group('WeeklySnapshotAggregator', () {
    const exBench = Exercise(
      id: 'ex-bench',
      name: 'Supino',
      primaryMuscleGroup: 'chest',
    );
    const exCardio = Exercise(
      id: 'ex-cardio',
      name: 'Cardio',
      primaryMuscleGroup: 'Cardio',
      movementPattern: 'cardio',
    );

    final weekStart = isoWeekStart(DateTime(2026, 11, 16)); // Mon Nov 16

    test('combines in-session cardio + standalone cardio and excludes cardio from tonnage',
        () {
      final session = WorkoutSession(
        id: 's-1',
        userId: 'u-1',
        startedAt: DateTime(2026, 11, 17, 18, 0),
        completedAt: DateTime(2026, 11, 17, 19, 0),
        durationSeconds: 3600,
        status: SessionStatus.completed,
        perceivedExertion: 8.5,
        executionScore: 94,
        exercises: const [
          SessionExercise(
            id: 'se-1',
            sessionId: 's-1',
            exerciseId: 'ex-bench',
            exercise: exBench,
            sets: [
              LoggedSet(
                id: 'ls-1',
                sessionExerciseId: 'se-1',
                setNumber: 1,
                weightKg: 80,
                repsCompleted: 10,
              ),
              LoggedSet(
                id: 'ls-2',
                sessionExerciseId: 'se-1',
                setNumber: 2,
                weightKg: 80,
                repsCompleted: 10,
              ),
            ],
          ),
          SessionExercise(
            id: 'se-2',
            sessionId: 's-1',
            exerciseId: 'ex-cardio',
            exercise: exCardio,
            sets: [
              LoggedSet(
                id: 'ls-c1',
                sessionExerciseId: 'se-2',
                setNumber: 1,
                weightKg: 0,
                repsCompleted: 0,
                durationSeconds: 1200, // 20 min in session
              ),
            ],
          ),
        ],
      );

      final standalone = [
        CardioLog(
          id: 'c-1',
          userId: 'u-1',
          modality: 'Esteira',
          durationSeconds: 1800, // 30 min standalone on Wed
          performedAt: DateTime(2026, 11, 18, 8, 0),
        ),
        CardioLog(
          id: 'c-old',
          userId: 'u-1',
          modality: 'Bicicleta',
          durationSeconds: 1500, // outside current week
          performedAt: DateTime(2026, 11, 10, 8, 0),
        ),
      ];

      final snap = WeeklySnapshotAggregator.aggregateWeek(
        weekStart: weekStart,
        sessions: [session],
        standaloneCardio: standalone,
      );

      expect(snap.workoutsCompleted, 1);
      expect(snap.cardioDurationSeconds, 3000); // 20m + 30m = 50m
      expect(snap.cardioMinutes, 50);
      expect(snap.trainingDurationSeconds, 3600);
      expect(snap.workingSetsCount, 2); // excludes cardio block
      expect(snap.totalVolumeKg, 1600.0); // excludes cardio block
      expect(snap.avgRpe, 8.5);
      expect(snap.avgExecutionScore, 94.0);

      final breakdown = WeeklySnapshotAggregator.buildDailyCardioBreakdown(
        weekStart: weekStart,
        sessions: [session],
        standaloneCardio: standalone,
      );
      expect(breakdown.length, 7);
      expect(breakdown[1].inSessionSeconds, 1200); // Tuesday
      expect(breakdown[2].standaloneSeconds, 1800); // Wednesday
      expect(breakdown[0].totalSeconds, 0);
    });

    test('returns null deltas on WeeklyComparisonData when previousWeek is null', () {
      final current = WeeklySnapshotAggregator.aggregateWeek(
        weekStart: weekStart,
        sessions: const [],
        standaloneCardio: [
          CardioLog(
            id: 'c-1',
            userId: 'u-1',
            modality: 'Corrida',
            durationSeconds: 1500,
            performedAt: DateTime(2026, 11, 19, 7, 0),
          ),
        ],
      );

      final data = WeeklyComparisonData(currentWeek: current);
      expect(data.hasPreviousWeek, isFalse);
      expect(data.cardioDeltaSeconds, isNull);
      expect(data.workoutsDelta, isNull);
      expect(data.workingSetsDelta, isNull);
      expect(data.volumeDeltaKg, isNull);
      expect(data.avgRpeDelta, isNull);
      expect(data.avgExecutionScoreDelta, isNull);
    });
  });
}
