import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/body/domain/entities/body_measurement.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/measurement_providers.dart';
import 'package:personal_fitness_os/features/body/presentation/screens/body_measurements_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  final tMeasurement = BodyMeasurement(
    id: 'm-1',
    userId: 'u-1',
    measuredAt: DateTime(2026, 8, 22),
    waist: 82.0,
    chest: 104.0,
    armRight: 38.5,
  );

  Widget createWidgetUnderTest({List<BodyMeasurement> measurements = const []}) {
    return ProviderScope(
      overrides: [
        measurementsListProvider.overrideWith((ref) => Future.value(measurements)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const BodyMeasurementsScreen(),
      ),
    );
  }

  group('BodyMeasurementsScreen Widget Test', () {
    testWidgets('should render empty state when no measurements', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(measurements: []));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma medida registrada'), findsOneWidget);
      expect(find.text('Registrar Medidas'), findsOneWidget);
    });

    testWidgets('should render comparison card and history list when measurements exist', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(measurements: [tMeasurement]));
      await tester.pumpAndSettle();

      expect(find.text('ÚLTIMA AVALIAÇÃO'), findsOneWidget);
      expect(find.text('HISTÓRICO DE MEDIÇÕES'), findsOneWidget);
      expect(find.text('82.0 cm'), findsOneWidget);
      expect(find.text('104.0 cm'), findsOneWidget);
      expect(find.text('38.5 cm'), findsOneWidget);
    });
  });
}
