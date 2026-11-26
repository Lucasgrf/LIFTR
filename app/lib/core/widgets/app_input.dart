import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';

class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.onFieldSubmitted,
    this.obscureText = false,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.autovalidateMode,
    this.enabled = true,
    this.suffix,
    this.prefix,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final AutovalidateMode? autovalidateMode;
  final bool enabled;
  final Widget? suffix;
  final Widget? prefix;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int? maxLines;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late bool _obscured = widget.obscureText;

  @override
  void didUpdateWidget(covariant AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget? effectiveSuffix = widget.suffix ??
        (widget.obscureText
            ? IconButton(
                onPressed: widget.enabled
                    ? () => setState(() => _obscured = !_obscured)
                    : null,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                tooltip: _obscured ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(
                  _obscured
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 20,
                  color: context.appColors.textSecondary,
                ),
              )
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.appColors.textSecondary,
                ),
          ),
          AppSpacing.verticalGap8,
        ],
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          focusNode: widget.focusNode,
          onFieldSubmitted: widget.onFieldSubmitted,
          obscureText: widget.obscureText ? _obscured : false,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          autovalidateMode: widget.autovalidateMode,
          enabled: widget.enabled,
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefix,
            suffixIcon: effectiveSuffix,
          ),
        ),
      ],
    );
  }
}

class AppNumericInput extends StatelessWidget {
  const AppNumericInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
    this.step = 1,
    this.unit,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double step;
  final String? unit;

  void _increment() {
    if (value + step <= max) {
      HapticFeedback.selectionClick();
      onChanged(value + step);
    }
  }

  void _decrement() {
    if (value - step >= min) {
      HapticFeedback.selectionClick();
      onChanged(value - step);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final formattedValue =
        value == value.toInt() ? value.toInt().toString() : value.toStringAsFixed(1);
    final displayText = '$formattedValue${unit != null ? ' $unit' : ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
              ),
        ),
        AppSpacing.verticalGap8,
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(radius.small),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Semantics(
                label: 'Diminuir $label',
                button: true,
                child: IconButton(
                  onPressed: value - step >= min ? _decrement : null,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(Icons.remove_rounded, size: 20),
                  color: colors.textPrimary,
                  disabledColor: colors.textDisabled,
                ),
              ),
              Expanded(
                child: Semantics(
                  label: '$label: $displayText',
                  child: Center(
                    child: Text(
                      displayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFeatures: AppTypography.tabularFeatures,
                          ),
                    ),
                  ),
                ),
              ),
              Semantics(
                label: 'Aumentar $label',
                button: true,
                child: IconButton(
                  onPressed: value + step <= max ? _increment : null,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  color: colors.textPrimary,
                  disabledColor: colors.textDisabled,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
