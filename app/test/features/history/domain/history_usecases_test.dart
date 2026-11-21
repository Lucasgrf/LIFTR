import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/history/domain/entities/exercise_history_record.dart';
import 'package:personal_fitness_os/features/history/domain/entities/history_event_type.dart';
import 'package:personal_fitness_os/features/history/domain/entities/timeline_event.dart';
import 'package:personal_fitness_os/features/history/domain/repositories/history_repository.dart';
import 'package:personal_fitness_os/features/history/domain/usecases/get_exercise_history.dart';
import 'package:personal_fitness_os/features/history/domain/usecases/get_unified_timeline.dart';
import 'package:personal_fitness_os/features/history/domain/usecases/get_workout_history.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late MockHistoryRepository mockRepo;
  late GetUnifiedTimelineUseCase getUnifiedTimelineUseCase;
  late GetExerciseHistoryUseCase getExerciseHistoryUseCase;
  late GetWorkoutHistoryUseCase getWorkoutHistoryUseCase;

  final tEvent = TimelineEvent(
    id: 'e-1',
    type: HistoryEventType.workout,
    timestamp: DateTime(2026, 8, 23, 10, 30),
    title: 'Treino A - Peito',
    subtitle: '4 séries • 45 min',
    referenceId: 's-1',
  );

  final tRecord = ExerciseHistoryRecord(
    sessionId: 's-1',
    sessionName: 'Treino A',
    date: DateTime(2026, 8, 23),
    setsCount: 4,
    topWeightKg: 80.0,
    topReps: 10,
    bestEstimated1Rm: 106.7,
  );

  final tSession = WorkoutSession(
    id: 's-1',
    userId: 'u-1',
    workoutId: 'w-1',
    workoutName: 'Treino A',
    startedAt: DateTime(2026, 8, 23, 10, 0),
    completedAt: DateTime(2026, 8, 23, 10, 45),
  );

  setUpAll(() {
    registerFallbackValue(HistoryEventType.workout);
  });

  setUp(() {
    mockRepo = MockHistoryRepository();
    getUnifiedTimelineUseCase = GetUnifiedTimelineUseCase(mockRepo);
    getExerciseHistoryUseCase = GetExerciseHistoryUseCase(mockRepo);
    getWorkoutHistoryUseCase = GetWorkoutHistoryUseCase(mockRepo);
  });

  group('GetUnifiedTimelineUseCase', () {
    test('should return timeline events from repository', () async {
      when(() => mockRepo.getUnifiedTimeline(
            type: any(named: 'type'),
            start: any(named: 'start'),
            end: any(named: 'end'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Success([tEvent]));

      final result = await getUnifiedTimelineUseCase.execute(
        type: HistoryEventType.workout,
        limit: 20,
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success).value, [tEvent]);
    });

    test('should reject invalid limit (<= 0)', () async {
      final result = await getUnifiedTimelineUseCase.execute(limit: 0);
      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });
  });

  group('GetExerciseHistoryUseCase', () {
    test('should return exercise records from repository', () async {
      when(() => mockRepo.getExerciseHistory('ex-1', limit: any(named: 'limit')))
          .thenAnswer((_) async => Success([tRecord]));

      final result = await getExerciseHistoryUseCase.execute('ex-1');

      expect(result.isSuccess, isTrue);
      expect((result as Success).value, [tRecord]);
    });

    test('should reject empty exerciseId or limit <= 0', () async {
      final emptyId = await getExerciseHistoryUseCase.execute('   ');
      expect(emptyId.isError, isTrue);
      expect((emptyId as Err).failure, isA<ValidationFailure>());

      final invalidLimit = await getExerciseHistoryUseCase.execute('ex-1', limit: -1);
      expect(invalidLimit.isError, isTrue);
      expect((invalidLimit as Err).failure, isA<ValidationFailure>());
    });
  });

  group('GetWorkoutHistoryUseCase', () {
    test('should return completed sessions', () async {
      when(() => mockRepo.getCompletedSessions(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => Success([tSession]));

      final result = await getWorkoutHistoryUseCase.execute();

      expect(result.isSuccess, isTrue);
      expect((result as Success).value, [tSession]);
    });
  });
}
