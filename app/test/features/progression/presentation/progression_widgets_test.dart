import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/progression/domain/entities/progression_recommendation.dart';
import 'package:personal_fitness_os/features/progression/presentation/widgets/progression_badge.dart';
import 'package:personal_fitness_os/features/progression/presentation/widgets/progression_recommendation_banner.dart';

void main() {
  const tIncreaseRec = ProgressionRecommendation(
    type: ProgressionType.increase,
    suggestedWeightKg: 82.5,
    weightDeltaKg: 2.5,
    rationale: '🎯 Meta atingida! Suba 2.5 kg.',
    previousSummary: '80.0 kg × 12, 12, 12 reps',
  );

  const tMaintainRec = ProgressionRecommendation(
    type: ProgressionType.maintain,
    suggestedWeightKg: 80.0,
    weightDeltaKg: 0.0,
    rationale: '💪 Dentro da faixa alvo. Mantenha 80 kg.',
    previousSummary: '80.0 kg × 10, 10 reps',
  );

  Widget createWidgetUnderTest(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('ProgressionBadge Widget Test', () {
    testWidgets('should render increase badge with delta and icon', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const ProgressionBadge(recommendation: tIncreaseRec),
        ),
      );

      expect(find.text('+2.5 kg'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    });

    testWidgets('should render maintain badge', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const ProgressionBadge(recommendation: tMaintainRec),
        ),
      );

      expect(find.text('Manter'), findsOneWidget);
      expect(find.byIcon(Icons.trending_flat_rounded), findsOneWidget);
    });
  });

  group('ProgressionRecommendationBanner Widget Test', () {
    testWidgets('should render rationale, badge, and previous summary', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const ProgressionRecommendationBanner(recommendation: tIncreaseRec),
        ),
      );

      expect(find.text('🎯 Meta atingida! Suba 2.5 kg.'), findsOneWidget);
      expect(find.text('Anterior: 80.0 kg × 12, 12, 12 reps'), findsOneWidget);
      expect(find.text('+2.5 kg'), findsOneWidget);
    });
  });
}
