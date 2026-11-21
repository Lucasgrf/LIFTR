import 'package:flutter/foundation.dart';

/// Pure Domain Entity representing adherence for a specific calendar day in the week.
@immutable
class DayAdherence {
  const DayAdherence({
    required this.date,
    required this.dayOfWeek,
    this.hasCompletedWorkout = false,
    this.isToday = false,
  });

  final DateTime date;
  final int dayOfWeek; // 0 = Dom, 1 = Seg ... 6 = Sáb
  final bool hasCompletedWorkout;
  final bool isToday;

  String get shortLabel {
    switch (dayOfWeek) {
      case 0:
        return 'D';
      case 1:
        return 'S';
      case 2:
        return 'T';
      case 3:
        return 'Q';
      case 4:
        return 'Q';
      case 5:
        return 'S';
      case 6:
        return 'S';
      default:
        return '';
    }
  }

  DayAdherence copyWith({
    DateTime? date,
    int? dayOfWeek,
    bool? hasCompletedWorkout,
    bool? isToday,
  }) {
    return DayAdherence(
      date: date ?? this.date,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      hasCompletedWorkout: hasCompletedWorkout ?? this.hasCompletedWorkout,
      isToday: isToday ?? this.isToday,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayAdherence &&
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day &&
        other.dayOfWeek == dayOfWeek &&
        other.hasCompletedWorkout == hasCompletedWorkout &&
        other.isToday == isToday;
  }

  @override
  int get hashCode => Object.hash(
        date.year,
        date.month,
        date.day,
        dayOfWeek,
        hasCompletedWorkout,
        isToday,
      );
}
