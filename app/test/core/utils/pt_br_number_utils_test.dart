import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/utils/pt_br_number_utils.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('pt_br_number_utils', () {
    test('parsePtBrDouble treats dot as decimal separator only (never thousands)', () {
      expect(parsePtBrDouble('2.500'), 2.5);
      expect(parsePtBrDouble('2.500'), isA<double>());
      expect(parsePtBrDouble('1.000'), 1.0);
      expect(parsePtBrDouble('1.000'), isA<double>());
      expect(parsePtBrDouble('72.500'), 72.5);
      expect(parsePtBrDouble('72.500'), isA<double>());
      expect(parsePtBrDouble('80,'), 80.0);
      expect(parsePtBrDouble('80,'), isA<double>());
      expect(parsePtBrDouble('80,5'), 80.5);
      expect(parsePtBrDouble('80,5'), isA<double>());
      expect(parsePtBrDouble('80.5'), 80.5);
      expect(parsePtBrDouble('82,5'), 82.5);
      expect(parsePtBrDouble('82.5'), 82.5);
      expect(parsePtBrDouble('100'), 100.0);
      expect(parsePtBrDouble('0,25'), 0.25);
      expect(parsePtBrDouble('0.125'), 0.125);
    });

    test('parsePtBrDouble rejects empty, mixed or malformed inputs', () {
      expect(parsePtBrDouble(null), isNull);
      expect(parsePtBrDouble(''), isNull);
      expect(parsePtBrDouble('   '), isNull);
      expect(parsePtBrDouble('abc'), isNull);
      expect(parsePtBrDouble('1.200,75'), isNull);
      expect(parsePtBrDouble('1,200.75'), isNull);
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

    test('PtBrDecimalInputFormatter handles 80,, 80,5, pasted 80.5, 1.000 and empty string', () {
      final formatter = PtBrDecimalInputFormatter(maxDecimalDigits: 1);
      const old = TextEditingValue(text: '82,5');

      expect(
        formatter.formatEditUpdate(const TextEditingValue(text: '80'), const TextEditingValue(text: '80,')).text,
        '80,',
      );
      expect(
        formatter.formatEditUpdate(const TextEditingValue(text: '80,'), const TextEditingValue(text: '80,5')).text,
        '80,5',
      );
      expect(
        formatter.formatEditUpdate(const TextEditingValue(), const TextEditingValue(text: '80.5')).text,
        '80.5',
      );
      expect(
        formatter.formatEditUpdate(old, const TextEditingValue(text: '')).text,
        '',
      );
      // 3 decimal digits after separator exceed maxDecimalDigits (1 or 2)
      expect(
        formatter.formatEditUpdate(const TextEditingValue(text: '1.0'), const TextEditingValue(text: '1.000')).text,
        '1.0',
      );
      expect(
        PtBrDecimalInputFormatter(maxDecimalDigits: 2)
            .formatEditUpdate(const TextEditingValue(text: '1.00'), const TextEditingValue(text: '1.000'))
            .text,
        '1.00',
      );
      expect(
        PtBrDecimalInputFormatter(maxDecimalDigits: 3)
            .formatEditUpdate(const TextEditingValue(), const TextEditingValue(text: '72.500'))
            .text,
        '72.500',
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

    test('UserSettings persists parsed PT-BR weights consistently as double', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final c1 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c1.dispose);

      c1.read(userSettingsProvider.notifier).updateBodyData(
            weightKg: parsePtBrDouble('80,5'),
          );
      await Future<void>.delayed(Duration.zero);

      final c2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c2.dispose);

      final reloaded = c2.read(userSettingsProvider);
      expect(reloaded.weightKg, 80.5);
      expect(reloaded.weightKg, isA<double>());
      expect(reloaded.toJson()['weightKg'], isA<double>());

      c2.read(userSettingsProvider.notifier).updateBodyData(
            weightKg: parsePtBrDouble('80,'),
          );
      expect(c2.read(userSettingsProvider).weightKg, 80.0);
      expect(c2.read(userSettingsProvider).weightKg, isA<double>());
    });
  });
}
