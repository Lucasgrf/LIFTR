import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_entry.dart';
import 'package:personal_fitness_os/features/body/domain/entities/weight_stats.dart';
import 'package:personal_fitness_os/features/body/presentation/widgets/weight_entry_list_tile.dart';
import 'package:personal_fitness_os/features/body/presentation/widgets/weight_stats_summary_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  final tEntry = WeightEntry(
    id: 'w-1',
    weightKg: 82.4,
    measuredAt: DateTime(2026, 8, 22),
    notes: 'Jejum pela manhã',
  );

  final tStatsGaining = WeightStats(
    latestEntry: tEntry,
    average7Days: 82.1,
    average14Days: 81.8,
    average30Days: 81.2,
    trend: WeightTrend.gaining,
    deltaVsPreviousWeekKg: 0.3,
  );

  final tStatsLosing = WeightStats(
    latestEntry: tEntry,
    average7Days: 80.0,
    average14Days: 80.5,
    average30Days: 81.5,
    trend: WeightTrend.losing,
    deltaVsPreviousWeekKg: -0.5,
  );

  Widget createWidgetUnderTest(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('WeightStatsSummaryCard Widget Test', () {
    testWidgets('should render current weight, 7d/14d/30d averages and gaining trend badge', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          WeightStatsSummaryCard(stats: tStatsGaining),
        ),
      );

      expect(find.text('82.4'), findsOneWidget);
      expect(find.text('Em alta ↗'), findsOneWidget);
      expect(find.text('82.1 kg'), findsOneWidget);
      expect(find.text('81.8 kg'), findsOneWidget);
      expect(find.text('81.2 kg'), findsOneWidget);
      expect(find.text('+0.3 kg / sem'), findsOneWidget);
    });

    testWidgets('should render losing trend badge and delta', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          WeightStatsSummaryCard(stats: tStatsLosing),
        ),
      );

      expect(find.text('Em queda ↘'), findsOneWidget);
      expect(find.text('-0.5 kg / sem'), findsOneWidget);
    });

    testWidgets('should invoke onTapHistory when card is tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          WeightStatsSummaryCard(
            stats: tStatsGaining,
            onTapHistory: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(WeightStatsSummaryCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('WeightEntryListTile Widget Test', () {
    testWidgets('should render weight, notes and formatted date', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          WeightEntryListTile(
            entry: tEntry,
            onDelete: () {},
          ),
        ),
      );

      expect(find.text('82.4 kg'), findsOneWidget);
      expect(find.text('Jejum pela manhã'), findsOneWidget);
      expect(find.text(tEntry.measuredAt.formatFull()), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('should invoke onDelete when delete dialog is confirmed', (tester) async {
      bool deleted = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          WeightEntryListTile(
            entry: tEntry,
            onDelete: () {
              deleted = true;
            },
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Excluir pesagem'), findsOneWidget);
      expect(find.text('Excluir'), findsOneWidget);

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });
  });
}
