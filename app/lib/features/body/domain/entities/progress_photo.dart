import 'package:flutter/foundation.dart';
import 'package:personal_fitness_os/features/body/domain/entities/photo_pose.dart';

/// Pure Domain Entity representing a physical progress photo.
@immutable
class ProgressPhoto {
  const ProgressPhoto({
    required this.id,
    this.userId,
    required this.photoUrl,
    required this.storagePath,
    required this.takenAt,
    this.pose = PhotoPose.other,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String? userId;
  final String photoUrl;
  final String storagePath;
  final DateTime takenAt;
  final PhotoPose pose;
  final String? notes;
  final DateTime? createdAt;

  ProgressPhoto copyWith({
    String? id,
    String? userId,
    String? photoUrl,
    String? storagePath,
    DateTime? takenAt,
    PhotoPose? pose,
    String? notes,
    DateTime? createdAt,
  }) {
    return ProgressPhoto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      photoUrl: photoUrl ?? this.photoUrl,
      storagePath: storagePath ?? this.storagePath,
      takenAt: takenAt ?? this.takenAt,
      pose: pose ?? this.pose,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgressPhoto &&
        other.id == id &&
        other.userId == userId &&
        other.photoUrl == photoUrl &&
        other.storagePath == storagePath &&
        other.takenAt == takenAt &&
        other.pose == pose &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        photoUrl,
        storagePath,
        takenAt,
        pose,
        notes,
      );
}
