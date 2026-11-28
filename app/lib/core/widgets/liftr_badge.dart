import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';

enum LiftrBadgeTone { neutral, brand, success, warning, danger, info, dropSet }

class LiftrBadge extends StatelessWidget {
  const LiftrBadge({
    super.key,
    required this.label,
    this.tone = LiftrBadgeTone.neutral,
    this.icon,
    this.uppercase = false,
  });

  final String label;
  final LiftrBadgeTone tone;
  final IconData? icon;
  final bool uppercase;

  (Color bg, Color fg, Color border) _resolveColors(AppColors colors) {
    switch (tone) {
      case LiftrBadgeTone.neutral:
        return (colors.surfaceVariant, colors.textSecondary, colors.border);
      case LiftrBadgeTone.brand:
      case LiftrBadgeTone.success:
      case LiftrBadgeTone.warning:
      case LiftrBadgeTone.info:
      case LiftrBadgeTone.dropSet:
        return (colors.surfaceVariant, colors.textSecondary, colors.divider);
      case LiftrBadgeTone.danger:
        return (
          colors.danger.withValues(alpha: 0.14),
          colors.danger,
          colors.danger.withValues(alpha: 0.3),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final (bg, fg, border) = _resolveColors(colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius.xs),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              uppercase ? label.toUpperCase() : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
                fontFeatures: AppTypography.tabularFeatures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
