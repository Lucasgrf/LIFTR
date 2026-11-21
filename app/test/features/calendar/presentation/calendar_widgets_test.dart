import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/calendar/domain/entities/day_activity_summary.dart';
import 'package:personal_fitness_os/features/calendar/domain/entities/month_activity_data.dart';
import 'package:personal_fitness_os/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:personal_fitness_os/features/calendar/presentation/screens/activity_calendar_screen.dart';
import 'package:personal_fitness_os/features/calendar/presentation/widgets/day_activity_detail_card.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  final tSession = WorkoutSession(
    id: 's-1',
    userId: 'u-1',
    workoutName: 'Treino A - Peito',
    startedAt: DateTime(2026, 8, 15, 10, 0),
    completedAt: DateTime(2026, 8, 15, 11, 0),
    durationSeconds: 3600,
  );

  final tDaySummary = DayActivitySummary(
    date: DateTime(2026, 8, 15),
    workoutSession: tSession,
  );

  final tMonthData = MonthActivityData(
    year: 2026,
    month: 8,
    days: [tDaySummary],
  );

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        monthActivitiesDataProvider.overrideWith((ref) => Future.value(tMonthData)),
        currentCalendarMonthProvider.overrideWith((ref) => DateTime(2026, 8, 1)),
        selectedCalendarDayProvider.overrideWith((ref) => DateTime(2026, 8, 15)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const ActivityCalendarScreen(),
      ),
    );
  }

  group('ActivityCalendarScreen Widget Test', () {
    testWidgets('should render month title and selected day details', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Agosto 2026'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Treino A - Peito'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Treino A - Peito'), findsOneWidget);
      expect(find.text('Ativo'), findsOneWidget);
    });
  });

  group('DayActivityDetailCard Widget Test', () {
    testWidgets('should render descanso badge when no activity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: DayActivityDetailCard(
              summary: DayActivitySummary(date: DateTime(2026, 8, 16)),
            ),
          ),
        ),
      );

      expect(find.text('Descanso'), findsOneWidget);
      expect(find.text('Nenhum treino registrado neste dia.'), findsOneWidget);
    });
  });
}
