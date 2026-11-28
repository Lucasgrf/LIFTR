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
    this.surfaceSubtle = const Color(0xFFE7E9E2),
    this.primaryPressed = const Color(0xFF16327F),
    this.primaryLight = const Color(0xFF1C3FAA),
    this.primaryMuted = const Color(0xFFE7E9E2),
    this.borderSubtle = const Color(0x2417191E),
    this.borderInteractive = const Color(0xFF4F545C),
    this.borderFocus = const Color(0xFF1C3FAA),
    this.danger = const Color(0xFFB8281F),
    this.warning = const Color(0xFF725000),
    this.info = const Color(0xFF1C3FAA),
    this.onPrimary = const Color(0xFFF4F5F0),
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

  /// Completion stamp ink.
  Color get success => danger;

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
    background: Color(0xFF151A2E),
    surfaceSubtle: Color(0xFF1F2640),
    surface: Color(0xFF151A2E),
    surfaceElevated: Color(0xFF1F2640),
    surfaceVariant: Color(0xFF1F2640),
    primary: Color(0xFF8FA8FF),
    primaryPressed: Color(0xFF738DE0),
    primaryLight: Color(0xFF8FA8FF),
    primaryMuted: Color(0xFF1F2640),
    onPrimary: Color(0xFF151A2E),
    textPrimary: Color(0xFFF4F5F0),
    textSecondary: Color(0xFFA9B0C2),
    textTertiary: Color(0xFFA9B0C2),
    textDisabled: Color(0xFF747B8D),
    border: Color(0x24F4F5F0),
    borderSubtle: Color(0x24F4F5F0),
    borderInteractive: Color(0xFF747B8D),
    borderFocus: Color(0xFF8FA8FF),
    divider: Color(0x24F4F5F0),
    danger: Color(0xFFFF8A7A),
    warning: Color(0xFFF3D55B),
    info: Color(0xFF8FA8FF),
  );

  static const light = AppColors(
    background: Color(0xFFF4F5F0),
    surfaceSubtle: Color(0xFFE7E9E2),
    surface: Color(0xFFF4F5F0),
    surfaceElevated: Color(0xFFE7E9E2),
    surfaceVariant: Color(0xFFE7E9E2),
    primary: Color(0xFF1C3FAA),
    primaryPressed: Color(0xFF16327F),
    primaryLight: Color(0xFF1C3FAA),
    primaryMuted: Color(0xFFE7E9E2),
    onPrimary: Color(0xFFF4F5F0),
    textPrimary: Color(0xFF17191E),
    textSecondary: Color(0xFF4F545C),
    textTertiary: Color(0xFF4F545C),
    textDisabled: Color(0xFF777C82),
    border: Color(0x3817191E),
    borderSubtle: Color(0x2417191E),
    borderInteractive: Color(0xFF4F545C),
    borderFocus: Color(0xFF1C3FAA),
    divider: Color(0x2417191E),
    danger: Color(0xFFB8281F),
    warning: Color(0xFF725000),
    info: Color(0xFF1C3FAA),
  );
}

extension AppColorsExtension on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
