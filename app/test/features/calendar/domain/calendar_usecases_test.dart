import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/weight_repository.dart';
import 'package:personal_fitness_os/features/calendar/domain/usecases/get_month_activities.dart';
import 'package:personal_fitness_os/features/history/domain/repositories/history_repository.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}
class MockWeightRepository extends Mock implements WeightRepository {}

void main() {
  late MockHistoryRepository mockHistoryRepo;
  late MockWeightRepository mockWeightRepo;

  final tSession = WorkoutSession(
    id: 's-1',
    userId: 'u-1',
    workoutName: 'Treino A',
    startedAt: DateTime(2026, 8, 10, 10, 0),
    completedAt: DateTime(2026, 8, 10, 11, 0),
    durationSeconds: 3600,
  );

  final tWeight = WeightEntry(
    id: 'w-1',
    weightKg: 82.5,
    measuredAt: DateTime(2026, 8, 10, 8, 0),
  );

  setUp(() {
    mockHistoryRepo = MockHistoryRepository();
    mockWeightRepo = MockWeightRepository();
  });

  group('GetMonthActivitiesUseCase', () {
    test('should aggregate sessions and weight into month activity data', () async {
      when(() => mockHistoryRepo.getSessionsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => Success([tSession]));

      when(() => mockWeightRepo.getWeightHistory())
          .thenAnswer((_) async => Success([tWeight]));

      final useCase = GetMonthActivitiesUseCase(
        historyRepository: mockHistoryRepo,
        weightRepository: mockWeightRepo,
      );

      final result = await useCase.execute(year: 2026, month: 8);

      expect(result.isSuccess, isTrue);
      final data = (result as Success).value;
      expect(data.year, 2026);
      expect(data.month, 8);
      expect(data.days.length, 31); // August has 31 days
      expect(data.totalCompletedWorkouts, 1);
      expect(data.totalWeightLogDays, 1);
      expect(data.totalVolumeKg, 0.0);

      // Check day 10
      final day10 = data.days[9];
      expect(day10.hasWorkout, isTrue);
      expect(day10.hasWeight, isTrue);
      expect(day10.workoutSession?.workoutName, 'Treino A');
    });
  });
}
