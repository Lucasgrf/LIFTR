import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/dashboard/presentation/widgets/today_workout_banner.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  const tWorkout = Workout(
    id: 'w-1',
    trainingPlanId: 'p-1',
    name: 'Treino A - Peito e Tríceps',
    dayOfWeek: 6,
  );

  final tSession = WorkoutSession(
    id: 's-1',
    userId: 'u-1',
    workoutName: 'Treino A - Peito e Tríceps',
    startedAt: DateTime(2026, 8, 22, 10, 0),
  );

  Widget createWidgetUnderTest(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('TodayWorkoutBanner Widget Test', () {
    testWidgets(
      'should render active session banner when ongoing session exists',
      (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            TodayWorkoutBanner(
              activeSession: tSession,
              onStartWorkout: (_) async {},
            ),
          ),
        );

        expect(find.text('SESSÃO EM ANDAMENTO'), findsOneWidget);
        expect(find.text('Treino A - Peito e Tríceps'), findsOneWidget);
        expect(find.text('0 séries registradas.'), findsOneWidget);
      },
    );

    testWidgets(
      'should render today workout banner when scheduled workout exists',
      (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            TodayWorkoutBanner(
              todayWorkout: tWorkout,
              onStartWorkout: (_) async {},
            ),
          ),
        );

        expect(find.text('Treino A - Peito e Tríceps'), findsOneWidget);
        expect(find.text('0 exercícios, 0 séries.'), findsOneWidget);
      },
    );
  });
}
