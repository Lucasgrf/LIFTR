import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';

enum LiftrMarkVariant { brand, monoLight, monoDark }

/// LIFTR ramp mark: the step in the logo represents double progression.
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

  Color _resolveColor(BuildContext context, AppColors colors) {
    switch (variant) {
      case LiftrMarkVariant.brand:
        return colors.primary;
      case LiftrMarkVariant.monoLight:
        return Theme.of(context).brightness == Brightness.dark
            ? colors.textPrimary
            : colors.background;
      case LiftrMarkVariant.monoDark:
        return colors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tint = _resolveColor(context, context.appColors);

    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          'assets/icons/liftr-simbolo.svg',
          width: size,
          height: size,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
        ),
      ),
    );
  }
}

/// Official lowercase lockup, using the two-color SVG supplied in the design.
class LiftrWordmark extends StatelessWidget {
  const LiftrWordmark({
    super.key,
    this.height = 30,
    this.variant = LiftrMarkVariant.brand,
  });

  final double height;
  final LiftrMarkVariant variant;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = switch (variant) {
      LiftrMarkVariant.brand =>
        isDark
            ? 'assets/icons/liftr-marca-noite.svg'
            : 'assets/icons/liftr-marca.svg',
      LiftrMarkVariant.monoLight => 'assets/icons/liftr-marca-noite.svg',
      LiftrMarkVariant.monoDark => 'assets/icons/liftr-marca.svg',
    };
    final filterColor = switch (variant) {
      LiftrMarkVariant.brand => null,
      LiftrMarkVariant.monoLight =>
        isDark ? context.appColors.textPrimary : context.appColors.background,
      LiftrMarkVariant.monoDark => context.appColors.textPrimary,
    };

    return Semantics(
      label: 'liftr',
      header: true,
      child: SvgPicture.asset(
        asset,
        height: height,
        width: height * 2.99,
        fit: BoxFit.contain,
        colorFilter: filterColor == null
            ? null
            : ColorFilter.mode(filterColor, BlendMode.srcIn),
      ),
    );
  }
}

/// Lowercase LIFTR wordmark without the ramp symbol, used under the splash mark.
class LiftrWordmarkOnly extends StatelessWidget {
  const LiftrWordmarkOnly({super.key, this.height = 55});

  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'liftr',
    image: true,
    child: SvgPicture.asset(
      'assets/icons/liftr-wordmark.svg',
      height: height,
      width: height * 2.03,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(
        context.appColors.textPrimary,
        BlendMode.srcIn,
      ),
    ),
  );
}
