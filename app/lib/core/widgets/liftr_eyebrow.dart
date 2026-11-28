import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';

/// Small sentence-case label used for secondary metadata and sheet eyebrows.
class LiftrEyebrow extends StatelessWidget {
  const LiftrEyebrow(
    this.text, {
    super.key,
    this.color,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final String text;
  final Color? color;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTypography.eyebrow(context);
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      style: color != null ? baseStyle.copyWith(color: color) : baseStyle,
    );
  }
}
