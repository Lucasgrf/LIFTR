import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_motion.dart';

/// Linear progress bar animated strictly via Transform.scale (no layout thrashing)
/// and respecting MediaQuery.disableAnimationsOf(context).
class LiftrProgressBar extends StatelessWidget {
  const LiftrProgressBar({
    super.key,
    required this.progress,
    this.height = 5,
    this.color,
    this.trackColor,
    this.borderRadius = 999,
    this.duration,
  });

  final double progress;
  final double height;
  final Color? color;
  final Color? trackColor;
  final double borderRadius;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final motion = context.appMotion;
    final clamped = progress.clamp(0.0, 1.0);
    final resolvedDuration = motion.resolve(context, duration ?? motion.standard);
    final fillColor = color ?? colors.primary;
    final bgColor = trackColor ?? colors.surfaceElevated;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        width: double.infinity,
        color: bgColor,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: clamped),
          duration: resolvedDuration,
          curve: motion.curveStandard,
          builder: (context, value, child) {
            return Transform.scale(
              scaleX: value,
              alignment: Alignment.centerLeft,
              child: child,
            );
          },
          child: Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ),
      ),
    );
  }
}
