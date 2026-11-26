import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';

/// Grouped surface container for settings and profile rows with hairline dividers.
class LiftrListGroup extends StatelessWidget {
  const LiftrListGroup({
    super.key,
    required this.children,
    this.header,
  });

  final List<Widget> children;
  final String? header;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final cardRadius = BorderRadius.circular(radius.large);

    final group = Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: cardRadius,
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: cardRadius,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ),
    );

    if (header == null) {
      return group;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(header!, style: AppTypography.eyebrow(context)),
        ),
        group,
      ],
    );
  }
}

/// Interactive or informational row inside a [LiftrListGroup].
class LiftrListRow extends StatelessWidget {
  const LiftrListRow({
    super.key,
    required this.label,
    this.value = '',
    this.subtitle,
    this.valueColor,
    this.labelColor,
    this.leading,
    this.trailing,
    this.showChevron = true,
    this.onTap,
  });

  /// Accessible toggle row using [MergeSemantics], full-row [InkWell], and [Switch.adaptive].
  const factory LiftrListRow.toggle({
    Key? key,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
    Color? activeColor,
  }) = _LiftrToggleListRow;

  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final Color? labelColor;
  final Widget? leading;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final rowContent = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: labelColor ?? colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: context.textTheme.labelMedium?.copyWith(
                  color: valueColor ?? colors.textSecondary,
                  fontFeatures: AppTypography.tabularFeatures,
                ),
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ] else if (showChevron) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: colors.textTertiary,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return rowContent;
    }

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: rowContent,
      ),
    );
  }
}

class _LiftrToggleListRow extends LiftrListRow {
  const _LiftrToggleListRow({
    super.key,
    required super.label,
    required bool value,
    required this.onChanged,
    super.subtitle,
    this.activeColor,
  }) : toggleValue = value;

  final bool toggleValue;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!toggleValue),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.textTertiary,
                          fontFeatures: AppTypography.tabularFeatures,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch.adaptive(
                value: toggleValue,
                activeTrackColor: activeColor ?? colors.primary,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
