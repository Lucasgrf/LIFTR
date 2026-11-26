import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/widgets/charts/exercise_load_progression_chart.dart';
import 'package:personal_fitness_os/features/history/domain/entities/exercise_history_record.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  final tRecords = [
    ExerciseHistoryRecord(
      sessionId: 's-1',
      sessionName: 'Treino A',
      date: DateTime.now().subtract(const Duration(days: 7)),
      setsCount: 3,
      topWeightKg: 80.0,
      topReps: 10,
      bestEstimated1Rm: 106.7,
    ),
    ExerciseHistoryRecord(
      sessionId: 's-2',
      sessionName: 'Treino A',
      date: DateTime.now(),
      setsCount: 4,
      topWeightKg: 85.0,
      topReps: 8,
      bestEstimated1Rm: 107.6,
    ),
  ];

  Widget createWidgetUnderTest(Widget child, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? AppTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('ExerciseLoadProgressionChart Widget Test', () {
    testWidgets(
        'should render chart, legend items and semantics in dark and light themes',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        for (final theme in [AppTheme.dark(), AppTheme.light()]) {
          await tester.pumpWidget(
            createWidgetUnderTest(
              ExerciseLoadProgressionChart(records: tRecords),
              theme: theme,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('PROGRESSÃO DE CARGA'), findsOneWidget);
          expect(find.text('Carga máx'), findsOneWidget);
          expect(find.text('1RM est'), findsOneWidget);
          expect(
            find.bySemanticsLabel('Gráfico de progressão de carga'),
            findsOneWidget,
          );
        }
      } finally {
        semantics.dispose();
      }
    });
  });
}
