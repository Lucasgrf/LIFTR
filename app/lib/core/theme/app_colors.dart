import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceElevated,
    required this.primary,
    required this.primaryVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.border,
    required this.divider,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceElevated;
  final Color primary;
  final Color primaryVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color border;
  final Color divider;

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceElevated,
    Color? primary,
    Color? primaryVariant,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? border,
    Color? divider,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      primary: primary ?? this.primary,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t) ?? surfaceVariant,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t) ?? surfaceElevated,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryVariant: Color.lerp(primaryVariant, other.primaryVariant, t) ?? primaryVariant,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t) ?? textTertiary,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t) ?? textDisabled,
      border: Color.lerp(border, other.border, t) ?? border,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
    );
  }

  static const dark = AppColors(
    background: Color(0xFF0D0D0F),
    surface: Color(0xFF1A1A1F),
    surfaceVariant: Color(0xFF252530),
    surfaceElevated: Color(0xFF2A2A35),
    primary: Color(0xFF6C63FF),
    primaryVariant: Color(0xFF5A52D5),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFF9E9EA8),
    textTertiary: Color(0xFF6B6B75),
    textDisabled: Color(0xFF404050),
    border: Color(0xFF2F2F3A),
    divider: Color(0xFF1F1F28),
  );

  static const light = AppColors(
    background: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF0F0F5),
    surfaceElevated: Color(0xFFFFFFFF),
    primary: Color(0xFF5A52D5),
    primaryVariant: Color(0xFF6C63FF),
    textPrimary: Color(0xFF1A1A1F),
    textSecondary: Color(0xFF6B6B75),
    textTertiary: Color(0xFF9E9EA8),
    textDisabled: Color(0xFF404050),
    border: Color(0xFFE0E0E0),
    divider: Color(0xFFEEEEEE),
  );
}

extension AppColorsExtension on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
