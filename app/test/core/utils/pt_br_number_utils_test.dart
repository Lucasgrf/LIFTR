import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/utils/pt_br_number_utils.dart';

void main() {
  group('pt_br_number_utils', () {
    test('parsePtBrDouble parses PT-BR commas, dot decimals and thousands separators', () {
      expect(parsePtBrDouble('82,5'), 82.5);
      expect(parsePtBrDouble('82.5'), 82.5);
      expect(parsePtBrDouble(' 1.200,75 '), 1200.75);
      expect(parsePtBrDouble('1,200.75'), 1200.75);
      expect(parsePtBrDouble('100'), 100.0);
      expect(parsePtBrDouble('0,25'), 0.25);
    });

    test('parsePtBrDouble rejects empty or malformed inputs', () {
      expect(parsePtBrDouble(null), isNull);
      expect(parsePtBrDouble(''), isNull);
      expect(parsePtBrDouble('   '), isNull);
      expect(parsePtBrDouble('abc'), isNull);
      expect(parsePtBrDouble('12,34,56'), isNull);
      expect(parsePtBrDouble('12.34.56'), isNull);
    });

    test('formatPtBrDecimal formats with comma and optional zero trimming', () {
      expect(formatPtBrDecimal(80.0), '80');
      expect(formatPtBrDecimal(82.5), '82,5');
      expect(formatPtBrDecimal(82.50, decimalDigits: 2), '82,5');
      expect(formatPtBrDecimal(80.0, decimalDigits: 1, trimTrailingZero: false), '80,0');
      expect(formatPtBrDecimal(-0.0), '0');
    });

    test('PtBrDecimalInputFormatter allows comma/dot up to maxDecimalDigits and blocks junk', () {
      final formatter = PtBrDecimalInputFormatter(maxDecimalDigits: 1);
      const old = TextEditingValue(text: '82,5');

      expect(
        formatter.formatEditUpdate(const TextEditingValue(), const TextEditingValue(text: '82,5')).text,
        '82,5',
      );
      expect(
        formatter.formatEditUpdate(const TextEditingValue(), const TextEditingValue(text: '82.5')).text,
        '82.5',
      );
      expect(
        formatter.formatEditUpdate(old, const TextEditingValue(text: '82,55')).text,
        '82,5',
      );
      expect(
        formatter.formatEditUpdate(old, const TextEditingValue(text: '82,5,')).text,
        '82,5',
      );
      expect(
        formatter.formatEditUpdate(old, const TextEditingValue(text: '82a')).text,
        '82,5',
      );
    });
  });
}
