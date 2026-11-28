import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';

/// Colored prescription card. Text is designed for the card surface even in
/// night mode, where workout cards keep their own paper color.
class LiftrWorkoutCard extends StatelessWidget {
  const LiftrWorkoutCard({
    super.key,
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  final Color color;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.appRadius.xs + 2);
    return Material(
      color: color,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
