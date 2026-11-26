import 'package:flutter/material.dart';

class FitnessColors extends ThemeExtension<FitnessColors> {
  const FitnessColors({
    required this.progressUp,
    required this.progressDown,
    required this.progressMaintain,
    required this.progressNeutral,
    required this.muscleChest,
    required this.muscleBack,
    required this.muscleLegs,
    required this.muscleShoulders,
    required this.muscleArms,
    required this.muscleCore,
    this.progressSteady = const Color(0xFF9898A3),
    this.onSuccess = const Color(0xFF0D0D0F),
  });

  final Color progressUp;
  final Color progressDown;
  final Color progressMaintain;
  final Color progressNeutral;
  final Color progressSteady;
  final Color onSuccess;

  final Color muscleChest;
  final Color muscleBack;
  final Color muscleLegs;
  final Color muscleShoulders;
  final Color muscleArms;
  final Color muscleCore;

  /// Alias pointing to [progressMaintain].
  Color get progressStalled => progressMaintain;

  /// Alias pointing to [progressNeutral].
  Color get warmupTag => progressNeutral;

  /// Alias pointing to [progressDown].
  Color get dropSetTag => progressDown;

  /// Alias pointing to [progressUp].
  Color get timerActive => progressUp;

  @override
  FitnessColors copyWith({
    Color? progressUp,
    Color? progressDown,
    Color? progressMaintain,
    Color? progressNeutral,
    Color? progressSteady,
    Color? onSuccess,
    Color? muscleChest,
    Color? muscleBack,
    Color? muscleLegs,
    Color? muscleShoulders,
    Color? muscleArms,
    Color? muscleCore,
  }) {
    return FitnessColors(
      progressUp: progressUp ?? this.progressUp,
      progressDown: progressDown ?? this.progressDown,
      progressMaintain: progressMaintain ?? this.progressMaintain,
      progressNeutral: progressNeutral ?? this.progressNeutral,
      progressSteady: progressSteady ?? this.progressSteady,
      onSuccess: onSuccess ?? this.onSuccess,
      muscleChest: muscleChest ?? this.muscleChest,
      muscleBack: muscleBack ?? this.muscleBack,
      muscleLegs: muscleLegs ?? this.muscleLegs,
      muscleShoulders: muscleShoulders ?? this.muscleShoulders,
      muscleArms: muscleArms ?? this.muscleArms,
      muscleCore: muscleCore ?? this.muscleCore,
    );
  }

  @override
  FitnessColors lerp(ThemeExtension<FitnessColors>? other, double t) {
    if (other is! FitnessColors) return this;
    return FitnessColors(
      progressUp: Color.lerp(progressUp, other.progressUp, t) ?? progressUp,
      progressDown:
          Color.lerp(progressDown, other.progressDown, t) ?? progressDown,
      progressMaintain:
          Color.lerp(progressMaintain, other.progressMaintain, t) ??
          progressMaintain,
      progressNeutral:
          Color.lerp(progressNeutral, other.progressNeutral, t) ??
          progressNeutral,
      progressSteady:
          Color.lerp(progressSteady, other.progressSteady, t) ?? progressSteady,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t) ?? onSuccess,
      muscleChest: Color.lerp(muscleChest, other.muscleChest, t) ?? muscleChest,
      muscleBack: Color.lerp(muscleBack, other.muscleBack, t) ?? muscleBack,
      muscleLegs: Color.lerp(muscleLegs, other.muscleLegs, t) ?? muscleLegs,
      muscleShoulders:
          Color.lerp(muscleShoulders, other.muscleShoulders, t) ??
          muscleShoulders,
      muscleArms: Color.lerp(muscleArms, other.muscleArms, t) ?? muscleArms,
      muscleCore: Color.lerp(muscleCore, other.muscleCore, t) ?? muscleCore,
    );
  }

  static const dark = FitnessColors(
    progressUp: Color(0xFF72A987),
    progressDown: Color(0xFFC98A5B),
    progressMaintain: Color(0xFFD4A154),
    progressNeutral: Color(0xFF6E9EC7),
    progressSteady: Color(0xFF9898A3),
    onSuccess: Color(0xFF0D0D0F),
    muscleChest: Color(0xFF72A987),
    muscleBack: Color(0xFF9898A3),
    muscleLegs: Color(0xFF7C9286),
    muscleShoulders: Color(0xFF9A9AA6),
    muscleArms: Color(0xFF6E8C7D),
    muscleCore: Color(0xFF7D8590),
  );

  static const light = FitnessColors(
    progressUp: Color(0xFF315B43),
    progressDown: Color(0xFF9A5528),
    progressMaintain: Color(0xFF805500),
    progressNeutral: Color(0xFF2B5E8A),
    progressSteady: Color(0xFF52525B),
    onSuccess: Color(0xFFF2F2F0),
    muscleChest: Color(0xFF315B43),
    muscleBack: Color(0xFF52525B),
    muscleLegs: Color(0xFF476354),
    muscleShoulders: Color(0xFF5E5E68),
    muscleArms: Color(0xFF3F5E4D),
    muscleCore: Color(0xFF525C68),
  );

  static const defaults = dark;
}

extension FitnessColorsExtension on BuildContext {
  FitnessColors get fitnessColors =>
      Theme.of(this).extension<FitnessColors>() ?? FitnessColors.defaults;
}
