import 'package:flutter/material.dart';

/// Centralized motion tokens for LIFTR's functional animation language.
class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({
    this.instant = Duration.zero,
    this.fast = const Duration(milliseconds: 140),
    this.standard = const Duration(milliseconds: 220),
    this.emphasis = const Duration(milliseconds: 260),
    this.curveStandard = const Cubic(0.23, 1.0, 0.32, 1.0),
    this.curveExit = const Cubic(0.4, 0.0, 1.0, 1.0),
  });

  final Duration instant;
  final Duration fast;
  final Duration standard;
  final Duration emphasis;
  final Curve curveStandard;
  final Curve curveExit;

  /// Returns [Duration.zero] when platform reduced-motion is active.
  Duration resolve(BuildContext context, Duration target) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Duration.zero;
    }
    return target;
  }

  @override
  AppMotion copyWith({
    Duration? instant,
    Duration? fast,
    Duration? standard,
    Duration? emphasis,
    Curve? curveStandard,
    Curve? curveExit,
  }) {
    return AppMotion(
      instant: instant ?? this.instant,
      fast: fast ?? this.fast,
      standard: standard ?? this.standard,
      emphasis: emphasis ?? this.emphasis,
      curveStandard: curveStandard ?? this.curveStandard,
      curveExit: curveExit ?? this.curveExit,
    );
  }

  @override
  AppMotion lerp(ThemeExtension<AppMotion>? other, double t) {
    if (other is! AppMotion) return this;
    return t < 0.5 ? this : other;
  }

  static const defaults = AppMotion();
}

extension AppMotionExtension on BuildContext {
  AppMotion get appMotion =>
      Theme.of(this).extension<AppMotion>() ?? AppMotion.defaults;
}
