import 'package:flutter/services.dart';

/// Parses a numeric string accepting both `,` and `.` as decimal separator.
/// Both `"82,5"` and `"2.500"` are treated as decimals (`82.5` and `2.5`).
double? parsePtBrDouble(String? raw) {
  if (raw == null) return null;
  var normalized = raw.trim().replaceAll(RegExp(r'\s+'), '');
  if (normalized.isEmpty) return null;

  final hasComma = normalized.contains(',');
  final hasDot = normalized.contains('.');

  // Mixed separators (e.g. "1.200,50") are ambiguous when dot is always decimal.
  if (hasComma && hasDot) return null;

  if (hasComma) {
    if (','.allMatches(normalized).length > 1) return null;
    normalized = normalized.replaceAll(',', '.');
  } else if (hasDot) {
    if ('.'.allMatches(normalized).length > 1) return null;
  }

  return double.tryParse(normalized);
}

/// Formats [value] using comma as the PT-BR decimal separator.
String formatPtBrDecimal(
  double value, {
  int decimalDigits = 1,
  bool trimTrailingZero = true,
}) {
  final safeValue = value == 0 ? 0.0 : value;
  var formatted = safeValue.toStringAsFixed(decimalDigits);
  if (trimTrailingZero && formatted.contains('.')) {
    formatted = formatted.replaceFirst(RegExp(r'\.?0+$'), '');
  }
  return formatted.replaceAll('.', ',');
}

/// [TextInputFormatter] that allows non-negative decimal inputs using either
/// `,` or `.` as the decimal separator, bounded to [maxDecimalDigits].
class PtBrDecimalInputFormatter extends TextInputFormatter {
  PtBrDecimalInputFormatter({this.maxDecimalDigits = 2});

  final int maxDecimalDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final pattern = maxDecimalDigits <= 0
        ? RegExp(r'^\d+$')
        : RegExp('^\\d*(?:[.,]\\d{0,$maxDecimalDigits})?\$');

    return pattern.hasMatch(text) ? newValue : oldValue;
  }
}
