import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';

enum AppButtonType { primary, secondary, text }

class AppButton extends StatelessWidget {
  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : _type = AppButtonType.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : _type = AppButtonType.secondary;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : _type = AppButtonType.text;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonType _type;

  void _handleTap() {
    if (onPressed == null || isLoading) return;
    HapticFeedback.lightImpact();
    onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final isDisabled = onPressed == null || isLoading;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _type == AppButtonType.primary
                    ? colors.onPrimary
                    : colors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _type == AppButtonType.primary
                      ? (isDisabled ? colors.textDisabled : colors.onPrimary)
                      : null,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    switch (_type) {
      case AppButtonType.primary:
        return Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius.medium),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: isDisabled ? null : _handleTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              disabledBackgroundColor: colors.surfaceElevated,
              disabledForegroundColor: colors.textDisabled,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius.medium),
              ),
              elevation: 0,
            ),
            child: content,
          ),
        );
      case AppButtonType.secondary:
        return SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: isDisabled ? null : _handleTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primaryLight,
              disabledForegroundColor: colors.textDisabled,
              side: BorderSide(
                color: isDisabled
                    ? colors.border
                    : colors.primary.withValues(alpha: 0.5),
              ),
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius.medium),
              ),
            ),
            child: content,
          ),
        );
      case AppButtonType.text:
        return TextButton(
          onPressed: isDisabled ? null : _handleTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: colors.primaryLight,
            disabledForegroundColor: colors.textDisabled,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius.small),
            ),
          ),
          child: content,
        );
    }
  }
}
