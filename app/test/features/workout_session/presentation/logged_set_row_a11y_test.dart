import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/widgets/logged_set_row.dart';

void main() {
  Future<void> pumpRow(
    WidgetTester tester, {
    required double width,
    double textScale = 1.0,
    SetType initialType = SetType.working,
    LoggedSet? loggedSet,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: Size(width, 900),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: LoggedSetRow(
                setNumber: 1,
                initialType: initialType,
                loggedSet: loggedSet,
                defaultWeight: 80.0,
                defaultReps: 10,
                showRir: false,
                onSave: ({
                  required weightKg,
                  required repsCompleted,
                  durationSeconds,
                  rirActual,
                  required setType,
                  dropSets = const [],
                  existingSetId,
                }) async {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('A11Y-01 LoggedSetRow 48dp targets, 8dp gaps and LayoutBuilder reflow', () {
    for (final width in [320.0, 375.0, 428.0]) {
      testWidgets(
          'passes androidTapTargetGuideline & labeledTapTargetGuideline at ${width}dp (normal + drop-set + completed)',
          (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpRow(tester, width: width);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          expect(tester.takeException(), isNull);

          await pumpRow(
            tester,
            width: width,
            initialType: SetType.dropSet,
            loggedSet: const LoggedSet(
              id: 'ls-drop',
              sessionExerciseId: 'se-1',
              setNumber: 1,
              setType: SetType.dropSet,
              weightKg: 80.0,
              repsCompleted: 10,
              dropSets: [
                DropSetEntry(weightKg: 60.0, repsCompleted: 8),
              ],
            ),
          );
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          expect(tester.takeException(), isNull);
        } finally {
          handle.dispose();
        }
      });
    }

    testWidgets('maintains >= 8dp spacing between stepper controls', (tester) async {
      await pumpRow(tester, width: 320.0);

      final decWeightRect =
          tester.getRect(find.bySemanticsLabel('Diminuir carga'));
      final editWeightRect =
          tester.getRect(find.bySemanticsLabel('Editar carga: 80 kg'));
      final incWeightRect =
          tester.getRect(find.bySemanticsLabel('Aumentar carga'));

      expect(decWeightRect.width, greaterThanOrEqualTo(48));
      expect(decWeightRect.height, greaterThanOrEqualTo(48));
      expect(incWeightRect.width, greaterThanOrEqualTo(48));
      expect(incWeightRect.height, greaterThanOrEqualTo(48));
      expect(editWeightRect.left - decWeightRect.right,
          greaterThanOrEqualTo(8.0));
      expect(incWeightRect.left - editWeightRect.right,
          greaterThanOrEqualTo(8.0));
    });

    testWidgets('reflows at 320dp without overflow at textScaler 1.3 and 2.0',
        (tester) async {
      for (final scale in [1.3, 2.0]) {
        await pumpRow(
          tester,
          width: 320.0,
          textScale: scale,
          initialType: SetType.dropSet,
        );
        expect(find.text('DROP-SET'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
