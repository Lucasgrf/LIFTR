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
    this.onSuccess = const Color(0xFF151A2E),
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
    progressUp: Color(0xFF8FA8FF),
    progressDown: Color(0xFFA9B0C2),
    progressMaintain: Color(0xFFA9B0C2),
    progressNeutral: Color(0xFFA9B0C2),
    progressSteady: Color(0xFFA9B0C2),
    onSuccess: Color(0xFF151A2E),
    muscleChest: Color(0xFF8FA8FF),
    muscleBack: Color(0xFFA9B0C2),
    muscleLegs: Color(0xFFA9B0C2),
    muscleShoulders: Color(0xFFA9B0C2),
    muscleArms: Color(0xFFA9B0C2),
    muscleCore: Color(0xFFA9B0C2),
  );

  static const light = FitnessColors(
    progressUp: Color(0xFF1C3FAA),
    progressDown: Color(0xFF4F545C),
    progressMaintain: Color(0xFF4F545C),
    progressNeutral: Color(0xFF4F545C),
    progressSteady: Color(0xFF4F545C),
    onSuccess: Color(0xFFF4F5F0),
    muscleChest: Color(0xFF1C3FAA),
    muscleBack: Color(0xFF4F545C),
    muscleLegs: Color(0xFF4F545C),
    muscleShoulders: Color(0xFF4F545C),
    muscleArms: Color(0xFF4F545C),
    muscleCore: Color(0xFF4F545C),
  );

  static const defaults = dark;
}

extension FitnessColorsExtension on BuildContext {
  FitnessColors get fitnessColors =>
      Theme.of(this).extension<FitnessColors>() ?? FitnessColors.defaults;
}
