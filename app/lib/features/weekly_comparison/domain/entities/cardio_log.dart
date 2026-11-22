import 'package:flutter/foundation.dart';

/// Standalone cardio session logged outside a strength training session.
@immutable
class CardioLog {
  const CardioLog({
    required this.id,
    required this.userId,
    required this.modality,
    required this.durationSeconds,
    required this.performedAt,
    this.notes,
    this.createdAt,
  });

  static const List<String> modalities = [
    'Esteira',
    'Bicicleta',
    'Caminhada',
    'Corrida',
    'Elíptico',
    'Escada',
    'Outro',
  ];

  final String id;
  final String userId;
  final String modality;
  final int durationSeconds;
  final DateTime performedAt;
  final String? notes;
  final DateTime? createdAt;

  int get durationMinutes => (durationSeconds / 60).round();

  CardioLog copyWith({
    String? id,
    String? userId,
    String? modality,
    int? durationSeconds,
    DateTime? performedAt,
    String? notes,
    DateTime? createdAt,
  }) {
    return CardioLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      modality: modality ?? this.modality,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      performedAt: performedAt ?? this.performedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardioLog &&
        other.id == id &&
        other.userId == userId &&
        other.modality == modality &&
        other.durationSeconds == durationSeconds &&
        other.performedAt == performedAt &&
        other.notes == notes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        modality,
        durationSeconds,
        performedAt,
        notes,
        createdAt,
      );
}
