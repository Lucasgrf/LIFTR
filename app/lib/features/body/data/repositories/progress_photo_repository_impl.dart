import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/data/datasources/progress_photo_remote_datasource.dart';
import 'package:personal_fitness_os/features/body/domain/entities/photo_pose.dart';
import 'package:personal_fitness_os/features/body/domain/entities/progress_photo.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/progress_photo_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressPhotoRepositoryImpl implements ProgressPhotoRepository {
  const ProgressPhotoRepositoryImpl(this._remoteDataSource);

  final ProgressPhotoRemoteDataSource _remoteDataSource;

  Future<Result<T, Failure>> _guard<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      return Success(result);
    } on AuthException catch (e, st) {
      return Err(AuthFailure(e.message, st));
    } on StorageException catch (e, st) {
      return Err(ServerFailure(e.message, st));
    } on PostgrestException catch (e, st) {
      return Err(ServerFailure(e.message, st));
    } catch (e, st) {
      return Err(UnexpectedFailure(e.toString(), st));
    }
  }

  @override
  Future<Result<List<ProgressPhoto>, Failure>> getPhotos({
    PhotoPose? pose,
    int limit = 50,
  }) {
    return _guard(() async {
      final models = await _remoteDataSource.fetchPhotos(
        pose: pose?.code,
        limit: limit,
      );
      return models.map((m) => m.toDomain()).toList();
    });
  }

  @override
  Future<Result<ProgressPhoto, Failure>> uploadPhoto({
    required String filePath,
    required PhotoPose pose,
    required DateTime takenAt,
    String? notes,
  }) {
    return _guard(() async {
      final model = await _remoteDataSource.uploadAndInsertPhoto(
        filePath: filePath,
        pose: pose.code,
        takenAt: takenAt,
        notes: notes,
      );
      return model.toDomain();
    });
  }

  @override
  Future<Result<void, Failure>> deletePhoto({
    required String id,
    required String storagePath,
  }) {
    return _guard(() async {
      await _remoteDataSource.deletePhoto(
        id: id,
        storagePath: storagePath,
      );
    });
  }
}
