import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/photo_pose.dart';
import 'package:personal_fitness_os/features/body/domain/entities/progress_photo.dart';

abstract class ProgressPhotoRepository {
  Future<Result<List<ProgressPhoto>, Failure>> getPhotos({
    PhotoPose? pose,
    int limit = 50,
  });

  Future<Result<ProgressPhoto, Failure>> uploadPhoto({
    required String filePath,
    required PhotoPose pose,
    required DateTime takenAt,
    String? notes,
  });

  Future<Result<void, Failure>> deletePhoto({
    required String id,
    required String storagePath,
  });
}
