import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/domain/entities/photo_pose.dart';
import 'package:personal_fitness_os/features/body/domain/entities/progress_photo.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/progress_photo_repository.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/delete_progress_photo.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/get_progress_photos.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/upload_progress_photo.dart';

class MockProgressPhotoRepository extends Mock implements ProgressPhotoRepository {}

void main() {
  late MockProgressPhotoRepository mockRepo;

  final tPhoto = ProgressPhoto(
    id: 'p-1',
    userId: 'u-1',
    photoUrl: 'https://example.com/photo1.jpg',
    storagePath: 'u-1/photo1.jpg',
    takenAt: DateTime(2026, 8, 22),
    pose: PhotoPose.front,
  );

  setUp(() {
    mockRepo = MockProgressPhotoRepository();
    registerFallbackValue(PhotoPose.front);
  });

  group('GetProgressPhotosUseCase', () {
    test('should return photos list from repository', () async {
      when(() => mockRepo.getPhotos(pose: any(named: 'pose'), limit: any(named: 'limit')))
          .thenAnswer((_) async => Success([tPhoto]));

      final useCase = GetProgressPhotosUseCase(mockRepo);
      final result = await useCase.execute(pose: PhotoPose.front);

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.length, 1);
    });

    test('should return ValidationFailure when limit <= 0', () async {
      final useCase = GetProgressPhotosUseCase(mockRepo);
      final result = await useCase.execute(limit: 0);

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });
  });

  group('UploadProgressPhotoUseCase', () {
    test('should upload photo when path is valid', () async {
      when(() => mockRepo.uploadPhoto(
            filePath: any(named: 'filePath'),
            pose: any(named: 'pose'),
            takenAt: any(named: 'takenAt'),
            notes: any(named: 'notes'),
          )).thenAnswer((_) async => Success(tPhoto));

      final useCase = UploadProgressPhotoUseCase(mockRepo);
      final result = await useCase.execute(
        filePath: '/tmp/test.jpg',
        pose: PhotoPose.front,
        takenAt: DateTime(2026, 8, 22),
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.id, 'p-1');
    });

    test('should return ValidationFailure when filePath is empty', () async {
      final useCase = UploadProgressPhotoUseCase(mockRepo);
      final result = await useCase.execute(
        filePath: '',
        pose: PhotoPose.front,
        takenAt: DateTime.now(),
      );

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });
  });

  group('DeleteProgressPhotoUseCase', () {
    test('should delete photo from repository', () async {
      when(() => mockRepo.deletePhoto(id: 'p-1', storagePath: 'u-1/photo1.jpg'))
          .thenAnswer((_) async => const Success(null));

      final useCase = DeleteProgressPhotoUseCase(mockRepo);
      final result = await useCase.execute(id: 'p-1', storagePath: 'u-1/photo1.jpg');

      expect(result.isSuccess, isTrue);
    });

    test('should return ValidationFailure when parameters are empty', () async {
      final useCase = DeleteProgressPhotoUseCase(mockRepo);
      final result = await useCase.execute(id: '', storagePath: '');

      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<ValidationFailure>());
    });
  });
}
