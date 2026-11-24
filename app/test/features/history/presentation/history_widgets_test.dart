import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/history/domain/entities/history_event_type.dart';
import 'package:personal_fitness_os/features/history/domain/entities/timeline_event.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/history_workout_card.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/timeline_event_card.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/timeline_filter_bar.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/workout_mood_icon.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  final tSession = WorkoutSession(
    id: 's-1',
    userId: 'u-1',
    workoutName: 'Treino A - Peito e Tríceps',
    startedAt: DateTime(2026, 8, 22, 10, 0),
    completedAt: DateTime(2026, 8, 22, 11, 0),
    durationSeconds: 3600,
    status: SessionStatus.completed,
    perceivedExertion: 8.5,
    mood: Mood.excellent,
  );

  final tEvent = TimelineEvent(
    id: 'e-1',
    type: HistoryEventType.workout,
    timestamp: DateTime(2026, 8, 23, 10, 30),
    title: 'Treino A - Peito',
    subtitle: '4 exercícios • 45 min',
    referenceId: 's-1',
  );

  Widget createWidgetUnderTest(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('HistoryWorkoutCard Widget Test', () {
    testWidgets('should render workout name, duration, RPE and mood', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          HistoryWorkoutCard(session: tSession),
        ),
      );

      expect(find.text('Treino A - Peito e Tríceps'), findsOneWidget);
      expect(find.text('60 min'), findsOneWidget);
      expect(find.text('RPE 8.5'), findsOneWidget);
      expect(find.byType(WorkoutMoodIcon), findsOneWidget);
      expect(find.text('Muito forte'), findsOneWidget);
    });
  });

  group('TimelineEventCard Widget Test', () {
    testWidgets('should render event type, title, subtitle and fire onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          TimelineEventCard(
            event: tEvent,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      expect(find.text('TREINOS'), findsOneWidget);
      expect(find.text('Treino A - Peito'), findsOneWidget);
      expect(find.text('4 exercícios • 45 min'), findsOneWidget);

      await tester.tap(find.byType(TimelineEventCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('TimelineFilterBar Widget Test', () {
    testWidgets('should render filter chips for type and period', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const TimelineFilterBar(),
        ),
      );

      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Treinos'), findsOneWidget);
      expect(find.text('Peso'), findsOneWidget);
      expect(find.text('Nutrição'), findsOneWidget);
      expect(find.text('Metas'), findsOneWidget);
      expect(find.text('Tudo'), findsOneWidget);
      expect(find.text('7 dias'), findsOneWidget);
    });
  });
}
