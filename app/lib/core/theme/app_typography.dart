import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';

class AppTypography {
  static const tabularFeatures = <FontFeature>[FontFeature.tabularFigures()];

  static TextStyle eyebrow(BuildContext context) {
    final colors = context.appColors;
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: 10,
      height: 1.4,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      color: colors.textTertiary,
    );
  }

  static TextTheme textTheme({bool isDark = true}) {
    final textColor =
        isDark ? AppColors.dark.textPrimary : AppColors.light.textPrimary;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 36,
        height: 40 / 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.08,
        fontFeatures: tabularFeatures,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 30,
        height: 34 / 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.9,
        fontFeatures: tabularFeatures,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.44,
        fontFeatures: tabularFeatures,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.27,
        fontFeatures: tabularFeatures,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.16,
        fontFeatures: tabularFeatures,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        fontFeatures: tabularFeatures,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        fontFeatures: tabularFeatures,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        fontFeatures: tabularFeatures,
        color: textColor,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        height: 20 / 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.24,
        fontFeatures: tabularFeatures,
        color: textColor,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.33,
        fontFeatures: tabularFeatures,
        color: textColor,
      ),
    );
  }
}
