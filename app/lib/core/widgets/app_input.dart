import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/utils/pt_br_number_utils.dart';

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
    this.autofocus = false,
    this.suffix,
    this.prefix,
    this.suffixText,
    this.errorText,
    this.helperText,
    this.style,
    this.fillColor,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
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
  final bool autofocus;
  final Widget? suffix;
  final Widget? prefix;
  final String? suffixText;
  final String? errorText;
  final String? helperText;
  final TextStyle? style;
  final Color? fillColor;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final int? minLines;

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
    final Widget? effectiveSuffix =
        widget.suffix ??
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
          autofocus: widget.autofocus,
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.obscureText ? null : widget.minLines,
          style: widget.style,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefix,
            suffixIcon: effectiveSuffix,
            suffixText: widget.suffixText,
            errorText: widget.errorText,
            helperText: widget.helperText,
            filled: widget.fillColor != null ? true : null,
            fillColor: widget.fillColor,
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
    final formattedValue = value == value.toInt()
        ? value.toInt().toString()
        : formatPtBrDecimal(value, decimalDigits: 1, trimTrailingZero: false);
    final displayText = '$formattedValue${unit != null ? ' $unit' : ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: colors.textSecondary),
        ),
        AppSpacing.verticalGap8,
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          child: Row(
            children: [
              Semantics(
                label: 'Diminuir $label',
                button: true,
                child: IconButton(
                  tooltip: 'Diminuir $label',
                  onPressed: value - step >= min ? _decrement : null,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.remove, size: 20),
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
                  tooltip: 'Aumentar $label',
                  onPressed: value + step <= max ? _increment : null,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.add, size: 20),
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
