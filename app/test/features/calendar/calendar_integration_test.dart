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
  late GetMonthActivitiesUseCase getMonthActivitiesUseCase;

  final tSession = WorkoutSession(
    id: 's-1',
    userId: 'u-1',
    workoutName: 'Treino A',
    startedAt: DateTime(2026, 8, 5, 10, 0),
    completedAt: DateTime(2026, 8, 5, 11, 0),
    durationSeconds: 3600,
  );

  final tWeight = WeightEntry(
    id: 'w-1',
    weightKg: 81.0,
    measuredAt: DateTime(2026, 8, 5, 7, 30),
  );

  setUp(() {
    mockHistoryRepo = MockHistoryRepository();
    mockWeightRepo = MockWeightRepository();
    getMonthActivitiesUseCase = GetMonthActivitiesUseCase(
      historyRepository: mockHistoryRepo,
      weightRepository: mockWeightRepo,
    );
  });

  group('Calendar Aggregation Full Integration Flow', () {
    test('should aggregate sessions and weight entries for month', () async {
      when(() => mockHistoryRepo.getSessionsInRange(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => Success([tSession]));

      when(() => mockWeightRepo.getWeightHistory())
          .thenAnswer((_) async => Success([tWeight]));

      final result = await getMonthActivitiesUseCase.execute(year: 2026, month: 8);

      expect(result.isSuccess, isTrue);
      final monthData = (result as Success).value;

      expect(monthData.totalCompletedWorkouts, 1);
      expect(monthData.totalWeightLogDays, 1);
      expect(monthData.totalVolumeKg, 0.0);

      final day5 = monthData.days[4];
      expect(day5.hasWorkout, isTrue);
      expect(day5.hasWeight, isTrue);
      expect(day5.workoutSession?.workoutName, 'Treino A');
      expect(day5.weightEntry?.weightKg, 81.0);
    });
  });
}
