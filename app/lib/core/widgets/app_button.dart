import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_motion.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';

enum AppButtonType { primary, secondary, text, destructive }

class AppButton extends StatefulWidget {
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

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : _type = AppButtonType.destructive;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonType _type;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  void _handleTap() {
    if (widget.onPressed == null || widget.isLoading) return;
    HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  void _setPressed(bool pressed) {
    if (_isPressed == pressed) return;
    setState(() => _isPressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final motion = context.appMotion;
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final hasSolidFill =
        widget._type == AppButtonType.primary ||
        widget._type == AppButtonType.destructive;

    final Color fgColor;
    switch (widget._type) {
      case AppButtonType.primary:
      case AppButtonType.destructive:
        fgColor = isDisabled ? colors.textDisabled : colors.onPrimary;
        break;
      case AppButtonType.secondary:
        fgColor = isDisabled ? colors.textDisabled : colors.textPrimary;
        break;
      case AppButtonType.text:
        fgColor = isDisabled ? colors.textDisabled : colors.primaryLight;
        break;
    }

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: fgColor),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: hasSolidFill || isDisabled ? fgColor : null,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final Widget button;
    switch (widget._type) {
      case AppButtonType.primary:
        button = SizedBox(
          width: double.infinity,
          height: 52,
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
              shadowColor: Colors.transparent,
            ),
            child: content,
          ),
        );
        break;
      case AppButtonType.destructive:
        button = SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isDisabled ? null : _handleTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: colors.onPrimary,
              disabledBackgroundColor: colors.surfaceElevated,
              disabledForegroundColor: colors.textDisabled,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius.medium),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: content,
          ),
        );
        break;
      case AppButtonType.secondary:
        button = SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: isDisabled ? null : _handleTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              disabledForegroundColor: colors.textDisabled,
              side: BorderSide(
                color: isDisabled
                    ? colors.borderSubtle
                    : colors.borderInteractive,
              ),
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius.medium),
              ),
            ),
            child: content,
          ),
        );
        break;
      case AppButtonType.text:
        button = TextButton(
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
        break;
    }

    return Listener(
      onPointerDown: isDisabled ? null : (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: (_isPressed && !isDisabled) ? 0.985 : 1.0,
        duration: motion.resolve(context, motion.fast),
        curve: motion.curveStandard,
        child: button,
      ),
    );
  }
}
