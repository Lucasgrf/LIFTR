import 'package:flutter/material.dart';

class AppRadius extends ThemeExtension<AppRadius> {
  const AppRadius({
    required this.small,
    required this.medium,
    required this.large,
    required this.full,
  });

  final double small;
  final double medium;
  final double large;
  final double full;

  @override
  AppRadius copyWith({
    double? small,
    double? medium,
    double? large,
    double? full,
  }) {
    return AppRadius(
      small: small ?? this.small,
      medium: medium ?? this.medium,
      large: large ?? this.large,
      full: full ?? this.full,
    );
  }

  @override
  AppRadius lerp(ThemeExtension<AppRadius>? other, double t) {
    if (other is! AppRadius) return this;
    return AppRadius(
      small: (small + (other.small - small) * t),
      medium: (medium + (other.medium - medium) * t),
      large: (large + (other.large - large) * t),
      full: (full + (other.full - full) * t),
    );
  }

  static const defaults = AppRadius(
    small: 8,
    medium: 12,
    large: 16,
    full: 999,
  );
}

extension AppRadiusExtension on BuildContext {
  AppRadius get appRadius => Theme.of(this).extension<AppRadius>() ?? AppRadius.defaults;
}
