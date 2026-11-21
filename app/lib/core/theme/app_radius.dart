import 'package:flutter/material.dart';

class AppRadius extends ThemeExtension<AppRadius> {
  const AppRadius({
    required this.small,
    required this.medium,
    required this.large,
    required this.full,
    this.xs = 6,
    this.xl = 24,
  });

  final double xs;
  final double small;
  final double medium;
  final double large;
  final double xl;
  final double full;

  @override
  AppRadius copyWith({
    double? xs,
    double? small,
    double? medium,
    double? large,
    double? xl,
    double? full,
  }) {
    return AppRadius(
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
      xs: xs + (other.xs - xs) * t,
      small: small + (other.small - small) * t,
      medium: medium + (other.medium - medium) * t,
      large: large + (other.large - large) * t,
      xl: xl + (other.xl - xl) * t,
      full: full + (other.full - full) * t,
    );
  }

  static const defaults = AppRadius(
    xs: 6,
    small: 10,
    medium: 14,
    large: 18,
    xl: 24,
    full: 999,
  );
}

extension AppRadiusExtension on BuildContext {
  AppRadius get appRadius =>
      Theme.of(this).extension<AppRadius>() ?? AppRadius.defaults;
}
