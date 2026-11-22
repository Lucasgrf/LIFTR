import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';

enum LiftrMarkVariant {
  brand,
  monoLight,
  monoDark,
}

/// Progressive Monolith symbol built from clean vector geometry.
class LiftrBrandMark extends StatelessWidget {
  const LiftrBrandMark({
    super.key,
    this.size = 24,
    this.variant = LiftrMarkVariant.brand,
    this.semanticLabel = 'Símbolo LIFTR',
  });

  final double size;
  final LiftrMarkVariant variant;
  final String semanticLabel;

  Color _resolveColor(AppColors colors) {
    switch (variant) {
      case LiftrMarkVariant.brand:
        return colors.primary;
      case LiftrMarkVariant.monoLight:
        return AppColors.dark.textPrimary;
      case LiftrMarkVariant.monoDark:
        return AppColors.light.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tint = _resolveColor(context.appColors);

    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          'assets/icons/liftr_monolith.svg',
          width: size,
          height: size,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
        ),
      ),
    );
  }
}

/// Controlled sporty horizontal lockup: Monolith symbol (4x) + LIFTR wordmark (14x).
class LiftrWordmark extends StatelessWidget {
  const LiftrWordmark({
    super.key,
    this.height = 30,
    this.variant = LiftrMarkVariant.brand,
  });

  final double height;
  final LiftrMarkVariant variant;

  // -tan(12 deg) aligns italic slant with the 12-degree Progressive Monolith.
  static final Matrix4 _slantMatrix = Matrix4.skewX(-0.21255656);

  Color _resolveWordmarkColor(AppColors colors) {
    switch (variant) {
      case LiftrMarkVariant.brand:
        return colors.textPrimary;
      case LiftrMarkVariant.monoLight:
        return AppColors.dark.textPrimary;
      case LiftrMarkVariant.monoDark:
        return AppColors.light.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final markSize = height;
    final gap = (height * 0.34).clamp(6.0, 14.0);
    final fontSize = height * 0.92;

    return Semantics(
      label: 'LIFTR',
      header: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LiftrBrandMark(
            size: markSize,
            variant: variant,
            semanticLabel: '',
          ),
          SizedBox(width: gap),
          ExcludeSemantics(
            child: Transform(
              transform: _slantMatrix,
              alignment: Alignment.bottomLeft,
              child: Text(
                'LIFTR',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: fontSize,
                  height: 1.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: fontSize * 0.04,
                  color: _resolveWordmarkColor(colors),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
