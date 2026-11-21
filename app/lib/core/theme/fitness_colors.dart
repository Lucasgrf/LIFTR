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
  });

  final Color progressUp;
  final Color progressDown;
  final Color progressMaintain;
  final Color progressNeutral;
  
  final Color muscleChest;
  final Color muscleBack;
  final Color muscleLegs;
  final Color muscleShoulders;
  final Color muscleArms;
  final Color muscleCore;

  @override
  FitnessColors copyWith({
    Color? progressUp,
    Color? progressDown,
    Color? progressMaintain,
    Color? progressNeutral,
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
      progressDown: Color.lerp(progressDown, other.progressDown, t) ?? progressDown,
      progressMaintain: Color.lerp(progressMaintain, other.progressMaintain, t) ?? progressMaintain,
      progressNeutral: Color.lerp(progressNeutral, other.progressNeutral, t) ?? progressNeutral,
      muscleChest: Color.lerp(muscleChest, other.muscleChest, t) ?? muscleChest,
      muscleBack: Color.lerp(muscleBack, other.muscleBack, t) ?? muscleBack,
      muscleLegs: Color.lerp(muscleLegs, other.muscleLegs, t) ?? muscleLegs,
      muscleShoulders: Color.lerp(muscleShoulders, other.muscleShoulders, t) ?? muscleShoulders,
      muscleArms: Color.lerp(muscleArms, other.muscleArms, t) ?? muscleArms,
      muscleCore: Color.lerp(muscleCore, other.muscleCore, t) ?? muscleCore,
    );
  }

  static const defaults = FitnessColors(
    progressUp: Color(0xFF00E676),
    progressDown: Color(0xFFFF5252),
    progressMaintain: Color(0xFFFFD740),
    progressNeutral: Color(0xFF40C4FF),
    muscleChest: Color(0xFFFF7043),
    muscleBack: Color(0xFF42A5F5),
    muscleLegs: Color(0xFF66BB6A),
    muscleShoulders: Color(0xFFAB47BC),
    muscleArms: Color(0xFFFFA726),
    muscleCore: Color(0xFFEC407A),
  );
}

extension FitnessColorsExtension on BuildContext {
  FitnessColors get fitnessColors => Theme.of(this).extension<FitnessColors>() ?? FitnessColors.defaults;
}
