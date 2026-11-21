import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/data/datasources/progress_photo_remote_datasource.dart';
import 'package:personal_fitness_os/features/body/data/models/progress_photo_model.dart';
import 'package:personal_fitness_os/features/body/data/repositories/progress_photo_repository_impl.dart';
import 'package:personal_fitness_os/features/body/domain/entities/photo_pose.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/delete_progress_photo.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/get_progress_photos.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/upload_progress_photo.dart';

class MockProgressPhotoRemoteDataSource extends Mock implements ProgressPhotoRemoteDataSource {}

void main() {
  late MockProgressPhotoRemoteDataSource mockDataSource;
  late ProgressPhotoRepositoryImpl repository;
  late GetProgressPhotosUseCase getProgressPhotosUseCase;
  late UploadProgressPhotoUseCase uploadProgressPhotoUseCase;
  late DeleteProgressPhotoUseCase deleteProgressPhotoUseCase;

  final tModel = ProgressPhotoModel(
    id: 'p-1',
    userId: 'u-1',
    photoUrl: 'https://example.com/photo1.jpg',
    storagePath: 'u-1/photo1.jpg',
    takenAt: DateTime(2026, 8, 22),
    pose: 'front',
  );

  setUp(() {
    mockDataSource = MockProgressPhotoRemoteDataSource();
    repository = ProgressPhotoRepositoryImpl(mockDataSource);
    getProgressPhotosUseCase = GetProgressPhotosUseCase(repository);
    uploadProgressPhotoUseCase = UploadProgressPhotoUseCase(repository);
    deleteProgressPhotoUseCase = DeleteProgressPhotoUseCase(repository);
    registerFallbackValue(PhotoPose.front);
  });

  group('Progress Photos Full Integration Flow', () {
    test('should upload, list with filters and delete photo', () async {
      // 1. Upload
      when(() => mockDataSource.uploadAndInsertPhoto(
            filePath: any(named: 'filePath'),
            pose: any(named: 'pose'),
            takenAt: any(named: 'takenAt'),
            notes: any(named: 'notes'),
          )).thenAnswer((_) async => tModel);

      final uploadResult = await uploadProgressPhotoUseCase.execute(
        filePath: '/storage/photo1.jpg',
        pose: PhotoPose.front,
        takenAt: DateTime(2026, 8, 22),
      );
      expect(uploadResult.isSuccess, isTrue);
      expect((uploadResult as Success).value.id, 'p-1');

      // 2. List with filter
      when(() => mockDataSource.fetchPhotos(pose: 'front', limit: any(named: 'limit')))
          .thenAnswer((_) async => [tModel]);

      final listResult = await getProgressPhotosUseCase.execute(pose: PhotoPose.front);
      expect(listResult.isSuccess, isTrue);
      expect((listResult as Success).value.length, 1);
      expect((listResult as Success).value.first.pose, PhotoPose.front);

      // 3. Delete
      when(() => mockDataSource.deletePhoto(
            id: 'p-1',
            storagePath: 'u-1/photo1.jpg',
          )).thenAnswer((_) async {});

      final deleteResult = await deleteProgressPhotoUseCase.execute(
        id: 'p-1',
        storagePath: 'u-1/photo1.jpg',
      );
      expect(deleteResult.isSuccess, isTrue);
      verify(() => mockDataSource.deletePhoto(id: 'p-1', storagePath: 'u-1/photo1.jpg')).called(1);
    });
  });
}
