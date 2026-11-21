import 'package:personal_fitness_os/features/body/domain/entities/body_measurement.dart';

class BodyMeasurementModel {
  const BodyMeasurementModel({
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

  factory BodyMeasurementModel.fromJson(Map<String, dynamic> json) {
    return BodyMeasurementModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      measuredAt: DateTime.parse(json['measured_at'] as String),
      waist: (json['waist'] as num?)?.toDouble(),
      chest: (json['chest'] as num?)?.toDouble(),
      armLeft: (json['arm_left'] as num?)?.toDouble(),
      armRight: (json['arm_right'] as num?)?.toDouble(),
      thighLeft: (json['thigh_left'] as num?)?.toDouble(),
      thighRight: (json['thigh_right'] as num?)?.toDouble(),
      calfLeft: (json['calf_left'] as num?)?.toDouble(),
      calfRight: (json['calf_right'] as num?)?.toDouble(),
      hip: (json['hip'] as num?)?.toDouble(),
      shoulder: (json['shoulder'] as num?)?.toDouble(),
      neck: (json['neck'] as num?)?.toDouble(),
      forearmLeft: (json['forearm_left'] as num?)?.toDouble(),
      forearmRight: (json['forearm_right'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'measured_at': measuredAt.toIso8601String(),
      if (waist != null) 'waist': waist,
      if (chest != null) 'chest': chest,
      if (armLeft != null) 'arm_left': armLeft,
      if (armRight != null) 'arm_right': armRight,
      if (thighLeft != null) 'thigh_left': thighLeft,
      if (thighRight != null) 'thigh_right': thighRight,
      if (calfLeft != null) 'calf_left': calfLeft,
      if (calfRight != null) 'calf_right': calfRight,
      if (hip != null) 'hip': hip,
      if (shoulder != null) 'shoulder': shoulder,
      if (neck != null) 'neck': neck,
      if (forearmLeft != null) 'forearm_left': forearmLeft,
      if (forearmRight != null) 'forearm_right': forearmRight,
      if (notes != null) 'notes': notes,
    };
  }

  BodyMeasurement toDomain() {
    return BodyMeasurement(
      id: id,
      userId: userId,
      measuredAt: measuredAt,
      waist: waist,
      chest: chest,
      armLeft: armLeft,
      armRight: armRight,
      thighLeft: thighLeft,
      thighRight: thighRight,
      calfLeft: calfLeft,
      calfRight: calfRight,
      hip: hip,
      shoulder: shoulder,
      neck: neck,
      forearmLeft: forearmLeft,
      forearmRight: forearmRight,
      notes: notes,
      createdAt: createdAt,
    );
  }

  factory BodyMeasurementModel.fromDomain(BodyMeasurement domain) {
    return BodyMeasurementModel(
      id: domain.id,
      userId: domain.userId,
      measuredAt: domain.measuredAt,
      waist: domain.waist,
      chest: domain.chest,
      armLeft: domain.armLeft,
      armRight: domain.armRight,
      thighLeft: domain.thighLeft,
      thighRight: domain.thighRight,
      calfLeft: domain.calfLeft,
      calfRight: domain.calfRight,
      hip: domain.hip,
      shoulder: domain.shoulder,
      neck: domain.neck,
      forearmLeft: domain.forearmLeft,
      forearmRight: domain.forearmRight,
      notes: domain.notes,
      createdAt: domain.createdAt,
    );
  }
}
