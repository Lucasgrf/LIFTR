import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserGoal {
  bulking,
  cutting,
  maintenance;

  String get label {
    switch (this) {
      case UserGoal.bulking:
        return 'Bulking';
      case UserGoal.cutting:
        return 'Cutting';
      case UserGoal.maintenance:
        return 'Manutenção';
    }
  }

  String get subtitle {
    switch (this) {
      case UserGoal.bulking:
        return 'Ganhar massa muscular com superávit controlado';
      case UserGoal.cutting:
        return 'Reduzir gordura preservando força e massa magra';
      case UserGoal.maintenance:
        return 'Recomposição gradual mantendo peso estável';
    }
  }

  String get weeklyRateTargetLabel {
    switch (this) {
      case UserGoal.bulking:
        return '+0,20 a +0,35 kg/sem';
      case UserGoal.cutting:
        return '-0,35 a -0,50 kg/sem';
      case UserGoal.maintenance:
        return '-0,10 a +0,10 kg/sem';
    }
  }
}

enum UserExperience {
  beginner,
  intermediate;

  String get label {
    switch (this) {
      case UserExperience.beginner:
        return 'Iniciante';
      case UserExperience.intermediate:
        return 'Intermediário';
    }
  }

  String get subtitle {
    switch (this) {
      case UserExperience.beginner:
        return 'Menos de 1 ano treinando com consistência';
      case UserExperience.intermediate:
        return 'Mais de 1 ano, já controla técnica e cargas';
    }
  }
}

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive;

  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentário';
      case ActivityLevel.lightlyActive:
        return 'Levemente ativo';
      case ActivityLevel.moderatelyActive:
        return 'Moderadamente ativo';
      case ActivityLevel.veryActive:
        return 'Muito ativo';
    }
  }

  String get subtitle {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Trabalho sentado · < 4.000 passos/dia';
      case ActivityLevel.lightlyActive:
        return 'Caminhadas leves · 4.000–7.000 passos/dia';
      case ActivityLevel.moderatelyActive:
        return 'Rotina em movimento · 7.000–10.000 passos/dia';
      case ActivityLevel.veryActive:
        return 'Trabalho físico intenso · > 10.000 passos/dia';
    }
  }

  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.25;
      case ActivityLevel.lightlyActive:
        return 1.4;
      case ActivityLevel.moderatelyActive:
        return 1.55;
      case ActivityLevel.veryActive:
        return 1.725;
    }
  }
}

@immutable
class UserSettingsState {
  const UserSettingsState({
    this.biologicalSex = 'M',
    this.age = 27,
    this.heightCm = 178,
    this.weightKg = 78.4,
    this.bodyFatPercent,
    this.goal = UserGoal.bulking,
    this.experience = UserExperience.intermediate,
    this.activityLevel = ActivityLevel.moderatelyActive,
    this.trainingDaysPerWeek = 4,
    this.selectedSplitName = 'Upper / Lower',
    this.barbellIncrementKg = 2.5,
    this.dumbbellIncrementKg = 2.0,
    this.machineIncrementKg = 5.0,
    this.whatsappConnected = true,
    this.whatsappMaskedPhone = '+55 (11) 9****-4821',
    this.weeklyReportDay = 'Domingo',
    this.weeklyReportTime = '19:00',
    this.quietHoursEnabled = true,
    this.quietHoursRange = '22:00 – 07:00',
    this.onboardingCompleted = false,
  });

  final String biologicalSex;
  final int age;
  final int heightCm;
  final double weightKg;
  final double? bodyFatPercent;
  final UserGoal goal;
  final UserExperience experience;
  final ActivityLevel activityLevel;
  final int trainingDaysPerWeek;
  final String selectedSplitName;
  final double barbellIncrementKg;
  final double dumbbellIncrementKg;
  final double machineIncrementKg;
  final bool whatsappConnected;
  final String whatsappMaskedPhone;
  final String weeklyReportDay;
  final String weeklyReportTime;
  final bool quietHoursEnabled;
  final String quietHoursRange;
  final bool onboardingCompleted;

  /// Deterministic Mifflin-St Jeor + goal offset calculation.
  int get estimatedDailyCalories {
    final sexOffset = biologicalSex == 'F' ? -161.0 : 5.0;
    final bmr = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age) + sexOffset;
    final tdee = bmr * activityLevel.multiplier;
    final goalDelta = switch (goal) {
      UserGoal.bulking => 300.0,
      UserGoal.cutting => -400.0,
      UserGoal.maintenance => 0.0,
    };
    final rounded = ((tdee + goalDelta) / 50).round() * 50;
    return rounded.clamp(1400, 4800);
  }

  /// Deterministic daily protein target (2.0 g/kg).
  int get estimatedDailyProteinGrams => (weightKg * 2.0).round();

  double incrementForEquipment(String? equipment) {
    if (equipment == null) return barbellIncrementKg;
    final eq = equipment.toLowerCase();
    if (eq == 'dumbbell' || eq == 'kettlebell') {
      return dumbbellIncrementKg;
    }
    if (eq == 'machine' || eq == 'cable') {
      return machineIncrementKg;
    }
    if (eq == 'bodyweight' || eq == 'band') {
      return 1.0;
    }
    return barbellIncrementKg;
  }

  UserSettingsState copyWith({
    String? biologicalSex,
    int? age,
    int? heightCm,
    double? weightKg,
    double? bodyFatPercent,
    bool clearBodyFat = false,
    UserGoal? goal,
    UserExperience? experience,
    ActivityLevel? activityLevel,
    int? trainingDaysPerWeek,
    String? selectedSplitName,
    double? barbellIncrementKg,
    double? dumbbellIncrementKg,
    double? machineIncrementKg,
    bool? whatsappConnected,
    String? whatsappMaskedPhone,
    String? weeklyReportDay,
    String? weeklyReportTime,
    bool? quietHoursEnabled,
    String? quietHoursRange,
    bool? onboardingCompleted,
  }) {
    return UserSettingsState(
      biologicalSex: biologicalSex ?? this.biologicalSex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPercent:
          clearBodyFat ? null : (bodyFatPercent ?? this.bodyFatPercent),
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      activityLevel: activityLevel ?? this.activityLevel,
      trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
      selectedSplitName: selectedSplitName ?? this.selectedSplitName,
      barbellIncrementKg: barbellIncrementKg ?? this.barbellIncrementKg,
      dumbbellIncrementKg: dumbbellIncrementKg ?? this.dumbbellIncrementKg,
      machineIncrementKg: machineIncrementKg ?? this.machineIncrementKg,
      whatsappConnected: whatsappConnected ?? this.whatsappConnected,
      whatsappMaskedPhone: whatsappMaskedPhone ?? this.whatsappMaskedPhone,
      weeklyReportDay: weeklyReportDay ?? this.weeklyReportDay,
      weeklyReportTime: weeklyReportTime ?? this.weeklyReportTime,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursRange: quietHoursRange ?? this.quietHoursRange,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

class UserSettingsNotifier extends StateNotifier<UserSettingsState> {
  UserSettingsNotifier() : super(const UserSettingsState());

  void updateBodyData({
    String? biologicalSex,
    int? age,
    int? heightCm,
    double? weightKg,
    double? bodyFatPercent,
    bool clearBodyFat = false,
  }) {
    state = state.copyWith(
      biologicalSex: biologicalSex,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      bodyFatPercent: bodyFatPercent,
      clearBodyFat: clearBodyFat,
    );
  }

  void setGoal(UserGoal goal) {
    state = state.copyWith(goal: goal);
  }

  void setExperience(UserExperience experience) {
    state = state.copyWith(experience: experience);
  }

  void setActivityLevel(ActivityLevel level) {
    state = state.copyWith(activityLevel: level);
  }

  void setSchedule({
    required int daysPerWeek,
    required String splitName,
  }) {
    state = state.copyWith(
      trainingDaysPerWeek: daysPerWeek,
      selectedSplitName: splitName,
    );
  }

  void setEquipmentIncrement({
    double? barbell,
    double? dumbbell,
    double? machine,
  }) {
    state = state.copyWith(
      barbellIncrementKg: barbell,
      dumbbellIncrementKg: dumbbell,
      machineIncrementKg: machine,
    );
  }

  void setWhatsappConnected(bool connected) {
    state = state.copyWith(whatsappConnected: connected);
  }

  void setWeeklyReportSchedule(String day, String time) {
    state = state.copyWith(weeklyReportDay: day, weeklyReportTime: time);
  }

  void setQuietHoursEnabled(bool enabled) {
    state = state.copyWith(quietHoursEnabled: enabled);
  }

  void completeOnboarding({bool whatsappConnected = false}) {
    state = state.copyWith(
      whatsappConnected: whatsappConnected,
      onboardingCompleted: true,
    );
  }
}

final userSettingsProvider =
    StateNotifierProvider<UserSettingsNotifier, UserSettingsState>((ref) {
  return UserSettingsNotifier();
});
