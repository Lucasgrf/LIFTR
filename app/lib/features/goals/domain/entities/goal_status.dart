enum GoalStatus {
  active,
  completed,
  abandoned,
  paused;

  String get label {
    switch (this) {
      case GoalStatus.active:
        return 'Ativa';
      case GoalStatus.completed:
        return 'Concluída';
      case GoalStatus.paused:
        return 'Pausada';
      case GoalStatus.abandoned:
        return 'Abandonada';
    }
  }
}
