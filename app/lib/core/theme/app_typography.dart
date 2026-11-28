import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';

class AppTypography {
  static const fontFamily = 'Familjen Grotesk';
  static const tabularFeatures = <FontFeature>[FontFeature.tabularFigures()];

  static TextStyle _style({
    required double size,
    required double lineHeight,
    required FontWeight weight,
    Color? color,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      height: lineHeight,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      fontFeatures: tabularFeatures,
      color: color,
    );
  }

  static TextStyle eyebrow(BuildContext context) {
    return _style(
      size: 13,
      lineHeight: 1.45,
      weight: FontWeight.w600,
      color: context.appColors.textTertiary,
    );
  }

  /// Type scale and line heights mirror the `t13`–`t64` classes in the HTML.
  static TextTheme textTheme({bool isDark = true}) {
    final textColor = isDark
        ? AppColors.dark.textPrimary
        : AppColors.light.textPrimary;

    return TextTheme(
      displayLarge: _style(
        size: 64,
        lineHeight: .92,
        weight: FontWeight.w700,
        color: textColor,
        letterSpacing: -2.56,
      ),
      displayMedium: _style(
        size: 40,
        lineHeight: 1,
        weight: FontWeight.w700,
        color: textColor,
        letterSpacing: -1.2,
      ),
      displaySmall: _style(
        size: 28,
        lineHeight: 1.1,
        weight: FontWeight.w700,
        color: textColor,
        letterSpacing: -.56,
      ),
      headlineLarge: _style(
        size: 28,
        lineHeight: 1.1,
        weight: FontWeight.w700,
        color: textColor,
        letterSpacing: -.56,
      ),
      headlineMedium: _style(
        size: 20,
        lineHeight: 1.3,
        weight: FontWeight.w600,
        color: textColor,
        letterSpacing: -.1,
      ),
      headlineSmall: _style(
        size: 20,
        lineHeight: 1.3,
        weight: FontWeight.w600,
        color: textColor,
        letterSpacing: -.1,
      ),
      titleLarge: _style(
        size: 20,
        lineHeight: 1.3,
        weight: FontWeight.w600,
        color: textColor,
        letterSpacing: -.1,
      ),
      titleMedium: _style(
        size: 17,
        lineHeight: 1.45,
        weight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: _style(
        size: 15,
        lineHeight: 1.45,
        weight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: _style(
        size: 17,
        lineHeight: 1.45,
        weight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: _style(
        size: 15,
        lineHeight: 1.45,
        weight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: _style(
        size: 13,
        lineHeight: 1.45,
        weight: FontWeight.w400,
        color: textColor,
      ),
      labelLarge: _style(
        size: 17,
        lineHeight: 1.45,
        weight: FontWeight.w600,
        color: textColor,
      ),
      labelMedium: _style(
        size: 15,
        lineHeight: 1.45,
        weight: FontWeight.w600,
        color: textColor,
      ),
      labelSmall: _style(
        size: 13,
        lineHeight: 1.45,
        weight: FontWeight.w500,
        color: textColor,
      ),
    );
  }
}
