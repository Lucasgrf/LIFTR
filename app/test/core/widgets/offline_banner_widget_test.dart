import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/widgets/offline_banner_widget.dart';

void main() {
  group('OfflineBannerWidget Widget Test', () {
    testWidgets('should render offline text and wifi off icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: OfflineBannerWidget(),
          ),
        ),
      );

      expect(find.text('Modo Offline • Alterações salvas localmente'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });
  });
}
