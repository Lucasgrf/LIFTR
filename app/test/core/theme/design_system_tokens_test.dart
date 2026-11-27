import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_motion.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/liftr_brand_mark.dart';

double _relativeLuminance(Color c) {
  double channel(int value) {
    final v = value / 255.0;
    return v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channel((c.r * 255.0).round());
  final g = channel((c.g * 255.0).round());
  final b = channel((c.b * 255.0).round());
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color a, Color b) {
  final l1 = _relativeLuminance(a);
  final l2 = _relativeLuminance(b);
  final brighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (brighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Technical Humanism Tokens & WCAG Contrast', () {
    test('Dark palette satisfies WCAG 2.1 AA/AAA and forbids legacy purple/Inter', () {
      const dark = AppColors.dark;
      const fitness = FitnessColors.dark;
      final theme = AppTheme.dark();

      expect(dark.primary, const Color(0xFF72A987));
      expect(dark.primary.toARGB32(), isNot(0xFF6C63FF));
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Geist');
      expect(theme.textTheme.displayLarge?.fontFeatures, AppTypography.tabularFeatures);

      expect(_contrastRatio(dark.textPrimary, dark.background), greaterThanOrEqualTo(7.0));
      expect(_contrastRatio(dark.textPrimary, dark.surface), greaterThanOrEqualTo(7.0));
      expect(_contrastRatio(dark.textSecondary, dark.surface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.textSecondary, dark.surfaceElevated), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.textSecondary, dark.surfaceVariant), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.textTertiary, dark.surface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.textTertiary, dark.surfaceElevated), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.textTertiary, dark.surfaceVariant), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.onPrimary, dark.primary), greaterThanOrEqualTo(7.0));
      expect(_contrastRatio(dark.primaryLight, dark.primaryMuted), greaterThanOrEqualTo(7.0));
      expect(_contrastRatio(dark.warning, dark.surface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.danger, dark.surface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.danger, dark.surfaceElevated), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.onPrimary, dark.danger), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.info, dark.surface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.borderInteractive, dark.surface), greaterThanOrEqualTo(3.0));
      expect(_contrastRatio(dark.borderInteractive, dark.surfaceElevated), greaterThanOrEqualTo(3.0));
      expect(_contrastRatio(fitness.dropSetTag, dark.surface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(fitness.progressUp, dark.surface), greaterThanOrEqualTo(4.5));
      expect(dark.primaryVariant, dark.primaryPressed);
      expect(dark.success, dark.primary);
    });

    test('Light palette satisfies WCAG 2.1 AA/AAA with Deep Botanical primary', () {
      const light = AppColors.light;
      const fitness = FitnessColors.light;
      final theme = AppTheme.light();

      expect(light.primary, const Color(0xFF315B43));
      expect(light.onPrimary, const Color(0xFFF2F2F0));
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Geist');
      expect(light.surfaceSubtle, isNot(light.surface));
      expect(light.surface, isNot(light.surfaceElevated));

      expect(_contrastRatio(light.textPrimary, light.background), greaterThanOrEqualTo(7.0));
      expect(_contrastRatio(light.textSecondary, light.background), greaterThanOrEqualTo(7.0));
      expect(_contrastRatio(light.textSecondary, light.surfaceElevated), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.textSecondary, light.surfaceVariant), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.textTertiary, light.surface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.textTertiary, light.surfaceElevated), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.textTertiary, light.surfaceVariant), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.primary, light.background), greaterThanOrEqualTo(7.0));
      expect(_contrastRatio(light.onPrimary, light.primary), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.warning, light.background), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.warning, light.surfaceSubtle), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.warning, light.surface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.danger, light.surface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.danger, light.surfaceElevated), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.onPrimary, light.danger), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.info, light.surface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.borderInteractive, light.surface), greaterThanOrEqualTo(3.0));
      expect(_contrastRatio(light.borderInteractive, light.surfaceElevated), greaterThanOrEqualTo(3.0));
      expect(_contrastRatio(fitness.dropSetTag, light.surface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(fitness.progressUp, light.surface), greaterThanOrEqualTo(4.5));
      expect(light.primaryVariant, light.primaryPressed);
      expect(light.success, light.primary);
    });

    test('AppRadius and AppMotion expose restrained geometry and motion budgets', () {
      final theme = AppTheme.dark();
      final radius = theme.extension<AppRadius>()!;
      final motion = theme.extension<AppMotion>()!;

      expect(radius.none, 0);
      expect(radius.xs, 4);
      expect(radius.small, 8);
      expect(radius.medium, 12);
      expect(radius.large, 16);
      expect(radius.xl, 16);
      expect(radius.full, 999);

      expect(motion.instant, Duration.zero);
      expect(motion.fast.inMilliseconds, 140);
      expect(motion.standard.inMilliseconds, 220);
      expect(motion.emphasis.inMilliseconds, lessThanOrEqualTo(260));
      expect(motion.curveStandard, const Cubic(0.23, 1.0, 0.32, 1.0));
    });

    test('AppTypography defines complete monotonic scale, tabular bodyLarge, and 14sp labelLarge', () {
      for (final theme in [AppTheme.dark(), AppTheme.light()]) {
        final tt = theme.textTheme;
        expect(tt.displaySmall?.fontSize, 28);
        expect(tt.displaySmall?.fontFeatures, isNotEmpty);
        expect(tt.headlineSmall?.fontSize, 20);
        expect(tt.headlineSmall?.fontFeatures, isNotEmpty);
        expect(tt.bodyLarge?.fontSize, 16);
        expect(tt.bodyLarge?.fontFeatures, isNotEmpty);
        expect(tt.labelLarge?.fontSize, 14);
        expect(tt.labelSmall?.fontSize, greaterThanOrEqualTo(11));

        // Monotonic type scale: display >= headline >= title, body, label.
        expect(tt.displayLarge!.fontSize, greaterThanOrEqualTo(tt.displayMedium!.fontSize!));
        expect(tt.displayMedium!.fontSize, greaterThanOrEqualTo(tt.displaySmall!.fontSize!));
        expect(tt.displaySmall!.fontSize, greaterThanOrEqualTo(tt.headlineLarge!.fontSize!));
        expect(tt.headlineLarge!.fontSize, greaterThanOrEqualTo(tt.headlineMedium!.fontSize!));
        expect(tt.headlineMedium!.fontSize, greaterThanOrEqualTo(tt.headlineSmall!.fontSize!));
        expect(tt.headlineSmall!.fontSize, greaterThanOrEqualTo(tt.titleLarge!.fontSize!));
        expect(tt.titleLarge!.fontSize, greaterThanOrEqualTo(tt.titleMedium!.fontSize!));
        expect(tt.titleMedium!.fontSize, greaterThanOrEqualTo(tt.titleSmall!.fontSize!));
        expect(tt.bodyLarge!.fontSize, greaterThanOrEqualTo(tt.bodyMedium!.fontSize!));
        expect(tt.bodyMedium!.fontSize, greaterThanOrEqualTo(tt.bodySmall!.fontSize!));
        expect(tt.labelLarge!.fontSize, greaterThanOrEqualTo(tt.labelMedium!.fontSize!));
        expect(tt.labelMedium!.fontSize, greaterThanOrEqualTo(tt.labelSmall!.fontSize!));
      }
    });

    testWidgets('AppMotion.resolve honors MediaQuery disableAnimations', (tester) async {
      late Duration resolvedNormal;
      late Duration resolvedReduced;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Column(
            children: [
              MediaQuery(
                data: const MediaQueryData(disableAnimations: false),
                child: Builder(
                  builder: (ctx) {
                    resolvedNormal = ctx.appMotion.resolve(ctx, ctx.appMotion.standard);
                    return const SizedBox.shrink();
                  },
                ),
              ),
              MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: Builder(
                  builder: (ctx) {
                    resolvedReduced = ctx.appMotion.resolve(ctx, ctx.appMotion.standard);
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      );

      expect(resolvedNormal, const Duration(milliseconds: 220));
      expect(resolvedReduced, Duration.zero);
    });

    testWidgets('LiftrBrandMark and LiftrWordmark render SVG monolith in dark and light themes',
        (tester) async {
      for (final theme in [AppTheme.dark(), AppTheme.light()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: Column(
                children: [
                  LiftrBrandMark(size: 32),
                  LiftrBrandMark(size: 16, variant: LiftrMarkVariant.monoLight),
                  LiftrBrandMark(size: 16, variant: LiftrMarkVariant.monoDark),
                  LiftrWordmark(),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SvgPicture), findsNWidgets(4));
        expect(find.text('LIFTR'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    test('A11Y-01 TextButtonThemeData enforces minimumSize 48x48 in dark and light themes', () {
      for (final theme in [AppTheme.dark(), AppTheme.light()]) {
        final resolvedSize = theme.textButtonTheme.style?.minimumSize?.resolve({});
        expect(resolvedSize, const Size(48, 48));
      }
    });
  });
}
