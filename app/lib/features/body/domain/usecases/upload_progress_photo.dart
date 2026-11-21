import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/photo_pose.dart';
import 'package:personal_fitness_os/features/body/domain/entities/progress_photo.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/progress_photo_repository.dart';

class UploadProgressPhotoUseCase {
  const UploadProgressPhotoUseCase(this._repository);

  final ProgressPhotoRepository _repository;

  Future<Result<ProgressPhoto, Failure>> execute({
    required String filePath,
    required PhotoPose pose,
    required DateTime takenAt,
    String? notes,
  }) {
    if (filePath.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Caminho do arquivo de foto inválido.')),
      );
    }

    return _repository.uploadPhoto(
      filePath: filePath,
      pose: pose,
      takenAt: takenAt,
      notes: notes,
    );
  }
}
