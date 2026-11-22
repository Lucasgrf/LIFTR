import 'package:flutter/foundation.dart';

enum AiWorkoutGoal {
  hypertrophy,
  fatLoss,
  strength,
  conditioning,
  recomposition;

  String get label {
    switch (this) {
      case AiWorkoutGoal.hypertrophy:
        return 'Hipertrofia';
      case AiWorkoutGoal.fatLoss:
        return 'Emagrecimento & Definição';
      case AiWorkoutGoal.strength:
        return 'Força & Performance';
      case AiWorkoutGoal.conditioning:
        return 'Condicionamento & Saúde';
      case AiWorkoutGoal.recomposition:
        return 'Recomposição Corporal';
    }
  }

  String get subtitle {
    switch (this) {
      case AiWorkoutGoal.hypertrophy:
        return 'Maximizar volume efetivo e progressão de cargas para ganho muscular';
      case AiWorkoutGoal.fatLoss:
        return 'Preservar massa magra com gasto energético estratégico e cardio';
      case AiWorkoutGoal.strength:
        return 'Ênfase em exercícios compostos, faixas de 4-8 reps e descansos completos';
      case AiWorkoutGoal.conditioning:
        return 'Equilíbrio entre força funcional, mobilidade e capacidade cardiorrespiratória';
      case AiWorkoutGoal.recomposition:
        return 'Evoluir cargas gradualmente enquanto reduz percentual de gordura';
    }
  }

  String get apiValue {
    switch (this) {
      case AiWorkoutGoal.hypertrophy:
        return 'hypertrophy';
      case AiWorkoutGoal.fatLoss:
        return 'fat_loss';
      case AiWorkoutGoal.strength:
        return 'strength';
      case AiWorkoutGoal.conditioning:
        return 'conditioning';
      case AiWorkoutGoal.recomposition:
        return 'recomposition';
    }
  }
}

enum AiWorkoutExperience {
  beginner,
  intermediate,
  advanced;

  String get label {
    switch (this) {
      case AiWorkoutExperience.beginner:
        return 'Iniciante';
      case AiWorkoutExperience.intermediate:
        return 'Intermediário';
      case AiWorkoutExperience.advanced:
        return 'Avançado';
    }
  }

  String get subtitle {
    switch (this) {
      case AiWorkoutExperience.beginner:
        return 'Começando agora ou menos de 1 ano contínuo — seleção simples e segura';
      case AiWorkoutExperience.intermediate:
        return '1 a 3 anos de treino consistente — domina execução e progressão dupla';
      case AiWorkoutExperience.advanced:
        return 'Mais de 3 anos — suporta maior volume específico e variação de estímulos';
    }
  }

  String get apiValue => name;
}

enum AiEquipmentAccess {
  fullGym,
  homeDumbbells,
  minimal;

  String get label {
    switch (this) {
      case AiEquipmentAccess.fullGym:
        return 'Academia completa';
      case AiEquipmentAccess.homeDumbbells:
        return 'Halteres, barra e banco';
      case AiEquipmentAccess.minimal:
        return 'Equipamento mínimo / Casa';
    }
  }

  String get subtitle {
    switch (this) {
      case AiEquipmentAccess.fullGym:
        return 'Máquinas, polias/cabos, barras livres, halteres e aparelhos de cardio';
      case AiEquipmentAccess.homeDumbbells:
        return 'Pesos livres sem máquinas guiadas ou cabos';
      case AiEquipmentAccess.minimal:
        return 'Peso corporal, halteres leves ou elásticos';
    }
  }

  String get apiValue {
    switch (this) {
      case AiEquipmentAccess.fullGym:
        return 'full_gym';
      case AiEquipmentAccess.homeDumbbells:
        return 'home_dumbbells';
      case AiEquipmentAccess.minimal:
        return 'minimal';
    }
  }
}

@immutable
class AiWorkoutRequest {
  const AiWorkoutRequest({
    required this.goal,
    required this.experience,
    required this.daysPerWeek,
    this.sessionMinutes = 60,
    this.preferredSplit,
    this.focusMuscles = const [],
    this.equipmentAccess = AiEquipmentAccess.fullGym,
    this.includeCardio = true,
    this.cardioMinutesPerSession = 15,
    this.restrictionsNotes,
    this.biologicalSex,
  });

  final AiWorkoutGoal goal;
  final AiWorkoutExperience experience;
  final int daysPerWeek;
  final int sessionMinutes;
  final String? preferredSplit;
  final List<String> focusMuscles;
  final AiEquipmentAccess equipmentAccess;
  final bool includeCardio;
  final int cardioMinutesPerSession;
  final String? restrictionsNotes;
  final String? biologicalSex;

  Map<String, dynamic> toJson() {
    final trimmedSplit = preferredSplit?.trim();
    final trimmedNotes = restrictionsNotes?.trim();
    return {
      'goal': goal.apiValue,
      'experience': experience.apiValue,
      'days_per_week': daysPerWeek.clamp(2, 6),
      'session_minutes': sessionMinutes.clamp(25, 120),
      if (trimmedSplit != null && trimmedSplit.isNotEmpty)
        'preferred_split': trimmedSplit,
      'focus_muscles': focusMuscles,
      'equipment_access': equipmentAccess.apiValue,
      'include_cardio': includeCardio,
      'cardio_minutes_per_session': includeCardio
          ? cardioMinutesPerSession.clamp(5, 90)
          : 0,
      if (trimmedNotes != null && trimmedNotes.isNotEmpty)
        'restrictions_notes': trimmedNotes,
      if (biologicalSex == 'M' || biologicalSex == 'F')
        'biological_sex': biologicalSex,
    };
  }
}
