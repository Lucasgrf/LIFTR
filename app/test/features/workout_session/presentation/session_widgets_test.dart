import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/logged_set_row.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/rest_timer_widget.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/session_exercise_card.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/session_timer_header.dart';

void main() {
  const tExercise = Exercise(
    id: 'ex-1',
    name: 'Supino Reto com Barra',
    primaryMuscleGroup: 'chest',
    equipment: 'barbell',
  );

  const tLoggedSet = LoggedSet(
    id: 'ls-1',
    sessionExerciseId: 'se-1',
    setNumber: 1,
    setType: SetType.working,
    weightKg: 80.0,
    repsCompleted: 10,
    rirActual: 2,
  );

  const tSessionExercise = SessionExercise(
    id: 'se-1',
    sessionId: 's-1',
    exerciseId: 'ex-1',
    exercise: tExercise,
    targetRestSeconds: 90,
    targetSetsCount: 3,
    sets: [tLoggedSet],
  );

  final tSession = WorkoutSession(
    id: 's-1',
    userId: 'u-1',
    workoutName: 'Treino A - Peito e Tríceps',
    startedAt: DateTime.now().subtract(const Duration(minutes: 25)),
    durationSeconds: 1500,
    exercises: [tSessionExercise],
  );

  Widget createWidgetUnderTest(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('SessionTimerHeader Widget Test', () {
    testWidgets('should render elapsed time, working sets count and volume in kg', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          SessionTimerHeader(
            session: tSession,
            elapsedSeconds: 1500, // 25:00
          ),
        ),
      );

      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('1 séries válidas'), findsOneWidget);
      expect(find.text('800 kg'), findsOneWidget);
    });
  });

  group('LoggedSetRow Widget Test', () {
    testWidgets('should render set number, weight and reps when logged', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          LoggedSetRow(
            setNumber: 1,
            loggedSet: tLoggedSet,
            onSave: ({
              required weightKg,
              required repsCompleted,
              rirActual,
              required setType,
            }) async {},
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('80'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('RIR 2'), findsOneWidget);
    });
  });

  group('SessionExerciseCard Widget Test', () {
    testWidgets('should render exercise name, muscle badge and target sets count', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          SessionExerciseCard(
            sessionExercise: tSessionExercise,
            onLogSet: ({
              required sessionExerciseId,
              required setNumber,
              required setType,
              required weightKg,
              required repsCompleted,
              rirActual,
              restSeconds = 90,
            }) async {},
          ),
        ),
      );

      expect(find.text('Supino Reto com Barra'), findsOneWidget);
      expect(find.text('CHEST'), findsOneWidget);
      expect(find.text('1/3 séries'), findsOneWidget);
    });
  });

  group('RestTimerWidget Widget Test', () {
    testWidgets('should render countdown and skip button when running', (tester) async {
      final container = ProviderContainer();
      container.read(restTimerNotifierProvider.notifier).start(
            90,
            exerciseName: 'Supino Reto',
            setNumber: 1,
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(
              body: RestTimerWidget(),
            ),
          ),
        ),
      );

      expect(find.text('01:30'), findsOneWidget);
      expect(find.text('Supino Reto'), findsOneWidget);
      expect(find.text('Pular'), findsOneWidget);
      expect(find.text('+30s'), findsOneWidget);

      container.read(restTimerNotifierProvider.notifier).stop();
      container.dispose();
    });
  });
}
