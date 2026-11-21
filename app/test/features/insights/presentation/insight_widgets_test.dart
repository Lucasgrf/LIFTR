import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/insights/domain/entities/fitness_insight.dart';
import 'package:personal_fitness_os/features/insights/presentation/widgets/insight_card.dart';

void main() {
  final tInsight = FitnessInsight(
    id: 'insight-1',
    title: 'Aumento de volume detectado',
    description: 'Seu volume semanal aumentou 30%.',
    category: InsightCategory.volume,
    severity: InsightSeverity.warning,
    createdAt: DateTime(2026, 8, 23),
  );

  group('InsightCard Widget Test', () {
    testWidgets('should render insight title and description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: InsightCard(insight: tInsight),
          ),
        ),
      );

      expect(find.text('Aumento de volume detectado'), findsOneWidget);
      expect(find.text('Seu volume semanal aumentou 30%.'), findsOneWidget);
    });

    testWidgets('should fire onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: InsightCard(
              insight: tInsight,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InsightCard));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
