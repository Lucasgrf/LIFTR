import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';

/// Standardized tracked-uppercase eyebrow label whose uppercase transform is
/// applied internally so callers supply readable sentence-case copy.
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
      text.toUpperCase(),
      maxLines: maxLines,
      overflow: overflow,
      style: color != null ? baseStyle.copyWith(color: color) : baseStyle,
    );
  }
}
