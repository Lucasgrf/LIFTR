import 'package:personal_fitness_os/features/body/domain/entities/photo_pose.dart';
import 'package:personal_fitness_os/features/body/domain/entities/progress_photo.dart';

class ProgressPhotoModel {
  const ProgressPhotoModel({
    required this.id,
    this.userId,
    required this.photoUrl,
    required this.storagePath,
    required this.takenAt,
    this.pose = 'other',
    this.notes,
    this.createdAt,
  });

  final String id;
  final String? userId;
  final String photoUrl;
  final String storagePath;
  final DateTime takenAt;
  final String pose;
  final String? notes;
  final DateTime? createdAt;

  factory ProgressPhotoModel.fromJson(Map<String, dynamic> json) {
    return ProgressPhotoModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      photoUrl: json['photo_url'] as String,
      storagePath: json['storage_path'] as String,
      takenAt: DateTime.parse(json['taken_at'] as String),
      pose: json['pose'] as String? ?? 'other',
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
      'photo_url': photoUrl,
      'storage_path': storagePath,
      'taken_at': takenAt.toIso8601String(),
      'pose': pose,
      if (notes != null) 'notes': notes,
    };
  }

  ProgressPhoto toDomain() {
    return ProgressPhoto(
      id: id,
      userId: userId,
      photoUrl: photoUrl,
      storagePath: storagePath,
      takenAt: takenAt,
      pose: PhotoPose.fromCode(pose),
      notes: notes,
      createdAt: createdAt,
    );
  }

  factory ProgressPhotoModel.fromDomain(ProgressPhoto domain) {
    return ProgressPhotoModel(
      id: domain.id,
      userId: domain.userId,
      photoUrl: domain.photoUrl,
      storagePath: domain.storagePath,
      takenAt: domain.takenAt,
      pose: domain.pose.code,
      notes: domain.notes,
      createdAt: domain.createdAt,
    );
  }
}
