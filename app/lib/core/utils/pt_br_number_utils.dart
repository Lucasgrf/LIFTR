import 'package:flutter/services.dart';

/// Parses a numeric string accepting both PT-BR comma decimals (`82,5`,
/// `1.200,5`) and dot decimals (`82.5`).
double? parsePtBrDouble(String? raw) {
  if (raw == null) return null;
  var normalized = raw.trim().replaceAll(RegExp(r'\s+'), '');
  if (normalized.isEmpty) return null;

  final hasComma = normalized.contains(',');
  final hasDot = normalized.contains('.');

  if (hasComma && hasDot) {
    final lastComma = normalized.lastIndexOf(',');
    final lastDot = normalized.lastIndexOf('.');
    if (lastComma > lastDot) {
      // Ex.: 1.200,50 -> 1200.50
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // Ex.: 1,200.50 -> 1200.50
      normalized = normalized.replaceAll(',', '');
    }
  } else if (hasComma) {
    final commaCount = ','.allMatches(normalized).length;
    if (commaCount > 1) return null;
    normalized = normalized.replaceAll(',', '.');
  } else if (hasDot) {
    final dotCount = '.'.allMatches(normalized).length;
    if (dotCount > 1) {
      // Only accept multiple dots if they look like thousands grouping (e.g. 1.200.000).
      final parts = normalized.split('.');
      final validGrouping = parts.first.isNotEmpty &&
          parts.skip(1).every((p) => p.length == 3 && RegExp(r'^\d+$').hasMatch(p));
      if (!validGrouping) return null;
      normalized = normalized.replaceAll('.', '');
    } else if (dotCount == 1) {
      // Treat PT-BR 3-digit grouping such as "1.000" as 1000, while keeping
      // genuine small decimals like "0.125" or "80.5".
      final parts = normalized.split('.');
      final isPtBrThousands =
          RegExp(r'^[1-9]\d{0,2}$').hasMatch(parts[0]) &&
          RegExp(r'^\d{3}$').hasMatch(parts[1]);
      if (isPtBrThousands) {
        normalized = '${parts[0]}${parts[1]}';
      }
    }
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
