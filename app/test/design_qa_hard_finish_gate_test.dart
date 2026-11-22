import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/exercise_library/domain/entities/exercise.dart';
import 'package:personal_fitness_os/features/exercise_library/presentation/widgets/exercise_diagram.dart';

void main() {
  group('Fase 5 — Hard Finish Gate (Guardrails Estáticos)', () {
    List<File> dartFilesIn(String relativeDir) {
      final dir = Directory(relativeDir);
      if (!dir.existsSync()) return const [];
      return dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
    }

    test('zero legacy #6C63FF, Inter font, or .withOpacity in app/lib', () {
      final files = dartFilesIn('lib');
      expect(files, isNotEmpty);

      for (final file in files) {
        final content = file.readAsStringSync();
        expect(
          RegExp(r'6[cC]63[fF]{2}').hasMatch(content),
          isFalse,
          reason: '${file.path} still references legacy purple #6C63FF',
        );
        expect(
          RegExp(r"""fontFamily:\s*['"]Inter['"]""").hasMatch(content),
          isFalse,
          reason: '${file.path} still references Inter fontFamily',
        );
        expect(
          content.contains('.withOpacity('),
          isFalse,
          reason: '${file.path} still uses deprecated .withOpacity(',
        );
      }
    });

    test('top-level core/widgets/*.dart never import features/', () {
      final coreWidgetsDir = Directory('lib/core/widgets');
      final files = coreWidgetsDir
          .listSync(recursive: false)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      expect(files, isNotEmpty);

      for (final file in files) {
        final content = file.readAsStringSync();
        expect(
          content.contains('/features/'),
          isFalse,
          reason: '${file.path} imports feature code directly',
        );
      }
    });
  });

  group('Fase 5 — Vector Kinematics SVGs & ExerciseDiagram', () {
    test('all 8 modular SVG assets exist with valid viewBox and palette', () {
      for (final pattern in MovementKinematicsPattern.values) {
        final file = File(pattern.assetPath);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Missing SVG asset: ${pattern.assetPath}',
        );
        final content = file.readAsStringSync();
        expect(content.trimLeft(), startsWith('<svg'));
        expect(content, contains('viewBox="0 0 96 96"'));
        expect(content.toUpperCase(), isNot(contains('6C63FF')));
      }
    });

    test('resolveMovementPattern maps seeded movementPattern and fallbacks', () {
      const mapping = <String, MovementKinematicsPattern>{
        'horizontal_push': MovementKinematicsPattern.pushHorizontal,
        'vertical_push': MovementKinematicsPattern.pushVertical,
        'horizontal_pull': MovementKinematicsPattern.pullHorizontal,
        'vertical_pull': MovementKinematicsPattern.pullVertical,
        'squat': MovementKinematicsPattern.squat,
        'lunge': MovementKinematicsPattern.squat,
        'hip_hinge': MovementKinematicsPattern.hinge,
        'rotation': MovementKinematicsPattern.coreCarry,
        'carry': MovementKinematicsPattern.coreCarry,
        'cardio': MovementKinematicsPattern.coreCarry,
        'isolation': MovementKinematicsPattern.isolation,
      };

      for (final entry in mapping.entries) {
        final ex = Exercise(
          id: 'ex-${entry.key}',
          name: entry.key,
          primaryMuscleGroup: 'chest',
          movementPattern: entry.key,
        );
        expect(resolveMovementPattern(ex), entry.value);
      }

      // Fallbacks when movementPattern is null
      expect(
        resolveMovementPattern(
          const Exercise(id: 'f1', name: 'A', primaryMuscleGroup: 'chest'),
        ),
        MovementKinematicsPattern.pushHorizontal,
      );
      expect(
        resolveMovementPattern(
          const Exercise(id: 'f2', name: 'B', primaryMuscleGroup: 'biceps'),
        ),
        MovementKinematicsPattern.isolation,
      );
      expect(
        resolveMovementPattern(
          const Exercise(id: 'f3', name: 'C', primaryMuscleGroup: 'hamstrings'),
        ),
        MovementKinematicsPattern.hinge,
      );
    });

    testWidgets(
        'ExerciseDiagram renders all 8 kinematics patterns in Dark and Light themes without errors',
        (tester) async {
      final exercises = [
        for (final entry in {
          'horizontal_push': 'Supino Reto',
          'vertical_push': 'Desenvolvimento Militar',
          'horizontal_pull': 'Remada Curvada',
          'vertical_pull': 'Puxada Alta',
          'squat': 'Agachamento Livre',
          'hip_hinge': 'Levantamento Terra Romeno',
          'carry': 'Prancha / Farmer Walk',
          'isolation': 'Rosca Direta',
        }.entries)
          Exercise(
            id: entry.key,
            name: entry.value,
            primaryMuscleGroup: 'chest',
            movementPattern: entry.key,
          ),
      ];

      for (final theme in [AppTheme.dark(), AppTheme.light()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final ex in exercises) ExerciseDiagram(exercise: ex),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ExerciseDiagram), findsNWidgets(8));
        expect(find.byType(SvgPicture), findsNWidgets(8));
        expect(tester.takeException(), isNull);
      }
    });
  });
}
