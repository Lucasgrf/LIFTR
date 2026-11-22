import 'package:flutter/material.dart';

class AppRadius extends ThemeExtension<AppRadius> {
  const AppRadius({
    required this.small,
    required this.medium,
    required this.large,
    required this.full,
    this.none = 0,
    this.xs = 4,
    this.xl = 16,
  });

  final double none;
  final double xs;
  final double small;
  final double medium;
  final double large;
  final double xl;
  final double full;

  @override
  AppRadius copyWith({
    double? none,
    double? xs,
    double? small,
    double? medium,
    double? large,
    double? xl,
    double? full,
  }) {
    return AppRadius(
      none: none ?? this.none,
      xs: xs ?? this.xs,
      small: small ?? this.small,
      medium: medium ?? this.medium,
      large: large ?? this.large,
      xl: xl ?? this.xl,
      full: full ?? this.full,
    );
  }

  @override
  AppRadius lerp(ThemeExtension<AppRadius>? other, double t) {
    if (other is! AppRadius) return this;
    return AppRadius(
      none: none + (other.none - none) * t,
      xs: xs + (other.xs - xs) * t,
      small: small + (other.small - small) * t,
      medium: medium + (other.medium - medium) * t,
      large: large + (other.large - large) * t,
      xl: xl + (other.xl - xl) * t,
      full: full + (other.full - full) * t,
    );
  }

  static const defaults = AppRadius(
    none: 0,
    xs: 4,
    small: 8,
    medium: 12,
    large: 16,
    xl: 16,
    full: 999,
  );
}

extension AppRadiusExtension on BuildContext {
  AppRadius get appRadius =>
      Theme.of(this).extension<AppRadius>() ?? AppRadius.defaults;
}
