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
    this.surfaceSubtle = const Color(0xFF141418),
    this.surfacePreview = const Color(0xFF18181D),
    this.primaryPressed = const Color(0xFF584FE6),
    this.primaryLight = const Color(0xFFB7B3FF),
    this.borderFocus = const Color(0xFF6C63FF),
    this.danger = const Color(0xFFFF4D5E),
    this.warning = const Color(0xFFF59E0B),
    this.success = const Color(0xFF22C55E),
    this.onPrimary = const Color(0xFFFFFFFF),
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceElevated;
  final Color surfaceSubtle;
  final Color surfacePreview;
  final Color primary;
  final Color primaryVariant;
  final Color primaryPressed;
  final Color primaryLight;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color border;
  final Color borderFocus;
  final Color divider;
  final Color danger;
  final Color warning;
  final Color success;

  Color get primaryMuted => primary.withValues(alpha: 0.15);

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceElevated,
    Color? surfaceSubtle,
    Color? surfacePreview,
    Color? primary,
    Color? primaryVariant,
    Color? primaryPressed,
    Color? primaryLight,
    Color? onPrimary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? border,
    Color? borderFocus,
    Color? divider,
    Color? danger,
    Color? warning,
    Color? success,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfacePreview: surfacePreview ?? this.surfacePreview,
      primary: primary ?? this.primary,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primaryLight: primaryLight ?? this.primaryLight,
      onPrimary: onPrimary ?? this.onPrimary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      borderFocus: borderFocus ?? this.borderFocus,
      divider: divider ?? this.divider,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      success: success ?? this.success,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceVariant:
          Color.lerp(surfaceVariant, other.surfaceVariant, t) ?? surfaceVariant,
      surfaceElevated:
          Color.lerp(surfaceElevated, other.surfaceElevated, t) ??
          surfaceElevated,
      surfaceSubtle:
          Color.lerp(surfaceSubtle, other.surfaceSubtle, t) ?? surfaceSubtle,
      surfacePreview:
          Color.lerp(surfacePreview, other.surfacePreview, t) ?? surfacePreview,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryVariant:
          Color.lerp(primaryVariant, other.primaryVariant, t) ?? primaryVariant,
      primaryPressed:
          Color.lerp(primaryPressed, other.primaryPressed, t) ?? primaryPressed,
      primaryLight:
          Color.lerp(primaryLight, other.primaryLight, t) ?? primaryLight,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t) ?? onPrimary,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textTertiary:
          Color.lerp(textTertiary, other.textTertiary, t) ?? textTertiary,
      textDisabled:
          Color.lerp(textDisabled, other.textDisabled, t) ?? textDisabled,
      border: Color.lerp(border, other.border, t) ?? border,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t) ?? borderFocus,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      success: Color.lerp(success, other.success, t) ?? success,
    );
  }

  static const dark = AppColors(
    background: Color(0xFF0D0D0F),
    surfaceSubtle: Color(0xFF141418),
    surfacePreview: Color(0xFF18181D),
    surface: Color(0xFF1A1A1F),
    surfaceElevated: Color(0xFF23232A),
    surfaceVariant: Color(0xFF252530),
    primary: Color(0xFF6C63FF),
    primaryVariant: Color(0xFF584FE6),
    primaryPressed: Color(0xFF584FE6),
    primaryLight: Color(0xFFB7B3FF),
    onPrimary: Color(0xFFFFFFFF),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFF9E9EA8),
    textTertiary: Color(0xFF63636E),
    textDisabled: Color(0xFF404050),
    border: Color(0xFF2A2A33),
    borderFocus: Color(0xFF6C63FF),
    divider: Color(0xFF25252D),
    danger: Color(0xFFFF4D5E),
    warning: Color(0xFFF59E0B),
    success: Color(0xFF22C55E),
  );

  static const light = AppColors(
    background: Color(0xFFF6F6F9),
    surfaceSubtle: Color(0xFFF0F0F5),
    surfacePreview: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFEFEFF5),
    surfaceVariant: Color(0xFFE8E8F0),
    primary: Color(0xFF5B52F0),
    primaryVariant: Color(0xFF4A41DE),
    primaryPressed: Color(0xFF4A41DE),
    primaryLight: Color(0xFF5B52F0),
    onPrimary: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF111116),
    textSecondary: Color(0xFF5C5C6B),
    textTertiary: Color(0xFF8E8E9E),
    textDisabled: Color(0xFFB4B4C2),
    border: Color(0xFFE4E4EC),
    borderFocus: Color(0xFF5B52F0),
    divider: Color(0xFFE4E4EC),
    danger: Color(0xFFE11D48),
    warning: Color(0xFFD97706),
    success: Color(0xFF16A34A),
  );
}

extension AppColorsExtension on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
