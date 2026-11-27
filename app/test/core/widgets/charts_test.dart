import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/theme/app_motion.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/widgets/charts/chart_models.dart';
import 'package:personal_fitness_os/core/widgets/charts/exercise_load_progression_chart.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  List<ChartSeries> buildSeries() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return [
      ChartSeries(
        id: 'max_load',
        label: 'Carga máx',
        color: const Color(0xFF72A987),
        points: [
          ChartPoint(date: weekAgo, value: 80.0),
          ChartPoint(date: now, value: 85.0),
        ],
      ),
      ChartSeries(
        id: 'e1rm',
        label: '1RM est',
        color: const Color(0xFF6BAED6),
        isDashed: true,
        points: [
          ChartPoint(date: weekAgo, value: 106.7),
          ChartPoint(date: now, value: 107.6),
        ],
      ),
    ];
  }

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
              ExerciseLoadProgressionChart(series: buildSeries()),
              theme: theme,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('PROGRESSÃO DE CARGA'), findsOneWidget);
          expect(find.text('Carga máx'), findsOneWidget);
          expect(find.text('1RM est'), findsOneWidget);
          expect(
            find.bySemanticsLabel(RegExp('^Gráfico de progressão de carga')),
            findsOneWidget,
          );
        }
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
        'ExerciseLoadProgressionChart honors MediaQuery disableAnimations on LineChart duration',
        (tester) async {
      final series = buildSeries();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: createWidgetUnderTest(
            ExerciseLoadProgressionChart(series: series),
          ),
        ),
      );
      await tester.pumpAndSettle();

      var chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.duration, Duration.zero);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: createWidgetUnderTest(
            ExerciseLoadProgressionChart(series: series),
          ),
        ),
      );
      await tester.pumpAndSettle();

      chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.duration, const AppMotion().fast);
    });
  });
}
