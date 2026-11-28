import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/extensions/date_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/utils/pt_br_copy_utils.dart';
import 'package:personal_fitness_os/core/widgets/liftr_eyebrow.dart';
import 'package:personal_fitness_os/core/widgets/liftr_list_group.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/history/presentation/providers/history_providers.dart';
import 'package:personal_fitness_os/features/history/presentation/widgets/progress_exercises_view.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/session_exercise.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/workout_session.dart';

Directory _resolveLibDir() {
  final direct = Directory('lib');
  if (direct.existsSync()) return direct;
  return Directory('app/lib');
}

List<File> _dartFilesIn(Directory dir) {
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  group('Phase 8 — VIS-02 Eyebrow pruning & sentence-case headers', () {
    test('prunes redundant ALL-CAPS eyebrows across lib/', () {
      final libDir = _resolveLibDir();
      final files = _dartFilesIn(libDir);
      final eyebrowRegex = RegExp(r'AppTypography\.eyebrow|eyebrow:');

      var eyebrowOccurrences = 0;
      for (final file in files) {
        final content = file.readAsStringSync();
        eyebrowOccurrences += eyebrowRegex.allMatches(content).length;
      }

      // Pruned from ~52 sites down to only intentional contextual call sites,
      // and AppTypography.eyebrow( is centralized strictly in LiftrEyebrow.
      expect(eyebrowOccurrences, lessThanOrEqualTo(10));
      for (final file in files) {
        final content = file.readAsStringSync();
        if (content.contains('AppTypography.eyebrow(')) {
          expect(
            file.path.endsWith('liftr_eyebrow.dart'),
            isTrue,
            reason:
                'Direct AppTypography.eyebrow() call outside LiftrEyebrow in ${file.path}',
          );
        }
      }

      final featuresDir = Directory('${libDir.path}/features');
      const removedEyebrows = <String>[
        'LIFTR · HOJE',
        'SESSÃO FINALIZADA',
        'ENCERRAMENTO',
        'EVOLUÇÃO OBJETIVA',
        'PROGRAMA ATIVO',
      ];
      for (final file in _dartFilesIn(featuresDir)) {
        final content = file.readAsStringSync();
        for (final forbidden in removedEyebrows) {
          if (forbidden == 'PROGRAMA ATIVO' &&
              file.path.endsWith('training_plan_detail_screen.dart')) {
            // Status badge pill ("PROGRAMA ATIVO" / "ARQUIVADO"), not an eyebrow.
            continue;
          }
          expect(
            content.contains("'$forbidden'"),
            isFalse,
            reason: 'Found removed eyebrow "$forbidden" in ${file.path}',
          );
        }
      }
    });

    testWidgets(
      'LiftrListGroup header renders in sentence case (not 1.2 tracked eyebrow)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(
              body: LiftrListGroup(
                header: 'Dados corporais e objetivo',
                children: [LiftrListRow(label: 'Peso', value: '80 kg')],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final headerFinder = find.text('Dados corporais e objetivo');
        expect(headerFinder, findsOneWidget);
        final textWidget = tester.widget<Text>(headerFinder);
        expect(textWidget.style?.letterSpacing, isNot(1.2));
      },
    );

    testWidgets(
      'LiftrEyebrow preserves sentence-case copy and HTML type scale',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(body: LiftrEyebrow('Compartilhar programa')),
          ),
        );
        await tester.pumpAndSettle();

        final rendered = find.text('Compartilhar programa');
        expect(rendered, findsOneWidget);
        final widget = tester.widget<Text>(rendered);
        expect(widget.style?.fontSize, 13);
        expect(widget.style?.letterSpacing, 0);
      },
    );
  });

  group('Phase 8 — COPY-01 PT-BR mappers, pluralization & vendor-free copy', () {
    test('pluralize handles singular and plural counts cleanly', () {
      expect(pluralize(0, 'série', 'séries'), '0 séries');
      expect(pluralize(1, 'série', 'séries'), '1 série');
      expect(pluralize(2, 'série', 'séries'), '2 séries');
      expect(pluralize(1, 'sessão', 'sessões'), '1 sessão');
      expect(pluralize(3, 'sessão', 'sessões'), '3 sessões');
    });

    test('formatWeightKgPtBr formats comma decimals and trims trailing .0', () {
      expect(formatWeightKgPtBr(80.0), '80 kg');
      expect(formatWeightKgPtBr(82.5), '82,5 kg');
      expect(formatWeightKgPtBr(-5.0), '-5 kg');
      expect(formatWeightKgPtBr(12.25, decimals: 2), '12,25 kg');
    });

    test(
      'PT-BR enum mappers translate movement patterns, equipment and sex',
      () {
        expect(
          formatMovementPatternPtBr('horizontal_push'),
          'Empurrar horizontal',
        );
        expect(formatMovementPatternPtBr('hinge'), 'Dobradiça de quadril');
        expect(formatMovementPatternPtBr('vertical_pull'), 'Puxar vertical');
        expect(formatMovementPatternPtBr(null), 'Não informado');

        expect(formatEquipmentPtBr('barbell'), 'Barra');
        expect(formatEquipmentPtBr('dumbbell'), 'Halteres');
        expect(formatEquipmentPtBr('cable'), 'Polia');
        expect(formatEquipmentPtBr('bodyweight'), 'Peso corporal');
        expect(formatEquipmentPtBr('ez_bar'), 'Barra W');
        expect(formatEquipmentPtBr(null), '');

        expect(formatBiologicalSexPtBr('M'), 'Masculino');
        expect(formatBiologicalSexPtBr('F'), 'Feminino');
        expect(formatBiologicalSexPtBr(null), 'Não informado');
      },
    );

    test(
      'forbids vendor names, mocked phone, and PT-BR typos in feature UI/datasource code',
      () {
        final featuresDir = Directory('${_resolveLibDir().path}/features');
        const forbiddenLiterals = <String>[
          'Gemini',
          'GitHub Releases',
          'Deltóide',
          'Clique ',
          'CSV / JSON',
          '+55 (11) 9****-4821',
        ];

        for (final file in _dartFilesIn(featuresDir)) {
          final codeLines = file
              .readAsLinesSync()
              .where((line) => !line.trimLeft().startsWith('//'))
              .join('\n');
          for (final term in forbiddenLiterals) {
            expect(
              codeLines.contains(term),
              isFalse,
              reason: 'Found forbidden copy "$term" in ${file.path}',
            );
          }
        }
      },
    );
  });

  group(
    'Phase 8 — PERF-02 Async images, cached DateFormat, and derived list state',
    () {
      test(
        'presentation files avoid existsSync() and inline DateFormat() in build',
        () {
          final featuresDir = Directory('${_resolveLibDir().path}/features');
          final presentationFiles = _dartFilesIn(featuresDir)
              .where(
                (f) => f.path.contains(
                  '${Platform.pathSeparator}presentation${Platform.pathSeparator}',
                ),
              )
              .toList();

          expect(presentationFiles, isNotEmpty);
          final inlineDateFormatRegex = RegExp(r'\bDateFormat\s*\(');
          for (final file in presentationFiles) {
            final content = file.readAsStringSync();
            expect(
              content.contains('existsSync('),
              isFalse,
              reason: 'Found synchronous existsSync() in ${file.path}',
            );
            expect(
              inlineDateFormatRegex.hasMatch(content),
              isFalse,
              reason: 'Found inline DateFormat() in ${file.path}',
            );
          }

          for (final screenName in <String>[
            'profile/presentation/screens/profile_screen.dart',
            'dashboard/presentation/screens/dashboard_screen.dart',
          ]) {
            final avatarFile = File('${featuresDir.path}/$screenName');
            final content = avatarFile.readAsStringSync();
            expect(content, contains('memCacheWidth:'));
            expect(content, contains('memCacheHeight:'));
          }
        },
      );

      test('ptBrDateFormat returns a single cached instance per pattern', () {
        final first = ptBrDateFormat('dd/MM');
        final second = ptBrDateFormat('dd/MM');
        expect(identical(first, second), isTrue);
        expect(first.format(DateTime(2026, 11, 20)), '20/11');
      });

      testWidgets(
        'ProgressExercisesView filters with the HTML chips without refetching history',
        (tester) async {
          final now = DateTime(2026, 11, 20, 10);
          final exercises = List<SessionExercise>.generate(6, (idx) {
            final name = idx == 0
                ? 'Supino Reto'
                : 'Exercício Teste ${idx + 1}';
            return SessionExercise(
              id: 'se-$idx',
              sessionId: 'sess-1',
              exerciseId: 'ex-$idx',
              sortOrder: idx,
              exercise: Exercise(
                id: 'ex-$idx',
                name: name,
                primaryMuscleGroup: 'chest',
              ),
              sets: [
                LoggedSet(
                  id: 'set-$idx',
                  sessionExerciseId: 'se-$idx',
                  setNumber: 1,
                  setType: SetType.working,
                  weightKg: 60.0 + idx * 5,
                  repsCompleted: 10,
                  completedAt: now,
                ),
              ],
            );
          });

          final session = WorkoutSession(
            id: 'sess-1',
            userId: 'u-1',
            workoutName: 'Full Body',
            startedAt: now.subtract(const Duration(hours: 1)),
            completedAt: now,
            durationSeconds: 3600,
            status: SessionStatus.completed,
            exercises: exercises,
          );

          var historyFetches = 0;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                historyListProvider.overrideWith((_) async {
                  historyFetches++;
                  return [session];
                }),
              ],
              child: MaterialApp(
                theme: AppTheme.dark(),
                home: const Scaffold(
                  body: SingleChildScrollView(child: ProgressExercisesView()),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(historyFetches, 1);
          expect(find.text('Supino Reto'), findsOneWidget);
          expect(find.text('Exercício Teste 2'), findsOneWidget);

          await tester.tap(find.text('Travado, 0'));
          await tester.pumpAndSettle();

          expect(historyFetches, 1);
          expect(find.text('Supino Reto'), findsNothing);
          expect(find.text('Exercício Teste 2'), findsNothing);

          await tester.tap(find.text('Todos'));
          await tester.pumpAndSettle();
          expect(historyFetches, 1);
          expect(find.text('Supino Reto'), findsOneWidget);
        },
      );
    },
  );
}
