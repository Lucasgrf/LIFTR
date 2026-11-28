import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';

enum AppCardVariant { raised, subtle, flat, accented }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.raised,
    this.accentColor,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.constraints,
    this.gradient,
    this.borderRadius,
    this.boxShadow,
  });

  final Widget child;
  final AppCardVariant variant;
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final BoxConstraints? constraints;
  final Gradient? gradient;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final effectiveRadius = borderRadius ?? radius.large;

    final Color defaultSurface;
    final Color defaultBorder;
    switch (variant) {
      case AppCardVariant.raised:
      case AppCardVariant.accented:
        defaultSurface = colors.surfaceSubtle;
        defaultBorder = Colors.transparent;
        break;
      case AppCardVariant.subtle:
        defaultSurface = colors.surface;
        defaultBorder = Colors.transparent;
        break;
      case AppCardVariant.flat:
        defaultSurface = colors.surface;
        defaultBorder = Colors.transparent;
        break;
    }

    final padded = Padding(
      padding: padding ?? const EdgeInsets.all(16.0),
      child: child,
    );

    final content = constraints != null
        ? ConstrainedBox(constraints: constraints!, child: padded)
        : padded;

    final inner = Material(
      color: Colors.transparent,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(effectiveRadius),
              child: content,
            )
          : content,
    );

    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? defaultSurface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: variant == AppCardVariant.flat && borderColor == null
            ? null
            : Border.all(
                color: borderColor ?? defaultBorder,
                width: borderWidth,
              ),
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: variant == AppCardVariant.accented
            ? Stack(
                children: [
                  inner,
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: accentColor ?? colors.primary,
                      ),
                    ),
                  ),
                ],
              )
            : inner,
      ),
    );
  }
}
