import 'package:personal_fitness_os/core/utils/pt_br_number_utils.dart';

/// Formats an integer count with the proper PT-BR singular/plural noun.
///
/// Example: `pluralize(1, 'série', 'séries')` -> `'1 série'`.
String pluralize(int count, String singular, String plural) {
  final word = count == 1 ? singular : plural;
  return '$count $word';
}

/// Formats a weight in kilograms using PT-BR comma decimal separator.
///
/// Whole values omit `.0` / `,0` by default (`80 kg`, `82,5 kg`).
String formatWeightKgPtBr(
  double weightKg, {
  int decimals = 1,
  bool trimTrailingZero = true,
}) {
  return '${formatPtBrDecimal(
    weightKg,
    decimalDigits: decimals,
    trimTrailingZero: trimTrailingZero,
  )} kg';
}

/// Maps internal exercise `movement_pattern` keys to user-facing PT-BR labels.
String formatMovementPatternPtBr(String? pattern) {
  final raw = pattern?.trim() ?? '';
  if (raw.isEmpty) return 'Não informado';
  switch (raw.toLowerCase()) {
    case 'horizontal_push':
      return 'Empurrar horizontal';
    case 'vertical_push':
      return 'Empurrar vertical';
    case 'horizontal_pull':
      return 'Puxar horizontal';
    case 'vertical_pull':
      return 'Puxar vertical';
    case 'squat':
      return 'Agachamento';
    case 'hinge':
      return 'Dobradiça de quadril';
    case 'lunge':
      return 'Avanço';
    case 'isolation':
      return 'Isolamento';
    case 'carry':
      return 'Transporte';
    case 'core':
      return 'Core';
    case 'cardio':
      return 'Cardio';
    default:
      final spaced = raw.replaceAll('_', ' ').trim();
      if (spaced.isEmpty) return 'Não informado';
      return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

/// Maps internal exercise `equipment` keys to user-facing PT-BR labels.
String formatEquipmentPtBr(String? equipment) {
  final raw = equipment?.trim() ?? '';
  if (raw.isEmpty) return '';
  switch (raw.toLowerCase()) {
    case 'barbell':
      return 'Barra';
    case 'dumbbell':
      return 'Halteres';
    case 'machine':
      return 'Máquina';
    case 'cable':
      return 'Polia';
    case 'bodyweight':
      return 'Peso corporal';
    case 'kettlebell':
      return 'Kettlebell';
    case 'band':
    case 'resistance_band':
      return 'Elástico';
    case 'smith':
    case 'smith_machine':
      return 'Máquina Smith';
    case 'ez_bar':
      return 'Barra W';
    case 'plate':
      return 'Anilha';
    default:
      final spaced = raw.replaceAll('_', ' ').trim();
      if (spaced.isEmpty) return '';
      return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

/// Maps stored `'M'` / `'F'` biological sex codes to user-facing PT-BR labels.
String formatBiologicalSexPtBr(String? sex) {
  final normalized = sex?.trim().toUpperCase() ?? '';
  switch (normalized) {
    case 'M':
      return 'Masculino';
    case 'F':
      return 'Feminino';
    default:
      return 'Não informado';
  }
}
