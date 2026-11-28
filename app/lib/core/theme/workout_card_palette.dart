import 'package:flutter/material.dart';

/// Ficha colors from the LIFTR identity system. A key keeps a workout's card
/// color stable when queue order changes without adding presentation data to
/// the workout entity.
abstract final class WorkoutCardPalette {
  static const ink = Color(0xFF17191E);
  static const secondaryInk = Color(0xFF3D4148);
  static const penInk = Color(0xFF1C3FAA);

  static const colors = <Color>[
    Color(0xFFF3D55B),
    Color(0xFFCDB9E8),
    Color(0xFFA8C7EF),
    Color(0xFF9ED9C9),
    Color(0xFFF5A992),
  ];

  static Color forKey(String key) {
    if (key.isEmpty) return colors.first;
    final stableIndex = key.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return colors[stableIndex % colors.length];
  }

  /// Uses the stable program order so a ficha keeps its color when the queue
  /// rotates or is rearranged.
  static Color forIndex(int index) => colors[index.abs() % colors.length];

  static Color forWorkout(String name) {
    final canonical = name.trim().toLowerCase();
    final index = switch (canonical) {
      'lower b' => 0,
      'especialização' => 1,
      'upper a' => 2,
      'lower a' => 3,
      'upper b' => 4,
      _ => null,
    };
    return index == null ? forKey(name) : colors[index];
  }
}
