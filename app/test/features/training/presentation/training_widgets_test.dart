import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/training/domain/entities/set_template.dart';
import 'package:personal_fitness_os/features/training/domain/entities/workout.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/set_template_row.dart';
import 'package:personal_fitness_os/features/training/presentation/widgets/workout_card.dart';

void main() {
  const tSetTemplate = SetTemplate(
    id: 'st-1',
    workoutExerciseId: 'we-1',
    setNumber: 1,
    setType: SetType.working,
    targetRepsMin: 8,
    targetRepsMax: 12,
    targetRirMin: 1,
    targetRirMax: 2,
    restSeconds: 90,
  );

  const tWorkout = Workout(
    id: 'w-1',
    trainingPlanId: 'p-1',
    name: 'Treino A - Peito e Tríceps',
    dayOfWeek: 1,
  );

  Widget createWidgetUnderTest(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('SetTemplateRow Widget Test', () {
    testWidgets('should render set number, reps, RIR and rest seconds', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const SetTemplateRow(template: tSetTemplate),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('8-12 reps'), findsOneWidget);
      expect(find.text('RIR 1-2'), findsOneWidget);
      expect(find.text('90s'), findsOneWidget);
    });
  });

  group('WorkoutCard Widget Test', () {
    testWidgets('should render workout name and day of week label', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const WorkoutCard(workout: tWorkout),
        ),
      );

      expect(find.text('Treino A - Peito e Tríceps'), findsOneWidget);
      expect(find.text('Segunda-feira'), findsOneWidget);
    });
  });
}
