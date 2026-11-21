import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/history/data/datasources/history_remote_datasource.dart';
import 'package:personal_fitness_os/features/history/data/repositories/history_repository_impl.dart';
import 'package:personal_fitness_os/features/history/domain/entities/exercise_history_record.dart';
import 'package:personal_fitness_os/features/history/domain/entities/history_event_type.dart';
import 'package:personal_fitness_os/features/history/domain/entities/timeline_event.dart';
import 'package:personal_fitness_os/features/workout_session/data/models/workout_session_model.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockHistoryRemoteDataSource extends Mock
    implements HistoryRemoteDataSource {}

void main() {
  late MockHistoryRemoteDataSource mockDataSource;
  late HistoryRepositoryImpl repository;

  final tSessionModel = WorkoutSessionModel(
    id: 'session-1',
    userId: 'user-1',
    workoutName: 'Treino A',
    startedAt: DateTime(2026, 8, 22, 10, 0),
    completedAt: DateTime(2026, 8, 22, 11, 0),
    durationSeconds: 3600,
    status: 'completed',
  );

  final tEvent = TimelineEvent(
    id: 'e-1',
    type: HistoryEventType.workout,
    timestamp: DateTime(2026, 8, 23, 10, 30),
    title: 'Treino A',
    subtitle: '4 séries',
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

  setUp(() {
    mockDataSource = MockHistoryRemoteDataSource();
    repository = HistoryRepositoryImpl(mockDataSource);
  });

  group('getCompletedSessions', () {
    test('should return list of WorkoutSession entities', () async {
      when(() => mockDataSource.fetchCompletedSessions(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => [tSessionModel]);

      final result = await repository.getCompletedSessions();

      expect(result.isSuccess, isTrue);
      final list = (result as Success<List<WorkoutSession>, Failure>).value;
      expect(list.length, 1);
      expect(list.first.id, 'session-1');
      expect(list.first.isCompleted, isTrue);
    });

    test('should return ServerFailure on PostgrestException', () async {
      when(() => mockDataSource.fetchCompletedSessions(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenThrow(const PostgrestException(message: 'Database query error'));

      final result = await repository.getCompletedSessions();

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ServerFailure>());
    });
  });

  group('getSessionsInRange', () {
    test('should return list of sessions within range', () async {
      when(() => mockDataSource.fetchSessionsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => [tSessionModel]);

      final result = await repository.getSessionsInRange(
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 31),
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success<List<WorkoutSession>, Failure>).value.length, 1);
    });
  });

  group('getUnifiedTimeline', () {
    test('should return timeline events list on success', () async {
      when(() => mockDataSource.fetchUnifiedTimeline(
            type: any(named: 'type'),
            start: any(named: 'start'),
            end: any(named: 'end'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [tEvent]);

      final result = await repository.getUnifiedTimeline(
        type: HistoryEventType.workout,
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success<List<TimelineEvent>, Failure>).value.length, 1);
    });

    test('should return AuthFailure on AuthException', () async {
      when(() => mockDataSource.fetchUnifiedTimeline(
            type: any(named: 'type'),
            start: any(named: 'start'),
            end: any(named: 'end'),
            limit: any(named: 'limit'),
          )).thenThrow(const AuthException('Unauthenticated'));

      final result = await repository.getUnifiedTimeline();

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<AuthFailure>());
    });
  });

  group('getExerciseHistory', () {
    test('should return exercise records list on success', () async {
      when(() => mockDataSource.fetchExerciseHistory(
            'ex-1',
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [tRecord]);

      final result = await repository.getExerciseHistory('ex-1');

      expect(result.isSuccess, isTrue);
      expect((result as Success<List<ExerciseHistoryRecord>, Failure>).value.length, 1);
    });
  });
}
