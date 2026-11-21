enum HistoryEventType {
  workout,
  weight,
  nutrition,
  goalCheckpoint;

  String get label {
    switch (this) {
      case HistoryEventType.workout:
        return 'Treinos';
      case HistoryEventType.weight:
        return 'Peso';
      case HistoryEventType.nutrition:
        return 'Nutrição';
      case HistoryEventType.goalCheckpoint:
        return 'Metas';
    }
  }
}
