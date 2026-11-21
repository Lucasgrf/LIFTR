import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/photo_pose.dart';
import 'package:personal_fitness_os/features/body/domain/entities/progress_photo.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/progress_photo_repository.dart';

class GetProgressPhotosUseCase {
  const GetProgressPhotosUseCase(this._repository);

  final ProgressPhotoRepository _repository;

  Future<Result<List<ProgressPhoto>, Failure>> execute({
    PhotoPose? pose,
    int limit = 50,
  }) {
    if (limit <= 0) {
      return Future.value(
        const Err(ValidationFailure('Limite deve ser maior que zero.')),
      );
    }
    return _repository.getPhotos(pose: pose, limit: limit);
  }
}
