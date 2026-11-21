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
    this.progressSteady = const Color(0xFF8B8B99),
    this.progressStalled = const Color(0xFFF59E0B),
    this.warmupTag = const Color(0xFF38BDF8),
    this.timerActive = const Color(0xFF6C63FF),
    this.onSuccess = const Color(0xFF08120C),
  });

  final Color progressUp;
  final Color progressDown;
  final Color progressMaintain;
  final Color progressNeutral;
  final Color progressSteady;
  final Color progressStalled;
  final Color warmupTag;
  final Color timerActive;
  final Color onSuccess;

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
    Color? progressSteady,
    Color? progressStalled,
    Color? warmupTag,
    Color? timerActive,
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
      progressStalled: progressStalled ?? this.progressStalled,
      warmupTag: warmupTag ?? this.warmupTag,
      timerActive: timerActive ?? this.timerActive,
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
      progressStalled:
          Color.lerp(progressStalled, other.progressStalled, t) ??
          progressStalled,
      warmupTag: Color.lerp(warmupTag, other.warmupTag, t) ?? warmupTag,
      timerActive: Color.lerp(timerActive, other.timerActive, t) ?? timerActive,
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

  static const defaults = FitnessColors(
    progressUp: Color(0xFF22C55E),
    progressDown: Color(0xFFFF4D5E),
    progressMaintain: Color(0xFFF59E0B),
    progressNeutral: Color(0xFF38BDF8),
    progressSteady: Color(0xFF8B8B99),
    progressStalled: Color(0xFFF59E0B),
    warmupTag: Color(0xFF38BDF8),
    timerActive: Color(0xFF6C63FF),
    onSuccess: Color(0xFF08120C),
    muscleChest: Color(0xFFF43F5E),
    muscleBack: Color(0xFF3B82F6),
    muscleLegs: Color(0xFF10B981),
    muscleShoulders: Color(0xFFF59E0B),
    muscleArms: Color(0xFFA855F7),
    muscleCore: Color(0xFF14B8A6),
  );
}

extension FitnessColorsExtension on BuildContext {
  FitnessColors get fitnessColors =>
      Theme.of(this).extension<FitnessColors>() ?? FitnessColors.defaults;
}
