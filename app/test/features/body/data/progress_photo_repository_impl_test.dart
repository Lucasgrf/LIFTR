import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/result.dart';
import 'package:personal_fitness_os/features/body/data/datasources/progress_photo_remote_datasource.dart';
import 'package:personal_fitness_os/features/body/data/models/progress_photo_model.dart';
import 'package:personal_fitness_os/features/body/data/repositories/progress_photo_repository_impl.dart';
import 'package:personal_fitness_os/features/body/domain/entities/photo_pose.dart';

class MockProgressPhotoRemoteDataSource extends Mock implements ProgressPhotoRemoteDataSource {}

void main() {
  late MockProgressPhotoRemoteDataSource mockDataSource;
  late ProgressPhotoRepositoryImpl repository;

  final tModel = ProgressPhotoModel(
    id: 'p-1',
    userId: 'u-1',
    photoUrl: 'https://example.com/photo.jpg',
    storagePath: 'u-1/photo.jpg',
    takenAt: DateTime(2026, 8, 22),
    pose: 'front',
  );

  setUp(() {
    mockDataSource = MockProgressPhotoRemoteDataSource();
    repository = ProgressPhotoRepositoryImpl(mockDataSource);
  });

  group('ProgressPhotoRepositoryImpl', () {
    test('getPhotos should return mapped domain list', () async {
      when(() => mockDataSource.fetchPhotos(pose: any(named: 'pose'), limit: any(named: 'limit')))
          .thenAnswer((_) async => [tModel]);

      final result = await repository.getPhotos(pose: PhotoPose.front);
      expect(result.isSuccess, isTrue);
      expect((result as Success).value.length, 1);
      expect((result as Success).value.first.pose, PhotoPose.front);
    });

    test('uploadPhoto should upload and return domain entity', () async {
      when(() => mockDataSource.uploadAndInsertPhoto(
            filePath: any(named: 'filePath'),
            pose: any(named: 'pose'),
            takenAt: any(named: 'takenAt'),
            notes: any(named: 'notes'),
          )).thenAnswer((_) async => tModel);

      final result = await repository.uploadPhoto(
        filePath: '/path/to/img.jpg',
        pose: PhotoPose.front,
        takenAt: DateTime(2026, 8, 22),
      );

      expect(result.isSuccess, isTrue);
      expect((result as Success).value.id, 'p-1');
    });

    test('deletePhoto should forward to datasource', () async {
      when(() => mockDataSource.deletePhoto(id: 'p-1', storagePath: 'u-1/photo.jpg'))
          .thenAnswer((_) async {});

      final result = await repository.deletePhoto(id: 'p-1', storagePath: 'u-1/photo.jpg');
      expect(result.isSuccess, isTrue);
      verify(() => mockDataSource.deletePhoto(id: 'p-1', storagePath: 'u-1/photo.jpg')).called(1);
    });

    test('should return UnexpectedFailure on generic exception', () async {
      when(() => mockDataSource.fetchPhotos(pose: any(named: 'pose'), limit: any(named: 'limit')))
          .thenThrow(Exception('Storage timeout'));

      final result = await repository.getPhotos();
      expect(result.isError, isTrue);
      expect((result as Err).failure, isA<UnexpectedFailure>());
    });
  });
}
