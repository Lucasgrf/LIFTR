import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/weight_providers.dart';
import 'package:personal_fitness_os/features/calendar/domain/entities/month_activity_data.dart';
import 'package:personal_fitness_os/features/calendar/domain/usecases/get_month_activities.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/providers/dashboard_providers.dart';

// Current visible month in calendar
final currentCalendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

// Currently selected day in month
final selectedCalendarDayProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final getMonthActivitiesUseCaseProvider = Provider<GetMonthActivitiesUseCase>((ref) {
  return GetMonthActivitiesUseCase(
    historyRepository: ref.watch(historyRepositoryProvider),
    weightRepository: ref.watch(weightRepositoryProvider),
  );
});

final monthActivitiesDataProvider = FutureProvider.autoDispose<MonthActivityData>((ref) async {
  final useCase = ref.watch(getMonthActivitiesUseCaseProvider);
  final visibleMonth = ref.watch(currentCalendarMonthProvider);

  final result = await useCase.execute(
    year: visibleMonth.year,
    month: visibleMonth.month,
  );

  return result.fold(
    (data) => data,
    (failure) => throw Exception(failure.message),
  );
});
