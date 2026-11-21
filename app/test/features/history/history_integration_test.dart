import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/history/data/datasources/history_remote_datasource.dart';
import 'package:personal_fitness_os/features/history/data/repositories/history_repository_impl.dart';
import 'package:personal_fitness_os/features/history/domain/entities/exercise_history_record.dart';
import 'package:personal_fitness_os/features/history/domain/entities/history_event_type.dart';
import 'package:personal_fitness_os/features/history/domain/entities/timeline_event.dart';
import 'package:personal_fitness_os/features/history/domain/usecases/get_exercise_history.dart';
import 'package:personal_fitness_os/features/history/domain/usecases/get_unified_timeline.dart';

class MockHistoryRemoteDataSource extends Mock
    implements HistoryRemoteDataSource {}

void main() {
  late MockHistoryRemoteDataSource mockDataSource;
  late HistoryRepositoryImpl repository;
  late GetUnifiedTimelineUseCase getUnifiedTimelineUseCase;
  late GetExerciseHistoryUseCase getExerciseHistoryUseCase;

  final tWorkoutEvent = TimelineEvent(
    id: 'ws-1',
    type: HistoryEventType.workout,
    timestamp: DateTime(2026, 8, 23, 10, 0),
    title: 'Treino A - Peito',
    subtitle: '4 exercícios • 45 min',
    referenceId: 's-1',
  );

  final tWeightEvent = TimelineEvent(
    id: 'we-1',
    type: HistoryEventType.weight,
    timestamp: DateTime(2026, 8, 23, 8, 0),
    title: 'Pesagem: 82.4 kg',
    subtitle: 'Registro matinal',
    referenceId: 'w-1',
  );

  final tExerciseRecord = ExerciseHistoryRecord(
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
    getUnifiedTimelineUseCase = GetUnifiedTimelineUseCase(repository);
    getExerciseHistoryUseCase = GetExerciseHistoryUseCase(repository);
  });

  group('Unified Timeline and History Integration Test', () {
    test('should aggregate timeline events from datasource and sort chronologically', () async {
      when(() => mockDataSource.fetchUnifiedTimeline(
            type: any(named: 'type'),
            start: any(named: 'start'),
            end: any(named: 'end'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [tWorkoutEvent, tWeightEvent]);

      final result = await getUnifiedTimelineUseCase.execute();

      expect(result.isSuccess, isTrue);
      final events = (result as Success<List<TimelineEvent>, dynamic>).value;
      expect(events.length, 2);
      expect(events.first.type, HistoryEventType.workout);
      expect(events.last.type, HistoryEventType.weight);
    });

    test('should fetch exercise progression records with computed stats', () async {
      when(() => mockDataSource.fetchExerciseHistory(
            'ex-1',
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [tExerciseRecord]);

      final result = await getExerciseHistoryUseCase.execute('ex-1');

      expect(result.isSuccess, isTrue);
      final records = (result as Success<List<ExerciseHistoryRecord>, dynamic>).value;
      expect(records.length, 1);
      expect(records.first.topWeightKg, 80.0);
      expect(records.first.bestEstimated1Rm, 106.7);
    });
  });
}
