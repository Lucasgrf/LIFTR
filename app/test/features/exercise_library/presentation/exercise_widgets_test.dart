import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/widgets/exercise_card.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/widgets/muscle_filter_chips.dart';

void main() {
  const tExercise = Exercise(
    id: '1',
    name: 'Supino Reto com Barra',
    primaryMuscleGroup: 'chest',
    secondaryMuscles: ['triceps', 'anterior_deltoid'],
    equipment: 'barbell',
    movementPattern: 'horizontal_push',
    isCustom: false,
  );

  Widget createWidgetUnderTest(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('ExerciseCard Widget Test', () {
    testWidgets('should display exercise name, muscle badge and equipment', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(const ExerciseCard(exercise: tExercise)),
      );

      expect(find.text('Supino Reto com Barra'), findsOneWidget);
      expect(find.text('Peito · Barra'), findsOneWidget);
    });

    testWidgets('should call onTap callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          ExerciseCard(exercise: tExercise, onTap: () => tapped = true),
        ),
      );

      await tester.tap(find.text('Supino Reto com Barra'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('MuscleFilterChips Widget Test', () {
    testWidgets('should render muscle option chips', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const MuscleFilterChips()));

      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Peito'), findsOneWidget);
      expect(find.text('Costas'), findsOneWidget);
    });
  });
}
