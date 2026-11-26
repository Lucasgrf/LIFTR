import 'package:flutter/material.dart';

class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    required this.space2,
    required this.space4,
    required this.space8,
    required this.space12,
    required this.space16,
    required this.space20,
    required this.space24,
    required this.space32,
    required this.space48,
    required this.space64,
  });

  final double space2;
  final double space4;
  final double space8;
  final double space12;
  final double space16;
  final double space20;
  final double space24;
  final double space32;
  final double space48;
  final double space64;

  /// Alias pointing to [space24] for generous bottom-sheet breathing room.
  double get xxl => space24;

  @override
  AppSpacing copyWith({
    double? space2,
    double? space4,
    double? space8,
    double? space12,
    double? space16,
    double? space20,
    double? space24,
    double? space32,
    double? space48,
    double? space64,
  }) {
    return AppSpacing(
      space2: space2 ?? this.space2,
      space4: space4 ?? this.space4,
      space8: space8 ?? this.space8,
      space12: space12 ?? this.space12,
      space16: space16 ?? this.space16,
      space20: space20 ?? this.space20,
      space24: space24 ?? this.space24,
      space32: space32 ?? this.space32,
      space48: space48 ?? this.space48,
      space64: space64 ?? this.space64,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      space2: (space2 + (other.space2 - space2) * t),
      space4: (space4 + (other.space4 - space4) * t),
      space8: (space8 + (other.space8 - space8) * t),
      space12: (space12 + (other.space12 - space12) * t),
      space16: (space16 + (other.space16 - space16) * t),
      space20: (space20 + (other.space20 - space20) * t),
      space24: (space24 + (other.space24 - space24) * t),
      space32: (space32 + (other.space32 - space32) * t),
      space48: (space48 + (other.space48 - space48) * t),
      space64: (space64 + (other.space64 - space64) * t),
    );
  }

  static const defaults = AppSpacing(
    space2: 2,
    space4: 4,
    space8: 8,
    space12: 12,
    space16: 16,
    space20: 20,
    space24: 24,
    space32: 32,
    space48: 48,
    space64: 64,
  );

  static const verticalGap2 = SizedBox(height: 2);
  static const verticalGap4 = SizedBox(height: 4);
  static const verticalGap8 = SizedBox(height: 8);
  static const verticalGap12 = SizedBox(height: 12);
  static const verticalGap16 = SizedBox(height: 16);
  static const verticalGap20 = SizedBox(height: 20);
  static const verticalGap24 = SizedBox(height: 24);
  static const verticalGap32 = SizedBox(height: 32);
  static const verticalGap48 = SizedBox(height: 48);
  static const verticalGap64 = SizedBox(height: 64);

  static const horizontalGap2 = SizedBox(width: 2);
  static const horizontalGap4 = SizedBox(width: 4);
  static const horizontalGap8 = SizedBox(width: 8);
  static const horizontalGap12 = SizedBox(width: 12);
  static const horizontalGap16 = SizedBox(width: 16);
  static const horizontalGap20 = SizedBox(width: 20);
  static const horizontalGap24 = SizedBox(width: 24);
  static const horizontalGap32 = SizedBox(width: 32);
  static const horizontalGap48 = SizedBox(width: 48);
  static const horizontalGap64 = SizedBox(width: 64);
}

extension AppSpacingExtension on BuildContext {
  AppSpacing get appSpacing => Theme.of(this).extension<AppSpacing>() ?? AppSpacing.defaults;
}
