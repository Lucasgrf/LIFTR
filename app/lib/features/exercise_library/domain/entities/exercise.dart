import 'package:flutter/foundation.dart';

/// Pure Domain Entity representing a physical exercise.
@immutable
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscleGroup,
    this.userId,
    this.secondaryMuscles = const [],
    this.equipment,
    this.movementPattern,
    this.instructions,
    this.commonMistakes,
    this.videoUrl,
    this.personalNotes,
    this.isCustom = false,
    this.createdAt,
    this.deletedAt,
  });

  final String id;
  final String? userId;
  final String name;
  final String primaryMuscleGroup;
  final List<String> secondaryMuscles;
  final String? equipment;
  final String? movementPattern;
  final String? instructions;
  final String? commonMistakes;
  final String? videoUrl;
  final String? personalNotes;
  final bool isCustom;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  bool get isGlobal => userId == null && !isCustom;

  /// Identifies cardio exercises tracked by duration rather than weight/reps.
  bool get isCardio {
    final pattern = movementPattern?.toLowerCase().trim() ?? '';
    final muscle = primaryMuscleGroup.toLowerCase().trim();
    final lowerName = name.toLowerCase().trim();
    return pattern == 'cardio' ||
        muscle == 'cardio' ||
        lowerName == 'cardio' ||
        lowerName.contains('esteira') ||
        lowerName.contains('bicicleta') ||
        lowerName.contains('ergométrica') ||
        lowerName.contains('ergometrica') ||
        lowerName.contains('elíptico') ||
        lowerName.contains('eliptico') ||
        lowerName.contains('escada') ||
        lowerName.contains('corrida') ||
        lowerName.contains('caminhada');
  }

  Exercise copyWith({
    String? id,
    String? userId,
    String? name,
    String? primaryMuscleGroup,
    List<String>? secondaryMuscles,
    String? equipment,
    String? movementPattern,
    String? instructions,
    String? commonMistakes,
    String? videoUrl,
    String? personalNotes,
    bool? isCustom,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      primaryMuscleGroup: primaryMuscleGroup ?? this.primaryMuscleGroup,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      movementPattern: movementPattern ?? this.movementPattern,
      instructions: instructions ?? this.instructions,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      videoUrl: videoUrl ?? this.videoUrl,
      personalNotes: personalNotes ?? this.personalNotes,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.primaryMuscleGroup == primaryMuscleGroup &&
        listEquals(other.secondaryMuscles, secondaryMuscles) &&
        other.equipment == equipment &&
        other.movementPattern == movementPattern &&
        other.instructions == instructions &&
        other.commonMistakes == commonMistakes &&
        other.videoUrl == videoUrl &&
        other.personalNotes == personalNotes &&
        other.isCustom == isCustom &&
        other.createdAt == createdAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        name,
        primaryMuscleGroup,
        Object.hashAll(secondaryMuscles),
        equipment,
        movementPattern,
        instructions,
        commonMistakes,
        videoUrl,
        personalNotes,
        isCustom,
        createdAt,
        deletedAt,
      );

  @override
  String toString() => 'Exercise(id: $id, name: $name, primaryMuscle: $primaryMuscleGroup, isCustom: $isCustom)';
}
