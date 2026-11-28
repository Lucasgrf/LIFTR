import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/widgets/offline_banner_widget.dart';

void main() {
  group('OfflineBannerWidget Widget Test', () {
    testWidgets('should render the offline status as a ruled text line', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: OfflineBannerWidget()),
        ),
      );

      expect(
        find.text('Modo Offline • Alterações salvas localmente'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
      expect(find.byType(OfflineBannerWidget), findsOneWidget);
    });
  });
}
