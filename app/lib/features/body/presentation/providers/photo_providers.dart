import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/features/body/data/datasources/progress_photo_remote_datasource.dart';
import 'package:personal_fitness_os/features/body/data/repositories/progress_photo_repository_impl.dart';
import 'package:personal_fitness_os/features/body/domain/entities/photo_pose.dart';
import 'package:personal_fitness_os/features/body/domain/entities/progress_photo.dart';
import 'package:personal_fitness_os/features/body/domain/repositories/progress_photo_repository.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/delete_progress_photo.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/get_progress_photos.dart';
import 'package:personal_fitness_os/features/body/domain/usecases/upload_progress_photo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Data Sources & Repositories ---

final progressPhotoRemoteDataSourceProvider = Provider<ProgressPhotoRemoteDataSource>((ref) {
  return SupabaseProgressPhotoRemoteDataSource(Supabase.instance.client);
});

final progressPhotoRepositoryProvider = Provider<ProgressPhotoRepository>((ref) {
  return ProgressPhotoRepositoryImpl(ref.watch(progressPhotoRemoteDataSourceProvider));
});

// --- Use Cases ---

final getProgressPhotosUseCaseProvider = Provider<GetProgressPhotosUseCase>((ref) {
  return GetProgressPhotosUseCase(ref.watch(progressPhotoRepositoryProvider));
});

final uploadProgressPhotoUseCaseProvider = Provider<UploadProgressPhotoUseCase>((ref) {
  return UploadProgressPhotoUseCase(ref.watch(progressPhotoRepositoryProvider));
});

final deleteProgressPhotoUseCaseProvider = Provider<DeleteProgressPhotoUseCase>((ref) {
  return DeleteProgressPhotoUseCase(ref.watch(progressPhotoRepositoryProvider));
});

// --- UI State & Data Providers ---

final selectedPhotoPoseFilterProvider = StateProvider<PhotoPose?>((ref) => null);

final progressPhotosProvider = FutureProvider.autoDispose<List<ProgressPhoto>>((ref) async {
  final useCase = ref.watch(getProgressPhotosUseCaseProvider);
  final poseFilter = ref.watch(selectedPhotoPoseFilterProvider);

  final result = await useCase.execute(pose: poseFilter);

  return result.fold(
    (photos) => photos,
    (failure) => throw Exception(failure.message),
  );
});
