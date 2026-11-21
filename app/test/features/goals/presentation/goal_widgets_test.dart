import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_category.dart';
import 'package:personal_fitness_os/features/goals/domain/entities/goal_status.dart';
import 'package:personal_fitness_os/features/goals/presentation/widgets/goal_card.dart';
import 'package:personal_fitness_os/features/goals/presentation/widgets/goal_progress_bar.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  final tGoal = Goal(
    id: 'g-1',
    title: 'Chegar a 80kg',
    description: 'Cutting para o verão',
    category: GoalCategory.weight,
    initialValue: 86.0,
    targetValue: 80.0,
    currentValue: 83.0,
    unit: 'kg',
    startedAt: DateTime(2026, 8, 1),
    deadline: DateTime(2026, 12, 1),
    status: GoalStatus.active,
  );

  Widget createWidgetUnderTest(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('GoalProgressBar Widget Test', () {
    testWidgets('should render progress percentage and start/target labels', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          GoalProgressBar(goal: tGoal),
        ),
      );

      expect(find.text('Progresso'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Início: 86.0 kg'), findsOneWidget);
      expect(find.text('Alvo: 80.0 kg'), findsOneWidget);
    });
  });

  group('GoalCard Widget Test', () {
    testWidgets('should render category, status, title, current value and deadline', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          GoalCard(
            goal: tGoal,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      expect(find.text('PESO CORPORAL'), findsOneWidget);
      expect(find.text('Ativa'), findsOneWidget);
      expect(find.text('Chegar a 80kg'), findsOneWidget);
      expect(find.text('Cutting para o verão'), findsOneWidget);
      expect(find.text('83.0 kg'), findsOneWidget);

      await tester.tap(find.byType(GoalCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
