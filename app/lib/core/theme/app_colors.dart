import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceElevated,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.border,
    required this.divider,
    this.surfaceSubtle = const Color(0xFF141418),
    this.primaryPressed = const Color(0xFF5E9473),
    this.primaryLight = const Color(0xFF93C4A5),
    this.primaryMuted = const Color(0xFF1B2921),
    this.borderSubtle = const Color(0xFF1E1E24),
    this.borderInteractive = const Color(0xFF6E6E7B),
    this.borderFocus = const Color(0xFF72A987),
    this.danger = const Color(0xFFE07575),
    this.warning = const Color(0xFFD4A154),
    this.info = const Color(0xFF6E9EC7),
    this.onPrimary = const Color(0xFF0D0D0F),
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceElevated;
  final Color surfaceSubtle;
  final Color primary;
  final Color primaryPressed;
  final Color primaryLight;
  final Color primaryMuted;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color border;
  final Color borderSubtle;
  final Color borderInteractive;
  final Color borderFocus;
  final Color divider;
  final Color danger;
  final Color warning;
  final Color info;

  /// Alias pointing to [primaryPressed].
  Color get primaryVariant => primaryPressed;

  /// Alias pointing to [primary].
  Color get success => primary;

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceElevated,
    Color? surfaceSubtle,
    Color? primary,
    Color? primaryPressed,
    Color? primaryLight,
    Color? primaryMuted,
    Color? onPrimary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? border,
    Color? borderSubtle,
    Color? borderInteractive,
    Color? borderFocus,
    Color? divider,
    Color? danger,
    Color? warning,
    Color? info,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryMuted: primaryMuted ?? this.primaryMuted,
      onPrimary: onPrimary ?? this.onPrimary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderInteractive: borderInteractive ?? this.borderInteractive,
      borderFocus: borderFocus ?? this.borderFocus,
      divider: divider ?? this.divider,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      info: info ?? this.info,
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
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryPressed:
          Color.lerp(primaryPressed, other.primaryPressed, t) ?? primaryPressed,
      primaryLight:
          Color.lerp(primaryLight, other.primaryLight, t) ?? primaryLight,
      primaryMuted:
          Color.lerp(primaryMuted, other.primaryMuted, t) ?? primaryMuted,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t) ?? onPrimary,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textTertiary:
          Color.lerp(textTertiary, other.textTertiary, t) ?? textTertiary,
      textDisabled:
          Color.lerp(textDisabled, other.textDisabled, t) ?? textDisabled,
      border: Color.lerp(border, other.border, t) ?? border,
      borderSubtle:
          Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      borderInteractive:
          Color.lerp(borderInteractive, other.borderInteractive, t) ??
          borderInteractive,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t) ?? borderFocus,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
    );
  }

  static const dark = AppColors(
    background: Color(0xFF0D0D0F),
    surfaceSubtle: Color(0xFF141418),
    surface: Color(0xFF1A1A1F),
    surfaceElevated: Color(0xFF222228),
    surfaceVariant: Color(0xFF2A2A32),
    primary: Color(0xFF72A987),
    primaryPressed: Color(0xFF5E9473),
    primaryLight: Color(0xFF93C4A5),
    primaryMuted: Color(0xFF1B2921),
    onPrimary: Color(0xFF0D0D0F),
    textPrimary: Color(0xFFF2F2F0),
    textSecondary: Color(0xFF9898A3),
    textTertiary: Color(0xFF93939E),
    textDisabled: Color(0xFF585864),
    border: Color(0xFF26262E),
    borderSubtle: Color(0xFF1E1E24),
    borderInteractive: Color(0xFF6E6E7B),
    borderFocus: Color(0xFF72A987),
    divider: Color(0xFF22222A),
    danger: Color(0xFFE07575),
    warning: Color(0xFFD4A154),
    info: Color(0xFF6E9EC7),
  );

  static const light = AppColors(
    background: Color(0xFFF4F4F0),
    surfaceSubtle: Color(0xFFEAEAE4),
    surface: Color(0xFFFAFAF8),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE3E3DC),
    primary: Color(0xFF315B43),
    primaryPressed: Color(0xFF264835),
    primaryLight: Color(0xFF315B43),
    primaryMuted: Color(0xFFE4EFE8),
    onPrimary: Color(0xFFF2F2F0),
    textPrimary: Color(0xFF0D0D0F),
    textSecondary: Color(0xFF52525B),
    textTertiary: Color(0xFF5E5E68),
    textDisabled: Color(0xFF90909A),
    border: Color(0xFFDCDBD5),
    borderSubtle: Color(0xFFE8E7E1),
    borderInteractive: Color(0xFF76767F),
    borderFocus: Color(0xFF315B43),
    divider: Color(0xFFE2E2DC),
    danger: Color(0xFFB93838),
    warning: Color(0xFF805500),
    info: Color(0xFF2B5E8A),
  );
}

extension AppColorsExtension on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
