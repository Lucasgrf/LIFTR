import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/features/body/domain/entities/photo_pose.dart';
import 'package:personal_fitness_os/features/body/domain/entities/progress_photo.dart';
import 'package:personal_fitness_os/features/body/presentation/providers/photo_providers.dart';
import 'package:personal_fitness_os/features/body/presentation/screens/progress_photos_screen.dart';
import 'package:personal_fitness_os/features/body/presentation/widgets/photo_comparator_modal.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  final tPhotoA = ProgressPhoto(
    id: 'p-1',
    userId: 'u-1',
    photoUrl: 'https://example.com/photo1.jpg',
    storagePath: 'u-1/photo1.jpg',
    takenAt: DateTime(2026, 7, 1),
    pose: PhotoPose.front,
  );

  final tPhotoB = ProgressPhoto(
    id: 'p-2',
    userId: 'u-1',
    photoUrl: 'https://example.com/photo2.jpg',
    storagePath: 'u-1/photo2.jpg',
    takenAt: DateTime(2026, 8, 22),
    pose: PhotoPose.front,
  );

  Widget createWidgetUnderTest({List<ProgressPhoto> photos = const []}) {
    return ProviderScope(
      overrides: [
        progressPhotosProvider.overrideWith((ref) => Future.value(photos)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const ProgressPhotosScreen(),
      ),
    );
  }

  group('ProgressPhotosScreen Widget Test', () {
    testWidgets('should render empty state when no photos exist', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(photos: []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Nenhuma foto encontrada'), findsOneWidget);
      expect(find.text('Adicionar Foto'), findsOneWidget);
    });

    testWidgets('should render filter chips and photos grid when photos exist', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(photos: [tPhotoA, tPhotoB]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Frente'), findsWidgets);
      expect(find.text('Costas'), findsOneWidget);
    });
  });

  group('PhotoComparatorModal Widget Test', () {
    testWidgets('should render before and after labels and days difference', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: PhotoComparatorModal(
              beforePhoto: tPhotoA,
              afterPhoto: tPhotoB,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Comparação Antes & Depois'), findsOneWidget);
      expect(find.text('ANTES'), findsOneWidget);
      expect(find.text('DEPOIS'), findsOneWidget);
      expect(find.text('Diferença de 52 dias'), findsOneWidget);
    });
  });
}
