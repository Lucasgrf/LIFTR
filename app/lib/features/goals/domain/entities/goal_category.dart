enum GoalCategory {
  weight,
  calories,
  protein,
  trainingFrequency,
  exerciseWeight,
  exerciseReps,
  measurement,
  habit,
  custom;

  String get label {
    switch (this) {
      case GoalCategory.weight:
        return 'Peso Corporal';
      case GoalCategory.calories:
        return 'Calorias';
      case GoalCategory.protein:
        return 'Proteína';
      case GoalCategory.trainingFrequency:
        return 'Frequência de Treino';
      case GoalCategory.exerciseWeight:
        return 'Carga em Exercício';
      case GoalCategory.exerciseReps:
        return 'Repetições em Exercício';
      case GoalCategory.measurement:
        return 'Medida Corporal';
      case GoalCategory.habit:
        return 'Hábito';
      case GoalCategory.custom:
        return 'Personalizada';
    }
  }

  String get defaultUnit {
    switch (this) {
      case GoalCategory.weight:
      case GoalCategory.exerciseWeight:
        return 'kg';
      case GoalCategory.calories:
        return 'kcal';
      case GoalCategory.protein:
        return 'g';
      case GoalCategory.trainingFrequency:
        return 'dias/sem';
      case GoalCategory.exerciseReps:
        return 'reps';
      case GoalCategory.measurement:
        return 'cm';
      case GoalCategory.habit:
      case GoalCategory.custom:
        return '';
    }
  }
}
