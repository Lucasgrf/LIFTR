import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/history_workout_card.dart';
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

  Widget createWidgetUnderTest(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('HistoryWorkoutCard Widget Test', () {
    testWidgets('should render workout name, duration, RPE and mood',
        (tester) async {
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
}
