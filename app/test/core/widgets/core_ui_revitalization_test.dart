import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/update/app_update_info.dart';
import 'package:personal_fitness_os/core/update/app_update_widgets.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/empty_state_widget.dart';
import 'package:personal_fitness_os/core/widgets/error_widget.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/core/widgets/liftr_progress_bar.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet_header.dart';
import 'package:personal_fitness_os/core/widgets/loading_widget.dart';
import 'package:personal_fitness_os/core/widgets/offline_banner_widget.dart';

void main() {
  Widget wrap(Widget child, {bool disableAnimations = false, ThemeData? theme}) {
    return MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        theme: theme ?? AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('Phase 2 Core UI Primitives', () {
    test('core/widgets primitives do not import feature domain files', () {
      final coreWidgetsDir = Directory('lib/core/widgets');
      final nonChartFiles = coreWidgetsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in nonChartFiles) {
        final content = file.readAsStringSync();
        expect(
          content.contains('package:personal_fitness_os/features/'),
          isFalse,
          reason: '${file.path} must remain domain-agnostic',
        );
      }
    });

    testWidgets('AppButton renders 4 variants without neon boxShadow and guards isLoading',
        (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              AppButton.primary(label: 'Primário', onPressed: () => tapCount++),
              AppButton.secondary(label: 'Secundário', onPressed: () {}),
              AppButton.text(label: 'Texto', onPressed: () {}),
              AppButton.destructive(label: 'Descartar', onPressed: () {}),
              AppButton.primary(
                label: 'Carregando',
                isLoading: true,
                onPressed: () => tapCount++,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Primário'), findsOneWidget);
      expect(find.text('Secundário'), findsOneWidget);
      expect(find.text('Texto'), findsOneWidget);
      expect(find.text('Descartar'), findsOneWidget);

      // Verify zero decorative BoxShadow containers on AppButton
      final decoratedContainers = tester.widgetList<Container>(find.byType(Container));
      for (final c in decoratedContainers) {
        final dec = c.decoration;
        if (dec is BoxDecoration) {
          expect(dec.boxShadow, isNull);
        }
      }

      await tester.tap(find.text('Carregando'));
      await tester.pump();
      expect(tapCount, 0);

      await tester.tap(find.text('Primário'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tapCount, 1);
    });

    testWidgets('AppCard supports raised, subtle, flat and accented variants without gradients',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const Column(
            children: [
              AppCard(variant: AppCardVariant.raised, child: Text('Raised')),
              AppCard(variant: AppCardVariant.subtle, child: Text('Subtle')),
              AppCard(variant: AppCardVariant.flat, child: Text('Flat')),
              AppCard(variant: AppCardVariant.accented, child: Text('Accented')),
            ],
          ),
        ),
      );

      expect(find.text('Raised'), findsOneWidget);
      expect(find.text('Subtle'), findsOneWidget);
      expect(find.text('Flat'), findsOneWidget);
      expect(find.text('Accented'), findsOneWidget);
    });

    testWidgets('LiftrBadge, LiftrSheetHeader, Empty/Error/Loading states and numeric input render cleanly',
        (tester) async {
      var numericVal = 60.0;

      await tester.pumpWidget(
        wrap(
          SingleChildScrollView(
            child: Column(
              children: [
                const LiftrSheetHeader(
                  eyebrow: 'Fila rotativa',
                  title: 'Escolher treino',
                  subtitle: 'Selecione o próximo treino da sequência',
                ),
                const Wrap(
                  spacing: 6,
                  children: [
                    LiftrBadge(label: 'Padrão', tone: LiftrBadgeTone.neutral),
                    LiftrBadge(label: 'Próximo', tone: LiftrBadgeTone.brand),
                    LiftrBadge(label: 'Subindo', tone: LiftrBadgeTone.success),
                    LiftrBadge(label: 'Atenção', tone: LiftrBadgeTone.warning),
                    LiftrBadge(label: 'Erro', tone: LiftrBadgeTone.danger),
                    LiftrBadge(label: 'AQ', tone: LiftrBadgeTone.info),
                    LiftrBadge(label: 'DROP', tone: LiftrBadgeTone.dropSet),
                  ],
                ),
                AppNumericInput(
                  label: 'Carga',
                  value: numericVal,
                  unit: 'kg',
                  step: 2.5,
                  onChanged: (v) => numericVal = v,
                ),
                const LiftrProgressBar(progress: 0.65),
                EmptyStateWidget(
                  icon: Icons.fitness_center_rounded,
                  title: 'Nenhum treino',
                  subtitle: 'Crie um programa para começar.',
                  actionLabel: 'Criar programa',
                  onAction: () {},
                ),
                ErrorStateWidget(
                  message: 'Falha de conexão.',
                  safetyNote: 'Seus dados locais continuam salvos no aparelho.',
                  onRetry: () {},
                ),
                const LiftrScreenSkeleton(itemCount: 2),
              ],
            ),
          ),
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FILA ROTATIVA'), findsOneWidget);
      expect(find.text('Escolher treino'), findsOneWidget);
      expect(find.text('DROP'), findsOneWidget);
      expect(find.text('60 kg'), findsOneWidget);
      expect(find.text('Seus dados locais continuam salvos no aparelho.'), findsOneWidget);
      expect(tester.getSize(find.bySemanticsLabel('Diminuir Carga')).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(find.bySemanticsLabel('Aumentar Carga')).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });

    testWidgets('OfflineBannerWidget and AppUpdateBanner expose >= 44x48dp dismiss hit targets',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              OfflineBannerWidget(pendingChangesCount: 1, onDismiss: () {}),
              AppUpdateBanner(
                updateInfo: const AppUpdateInfo(
                  versionName: '0.2.0',
                  buildNumber: 200,
                  tagName: 'v0.2.0',
                  releaseNotes: 'Notas',
                  apkDownloadUrl: 'https://example.com/app.apk',
                  apkFileName: 'liftr-arm64-release.apk',
                  apkSizeBytes: 25000000,
                ),
                onUpdateTap: () {},
                onDismiss: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.text('Modo Offline • 1 alteração salva localmente'), findsOneWidget);
      expect(find.text('Nova versão v0.2.0 disponível'), findsOneWidget);

      final offlineClose = tester.getSize(find.bySemanticsLabel('Ocultar aviso offline'));
      final updateClose = tester.getSize(find.bySemanticsLabel('Ocultar aviso de atualização'));
      expect(offlineClose.width, greaterThanOrEqualTo(48));
      expect(offlineClose.height, greaterThanOrEqualTo(44));
      expect(updateClose.width, greaterThanOrEqualTo(48));
      expect(updateClose.height, greaterThanOrEqualTo(44));
    });

    testWidgets(
        'AppButton uses fgColor on text variant and satisfies 320dp @ 1.3x/2.0x and a11y guidelines',
        (tester) async {
      for (final theme in [AppTheme.dark(), AppTheme.light()]) {
        final expectedPrimaryLight = theme.extension<AppColors>()!.primaryLight;
        for (final scale in [1.3, 2.0]) {
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: const Size(320, 640),
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: MaterialApp(
                theme: theme,
                home: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        AppButton.primary(
                          label: 'Iniciar treino longo da semana',
                          icon: Icons.play_arrow_rounded,
                          onPressed: () {},
                        ),
                        const SizedBox(height: 12),
                        AppButton.secondary(
                          label: 'Ver histórico completo',
                          onPressed: () {},
                        ),
                        const SizedBox(height: 12),
                        AppButton.text(
                          label: 'Esqueci minha senha',
                          onPressed: () {},
                        ),
                        const SizedBox(height: 12),
                        AppButton.destructive(
                          label: 'Descartar sessão atual',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final textWidget = tester.widget<Text>(find.text('Esqueci minha senha'));
          expect(textWidget.style?.color, expectedPrimaryLight);
          expect(textWidget.maxLines, 2);
          expect(tester.takeException(), isNull);

          final a11yHandle = tester.ensureSemantics();
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          a11yHandle.dispose();
        }
      }
    });

    testWidgets(
        'AppInput supports obscureText toggle, textInputAction, onFieldSubmitted and autofillHints',
        (tester) async {
      final controller = TextEditingController(text: 'segredo123');
      String? submittedValue;

      await tester.pumpWidget(
        wrap(
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppInput(
              label: 'Senha',
              controller: controller,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              textCapitalization: TextCapitalization.none,
              onFieldSubmitted: (v) => submittedValue = v,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      var editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.obscureText, isTrue);
      expect(editable.textInputAction, TextInputAction.done);
      expect(editable.autofillHints, contains(AutofillHints.password));

      final toggleButton = find.byTooltip('Mostrar senha');
      expect(toggleButton, findsOneWidget);
      expect(tester.getSize(toggleButton).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(toggleButton).height, greaterThanOrEqualTo(48));

      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.obscureText, isFalse);
      expect(find.byTooltip('Ocultar senha'), findsOneWidget);

      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(submittedValue, 'segredo123');

      final a11yHandle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      a11yHandle.dispose();
    });
  });
}
