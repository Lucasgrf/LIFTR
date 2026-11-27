import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    bool isExpanded = true,
    VoidCallback? onRequestExpand,
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
                isExpanded: isExpanded,
                onRequestExpand: onRequestExpand,
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

    for (final width in [320.0, 375.0]) {
      testWidgets(
          'verifies >= 48dp touch targets and a11y guidelines on set type badge, Outro drop and Remover drop at ${width}dp',
          (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpRow(
            tester,
            width: width,
            initialType: SetType.dropSet,
            loggedSet: const LoggedSet(
              id: 'ls-drop-targets',
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

          final badgeFinder =
              find.bySemanticsLabel('Série drop-set. Toque para alternar tipo');
          final addAnotherDropFinder =
              find.bySemanticsLabel('Adicionar outro drop');
          final removeDropFinder = find.bySemanticsLabel('Remover drop 1');

          expect(badgeFinder, findsOneWidget);
          expect(addAnotherDropFinder, findsOneWidget);
          expect(removeDropFinder, findsOneWidget);

          for (final finder in [
            badgeFinder,
            addAnotherDropFinder,
            removeDropFinder,
          ]) {
            final size = tester.getSize(finder);
            expect(size.width, greaterThanOrEqualTo(48.0));
            expect(size.height, greaterThanOrEqualTo(48.0));
          }

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

    testWidgets(
        'A11Y-02 completed set check button renders Material + Ink ripple surface',
        (tester) async {
      await pumpRow(
        tester,
        width: 375.0,
        loggedSet: const LoggedSet(
          id: 'ls-1',
          sessionExerciseId: 'se-1',
          setNumber: 1,
          weightKg: 80.0,
          repsCompleted: 10,
        ),
      );

      final checkInkWell = find.ancestor(
        of: find.byIcon(Icons.check_rounded),
        matching: find.byType(InkWell),
      );
      expect(checkInkWell, findsOneWidget);
      expect(
        find.ancestor(of: checkInkWell, matching: find.byType(Material)),
        findsWidgets,
      );
      expect(
        find.descendant(of: checkInkWell, matching: find.byType(Ink)),
        findsOneWidget,
      );
    });
  });

  group('Compact LoggedSetRow a11y, single-node Semantics and 48dp targets', () {
    for (final width in [320.0, 375.0]) {
      testWidgets(
          'passes androidTapTargetGuideline & labeledTapTargetGuideline in compact mode (pending, completed, drop-set) at ${width}dp',
          (tester) async {
        final handle = tester.ensureSemantics();
        try {
          var expandedCalls = 0;

          // Pending compact row
          await pumpRow(
            tester,
            width: width,
            isExpanded: false,
            onRequestExpand: () => expandedCalls++,
          );
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

          final pendingNode = tester.getSemantics(
            find.bySemanticsLabel(
              'Série 1, 80 kg, 10 repetições, pendente. Toque duas vezes para editar',
            ),
          );
          expect(pendingNode.flagsCollection.isButton, isTrue);
          expect(
            pendingNode.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
          );
          expect(pendingNode.hintOverrides?.onTapHint, 'expandir para editar');
          expect(pendingNode.childrenCount, 0);

          final pendingCheckFinder =
              find.bySemanticsLabel('Concluir série 1');
          final pendingCheckNode = tester.getSemantics(pendingCheckFinder);
          expect(pendingCheckNode.flagsCollection.isButton, isTrue);
          expect(pendingCheckNode.childrenCount, 0);
          expect(
            tester.getSize(pendingCheckFinder).width,
            greaterThanOrEqualTo(48.0),
          );
          expect(
            tester.getSize(pendingCheckFinder).height,
            greaterThanOrEqualTo(48.0),
          );

          await tester.tap(
            find.bySemanticsLabel(
              'Série 1, 80 kg, 10 repetições, pendente. Toque duas vezes para editar',
            ),
          );
          expect(expandedCalls, 1);

          // Completed drop-set compact row
          await pumpRow(
            tester,
            width: width,
            isExpanded: false,
            initialType: SetType.dropSet,
            onRequestExpand: () => expandedCalls++,
            loggedSet: const LoggedSet(
              id: 'ls-compact-drop',
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

          const expectedDropLabel =
              'Série 1, drop-set, 80 kg, 10 repetições, drop 60 kg por 8 repetições, concluída. Toque duas vezes para editar';
          final dropExpandFinder = find.bySemanticsLabel(expectedDropLabel);
          final dropNode = tester.getSemantics(dropExpandFinder);
          expect(dropNode.childrenCount, 0);
          expect(dropNode.hintOverrides?.onTapHint, 'expandir para editar');
          expect(
            tester.getSize(dropExpandFinder).height,
            greaterThanOrEqualTo(48.0),
          );
          // Informative badge & drop summary must NOT expose separate interactive nodes
          expect(find.bySemanticsLabel('Série drop-set. Toque para alternar tipo'), findsNothing);
          expect(find.bySemanticsLabel('Adicionar outro drop'), findsNothing);
          expect(find.bySemanticsLabel('Remover drop 1'), findsNothing);

          final unmarkFinder = find.bySemanticsLabel('Desmarcar série 1');
          final unmarkNode = tester.getSemantics(unmarkFinder);
          expect(unmarkNode.childrenCount, 0);
          expect(tester.getSize(unmarkFinder).width, greaterThanOrEqualTo(48.0));
          expect(tester.getSize(unmarkFinder).height, greaterThanOrEqualTo(48.0));

          // Verify zero duplicate/repeated child nodes under LoggedSetRow
          final rootSemantics = tester.getSemantics(find.byType(LoggedSetRow));
          final collectedLabels = <String>[];
          void collect(SemanticsNode node) {
            if (node.label.isNotEmpty) collectedLabels.add(node.label);
            node.visitChildren((child) {
              collect(child);
              return true;
            });
          }

          collect(rootSemantics);
          expect(
            collectedLabels,
            unorderedEquals([expectedDropLabel, 'Desmarcar série 1']),
          );
        } finally {
          handle.dispose();
        }
      });
    }
  });
}
