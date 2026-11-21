import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/progress_photo_repository.dart';

class DeleteProgressPhotoUseCase {
  const DeleteProgressPhotoUseCase(this._repository);

  final ProgressPhotoRepository _repository;

  Future<Result<void, Failure>> execute({
    required String id,
    required String storagePath,
  }) {
    if (id.trim().isEmpty || storagePath.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('ID ou caminho da foto inválido.')),
      );
    }

    return _repository.deletePhoto(
      id: id,
      storagePath: storagePath,
    );
  }
}
