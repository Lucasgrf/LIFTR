import 'package:flutter/foundation.dart';

/// Immutable representation of a training split preset in the LIFTR catalog.
@immutable
class SplitPreset {
  const SplitPreset({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.daysPerWeek,
    required this.queueDescription,
    required this.sessions,
    this.focusTag,
  });

  final String id;
  final String name;
  final String shortLabel;
  final int daysPerWeek;
  final String queueDescription;
  final List<String> sessions;
  final String? focusTag;
}

/// Complete catalog of training split presets across 2 to 6 days/week.
///
/// Note: The first item in each `byDays[days]` list is the default automatic
/// recommendation for that frequency (preserving existing onboarding contracts).
class SplitPresets {
  const SplitPresets._();

  static const Map<int, List<SplitPreset>> byDays = {
    2: [
      SplitPreset(
        id: 'full_body_2x',
        name: 'Full Body 2×',
        shortLabel: 'Full Body 2×',
        daysPerWeek: 2,
        queueDescription: 'Fila de 2 treinos equilibrados de corpo inteiro',
        sessions: ['Full Body A', 'Full Body B'],
      ),
      SplitPreset(
        id: 'ab_2x',
        name: 'AB (Superior / Inferior)',
        shortLabel: 'AB',
        daysPerWeek: 2,
        queueDescription: 'Fila A/B alternando superiores e inferiores',
        sessions: ['Treino A — Superior', 'Treino B — Inferior'],
      ),
    ],
    3: [
      SplitPreset(
        id: 'full_body_3x',
        name: 'Full Body 3×',
        shortLabel: 'Full Body 3×',
        daysPerWeek: 3,
        queueDescription: 'Fila de 3 treinos completos de alta eficiência',
        sessions: ['Full Body A', 'Full Body B', 'Full Body C'],
      ),
      SplitPreset(
        id: 'abc_classic',
        name: 'ABC',
        shortLabel: 'ABC',
        daysPerWeek: 3,
        queueDescription:
            'Clássico A (Peito/Tríceps), B (Costas/Bíceps) e C (Pernas/Ombros)',
        sessions: [
          'Treino A — Peito e Tríceps',
          'Treino B — Costas e Bíceps',
          'Treino C — Pernas e Ombros',
        ],
      ),
      SplitPreset(
        id: 'ppl_3x',
        name: 'Push / Pull / Legs',
        shortLabel: 'PPL',
        daysPerWeek: 3,
        queueDescription: 'Fila rotativa de 3 padrões de movimento',
        sessions: ['Push', 'Pull', 'Legs'],
      ),
    ],
    4: [
      SplitPreset(
        id: 'upper_lower_4x',
        name: 'Upper / Lower',
        shortLabel: 'Upper / Lower',
        daysPerWeek: 4,
        queueDescription: 'Fila de 4 treinos alternando superiores e inferiores',
        sessions: ['Upper A', 'Lower A', 'Upper B', 'Lower B'],
      ),
      SplitPreset(
        id: 'abcd_classic',
        name: 'ABCD',
        shortLabel: 'ABCD',
        daysPerWeek: 4,
        queueDescription:
            'Divisão de 4 sessões (Peito/Tríceps · Costas/Bíceps · Pernas · Ombros/Core)',
        sessions: [
          'Treino A — Peito e Tríceps',
          'Treino B — Costas e Bíceps',
          'Treino C — Pernas Completo',
          'Treino D — Ombros e Core',
        ],
      ),
      SplitPreset(
        id: 'abcd_lower_glutes',
        name: 'ABCD · Inferiores & Glúteos',
        shortLabel: 'ABCD Inferiores',
        daysPerWeek: 4,
        queueDescription:
            '2 sessões dedicadas a inferiores/glúteos e 2 sessões de superiores',
        sessions: [
          'Treino A — Quadríceps e Glúteos',
          'Treino B — Costas e Ombros',
          'Treino C — Posterior e Glúteos',
          'Treino D — Peito, Braços e Core',
        ],
        focusTag: 'Foco Inferiores',
      ),
      SplitPreset(
        id: 'torso_limbs_4x',
        name: 'Torso / Membros',
        shortLabel: 'Torso / Membros',
        daysPerWeek: 4,
        queueDescription: 'Fila de 4 sessões equilibradas',
        sessions: ['Torso A', 'Membros A', 'Torso B', 'Membros B'],
      ),
    ],
    5: [
      SplitPreset(
        id: 'ul_full_5x',
        name: 'Upper / Lower + Full',
        shortLabel: 'UL + Full',
        daysPerWeek: 5,
        queueDescription: 'Fila de 5 sessões semanais de frequência mista',
        sessions: ['Upper A', 'Lower A', 'Upper B', 'Lower B', 'Full Body'],
      ),
      SplitPreset(
        id: 'ppl_ul_5x',
        name: 'PPL + Upper / Lower',
        shortLabel: 'PPL + UL',
        daysPerWeek: 5,
        queueDescription: 'Fila híbrida de 5 treinos (Push/Pull/Legs + Upper/Lower)',
        sessions: ['Push', 'Pull', 'Legs', 'Upper', 'Lower'],
      ),
      SplitPreset(
        id: 'abcde_5x',
        name: 'ABCDE',
        shortLabel: 'ABCDE',
        daysPerWeek: 5,
        queueDescription:
            '5 sessões com foco dedicado por grupo muscular a cada dia',
        sessions: [
          'Treino A — Peito',
          'Treino B — Costas',
          'Treino C — Pernas (Quadríceps e Glúteos)',
          'Treino D — Ombros e Trapézio',
          'Treino E — Posterior, Braços e Core',
        ],
      ),
    ],
    6: [
      SplitPreset(
        id: 'ppl_6x',
        name: 'Push / Pull / Legs 2×',
        shortLabel: 'PPL 2×',
        daysPerWeek: 6,
        queueDescription: 'Fila de 6 treinos de alta frequência por padrão',
        sessions: ['Push A', 'Pull A', 'Legs A', 'Push B', 'Pull B', 'Legs B'],
      ),
      SplitPreset(
        id: 'abc_2x',
        name: 'ABC 2×',
        shortLabel: 'ABC 2×',
        daysPerWeek: 6,
        queueDescription: 'Divisão ABC repetida duas vezes na semana',
        sessions: [
          'Treino A1 — Peito e Tríceps',
          'Treino B1 — Costas e Bíceps',
          'Treino C1 — Pernas e Ombros',
          'Treino A2 — Peito e Tríceps',
          'Treino B2 — Costas e Bíceps',
          'Treino C2 — Pernas e Ombros',
        ],
      ),
      SplitPreset(
        id: 'upper_lower_3x',
        name: 'Upper / Lower 3×',
        shortLabel: 'Upper / Lower 3×',
        daysPerWeek: 6,
        queueDescription: 'Fila rotativa de 6 sessões alternadas',
        sessions: [
          'Upper A',
          'Lower A',
          'Upper B',
          'Lower B',
          'Upper C',
          'Lower C',
        ],
      ),
    ],
  };

  static List<SplitPreset> forDays(int days) =>
      byDays[days] ?? byDays[4]!;

  /// Curated template list displayed in SwitchProgramSheet ("MODELOS PRONTOS").
  static List<SplitPreset> get featuredTemplates => [
        byDays[2]![1], // AB
        byDays[3]![0], // Full Body 3×
        byDays[3]![1], // ABC
        byDays[3]![2], // Push / Pull / Legs
        byDays[4]![0], // Upper / Lower
        byDays[4]![1], // ABCD
        byDays[4]![2], // ABCD · Inferiores & Glúteos
        byDays[5]![1], // PPL + Upper / Lower
        byDays[5]![2], // ABCDE
        byDays[6]![0], // Push / Pull / Legs 2×
      ];
}
