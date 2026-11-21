import 'package:flutter/foundation.dart';

/// Pure Domain Entity representing a set of body circumference measurements (in cm).
@immutable
class BodyMeasurement {
  const BodyMeasurement({
    required this.id,
    this.userId,
    required this.measuredAt,
    this.waist,
    this.chest,
    this.armLeft,
    this.armRight,
    this.thighLeft,
    this.thighRight,
    this.calfLeft,
    this.calfRight,
    this.hip,
    this.shoulder,
    this.neck,
    this.forearmLeft,
    this.forearmRight,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String? userId;
  final DateTime measuredAt;
  final double? waist;
  final double? chest;
  final double? armLeft;
  final double? armRight;
  final double? thighLeft;
  final double? thighRight;
  final double? calfLeft;
  final double? calfRight;
  final double? hip;
  final double? shoulder;
  final double? neck;
  final double? forearmLeft;
  final double? forearmRight;
  final String? notes;
  final DateTime? createdAt;

  BodyMeasurement copyWith({
    String? id,
    String? userId,
    DateTime? measuredAt,
    double? waist,
    double? chest,
    double? armLeft,
    double? armRight,
    double? thighLeft,
    double? thighRight,
    double? calfLeft,
    double? calfRight,
    double? hip,
    double? shoulder,
    double? neck,
    double? forearmLeft,
    double? forearmRight,
    String? notes,
    DateTime? createdAt,
  }) {
    return BodyMeasurement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      measuredAt: measuredAt ?? this.measuredAt,
      waist: waist ?? this.waist,
      chest: chest ?? this.chest,
      armLeft: armLeft ?? this.armLeft,
      armRight: armRight ?? this.armRight,
      thighLeft: thighLeft ?? this.thighLeft,
      thighRight: thighRight ?? this.thighRight,
      calfLeft: calfLeft ?? this.calfLeft,
      calfRight: calfRight ?? this.calfRight,
      hip: hip ?? this.hip,
      shoulder: shoulder ?? this.shoulder,
      neck: neck ?? this.neck,
      forearmLeft: forearmLeft ?? this.forearmLeft,
      forearmRight: forearmRight ?? this.forearmRight,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BodyMeasurement &&
        other.id == id &&
        other.userId == userId &&
        other.measuredAt == measuredAt &&
        other.waist == waist &&
        other.chest == chest &&
        other.armLeft == armLeft &&
        other.armRight == armRight &&
        other.thighLeft == thighLeft &&
        other.thighRight == thighRight &&
        other.calfLeft == calfLeft &&
        other.calfRight == calfRight &&
        other.hip == hip &&
        other.shoulder == shoulder &&
        other.neck == neck &&
        other.forearmLeft == forearmLeft &&
        other.forearmRight == forearmRight &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        measuredAt,
        waist,
        chest,
        armLeft,
        armRight,
        thighLeft,
        thighRight,
        calfLeft,
        calfRight,
        hip,
        shoulder,
        neck,
        forearmLeft,
        forearmRight,
        notes,
      );
}
