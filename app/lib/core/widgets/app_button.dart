import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    final isDisabled = onPressed == null || isLoading;

    Widget content = Row(
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
                _type == AppButtonType.primary ? Colors.white : colors.primary,
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
            style: Theme.of(context).textTheme.labelLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    switch (_type) {
      case AppButtonType.primary:
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: colors.surfaceVariant,
              disabledForegroundColor: colors.textDisabled,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius.small),
              ),
              elevation: 0,
            ),
            child: content,
          ),
        );
      case AppButtonType.secondary:
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: isDisabled ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              disabledForegroundColor: colors.textDisabled,
              side: BorderSide(
                color: isDisabled ? colors.border : colors.primary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius.small),
              ),
            ),
            child: content,
          ),
        );
      case AppButtonType.text:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
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
