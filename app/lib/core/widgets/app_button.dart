import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_motion.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';

enum AppButtonType { primary, secondary, text, destructive }

class AppButton extends StatefulWidget {
  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.autofocus = false,
  }) : _type = AppButtonType.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.autofocus = false,
  }) : _type = AppButtonType.secondary;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.autofocus = false,
  }) : _type = AppButtonType.text;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.autofocus = false,
  }) : _type = AppButtonType.destructive;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool autofocus;
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

  Widget _buttonLabel(BuildContext context, Color foreground) => Text(
    widget.label,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final motion = context.appMotion;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    final Color fgColor;
    switch (widget._type) {
      case AppButtonType.primary:
        fgColor = isDisabled ? colors.textDisabled : colors.background;
        break;
      case AppButtonType.destructive:
        fgColor = isDisabled ? colors.textDisabled : colors.onPrimary;
        break;
      case AppButtonType.secondary:
        fgColor = isDisabled ? colors.textDisabled : colors.textPrimary;
        break;
      case AppButtonType.text:
        fgColor = isDisabled ? colors.textDisabled : colors.textPrimary;
        break;
    }

    final isTextButton = widget._type == AppButtonType.text;
    final content = Row(
      mainAxisSize: isTextButton ? MainAxisSize.min : MainAxisSize.max,
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
          AppSpacing.horizontalGap8,
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: fgColor),
          AppSpacing.horizontalGap8,
        ],
        if (isTextButton)
          Flexible(child: _buttonLabel(context, fgColor))
        else
          Expanded(child: _buttonLabel(context, fgColor)),
      ],
    );

    final Widget button;
    switch (widget._type) {
      case AppButtonType.primary:
        button = ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: double.infinity,
            minHeight: 56,
          ),
          child: ElevatedButton(
            autofocus: widget.autofocus,
            onPressed: isDisabled ? null : _handleTap,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: context.appSpacing.space16,
                vertical: context.appSpacing.space12,
              ),
              backgroundColor: colors.textPrimary,
              foregroundColor: colors.background,
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
        button = ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: double.infinity,
            minHeight: 56,
          ),
          child: ElevatedButton(
            autofocus: widget.autofocus,
            onPressed: isDisabled ? null : _handleTap,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: context.appSpacing.space16,
                vertical: context.appSpacing.space12,
              ),
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
        button = ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: double.infinity,
            minHeight: 56,
          ),
          child: OutlinedButton(
            autofocus: widget.autofocus,
            onPressed: isDisabled ? null : _handleTap,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: context.appSpacing.space16,
                vertical: context.appSpacing.space12,
              ),
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
          autofocus: widget.autofocus,
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
