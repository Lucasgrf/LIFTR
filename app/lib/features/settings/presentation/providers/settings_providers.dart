import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'biologicalSex': biologicalSex,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'bodyFatPercent': bodyFatPercent,
      'goal': goal.name,
      'experience': experience.name,
      'activityLevel': activityLevel.name,
      'trainingDaysPerWeek': trainingDaysPerWeek,
      'selectedSplitName': selectedSplitName,
      'barbellIncrementKg': barbellIncrementKg,
      'dumbbellIncrementKg': dumbbellIncrementKg,
      'machineIncrementKg': machineIncrementKg,
      'whatsappConnected': whatsappConnected,
      'whatsappMaskedPhone': whatsappMaskedPhone,
      'weeklyReportDay': weeklyReportDay,
      'weeklyReportTime': weeklyReportTime,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursRange': quietHoursRange,
      'onboardingCompleted': onboardingCompleted,
    };
  }

  static T _parseEnum<T extends Enum>(
    List<T> values,
    Object? raw,
    T fallback,
  ) {
    if (raw is! String) return fallback;
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return fallback;
  }

  factory UserSettingsState.fromJson(Map<String, dynamic> json) {
    const defaults = UserSettingsState();
    return UserSettingsState(
      biologicalSex:
          json['biologicalSex'] as String? ?? defaults.biologicalSex,
      age: (json['age'] as num?)?.toInt() ?? defaults.age,
      heightCm: (json['heightCm'] as num?)?.toInt() ?? defaults.heightCm,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? defaults.weightKg,
      bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble(),
      goal: _parseEnum(UserGoal.values, json['goal'], defaults.goal),
      experience: _parseEnum(
        UserExperience.values,
        json['experience'],
        defaults.experience,
      ),
      activityLevel: _parseEnum(
        ActivityLevel.values,
        json['activityLevel'],
        defaults.activityLevel,
      ),
      trainingDaysPerWeek:
          (json['trainingDaysPerWeek'] as num?)?.toInt() ??
              defaults.trainingDaysPerWeek,
      selectedSplitName:
          json['selectedSplitName'] as String? ?? defaults.selectedSplitName,
      barbellIncrementKg:
          (json['barbellIncrementKg'] as num?)?.toDouble() ??
              defaults.barbellIncrementKg,
      dumbbellIncrementKg:
          (json['dumbbellIncrementKg'] as num?)?.toDouble() ??
              defaults.dumbbellIncrementKg,
      machineIncrementKg:
          (json['machineIncrementKg'] as num?)?.toDouble() ??
              defaults.machineIncrementKg,
      whatsappConnected:
          json['whatsappConnected'] as bool? ?? defaults.whatsappConnected,
      whatsappMaskedPhone:
          json['whatsappMaskedPhone'] as String? ??
              defaults.whatsappMaskedPhone,
      weeklyReportDay:
          json['weeklyReportDay'] as String? ?? defaults.weeklyReportDay,
      weeklyReportTime:
          json['weeklyReportTime'] as String? ?? defaults.weeklyReportTime,
      quietHoursEnabled:
          json['quietHoursEnabled'] as bool? ?? defaults.quietHoursEnabled,
      quietHoursRange:
          json['quietHoursRange'] as String? ?? defaults.quietHoursRange,
      onboardingCompleted:
          json['onboardingCompleted'] as bool? ?? defaults.onboardingCompleted,
    );
  }
}

class UserSettingsNotifier extends StateNotifier<UserSettingsState> {
  UserSettingsNotifier(this._prefs) : super(_load(_prefs));

  static const String _storageKey = 'liftr_user_settings_v1';
  final SharedPreferences? _prefs;

  static UserSettingsState _load(SharedPreferences? prefs) {
    final raw = prefs?.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const UserSettingsState();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return UserSettingsState.fromJson(decoded);
      }
      if (decoded is Map) {
        return UserSettingsState.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return const UserSettingsState();
    }
    return const UserSettingsState();
  }

  void _persist() {
    _prefs?.setString(_storageKey, jsonEncode(state.toJson()));
  }

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
    _persist();
  }

  void setGoal(UserGoal goal) {
    state = state.copyWith(goal: goal);
    _persist();
  }

  void setExperience(UserExperience experience) {
    state = state.copyWith(experience: experience);
    _persist();
  }

  void setActivityLevel(ActivityLevel level) {
    state = state.copyWith(activityLevel: level);
    _persist();
  }

  void setSchedule({
    required int daysPerWeek,
    required String splitName,
  }) {
    state = state.copyWith(
      trainingDaysPerWeek: daysPerWeek,
      selectedSplitName: splitName,
    );
    _persist();
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
    _persist();
  }

  void setWhatsappConnected(bool connected) {
    state = state.copyWith(whatsappConnected: connected);
    _persist();
  }

  void setWeeklyReportSchedule(String day, String time) {
    state = state.copyWith(weeklyReportDay: day, weeklyReportTime: time);
    _persist();
  }

  void setQuietHoursEnabled(bool enabled) {
    state = state.copyWith(quietHoursEnabled: enabled);
    _persist();
  }

  void completeOnboarding({bool whatsappConnected = false}) {
    state = state.copyWith(
      whatsappConnected: whatsappConnected,
      onboardingCompleted: true,
    );
    _persist();
  }
}

final userSettingsProvider =
    StateNotifierProvider<UserSettingsNotifier, UserSettingsState>((ref) {
  return UserSettingsNotifier(ref.watch(sharedPreferencesProvider));
});
