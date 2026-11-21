import 'dart:io';
import 'package:personal_fitness_os/features/body/data/models/progress_photo_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract class ProgressPhotoRemoteDataSource {
  Future<List<ProgressPhotoModel>> fetchPhotos({String? pose, int limit = 50});
  Future<ProgressPhotoModel> uploadAndInsertPhoto({
    required String filePath,
    required String pose,
    required DateTime takenAt,
    String? notes,
  });
  Future<void> deletePhoto({
    required String id,
    required String storagePath,
  });
}

class SupabaseProgressPhotoRemoteDataSource implements ProgressPhotoRemoteDataSource {
  const SupabaseProgressPhotoRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ProgressPhotoModel>> fetchPhotos({String? pose, int limit = 50}) async {
    var query = _client.from('progress_photos').select();
    if (pose != null) {
      query = query.eq('pose', pose);
    }

    final response = await query.order('taken_at', ascending: false).limit(limit);

    return (response as List)
        .map((json) => ProgressPhotoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProgressPhotoModel> uploadAndInsertPhoto({
    required String filePath,
    required String pose,
    required DateTime takenAt,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id ?? 'anonymous';
    final fileExt = filePath.split('.').last;
    final fileName = '${const Uuid().v4()}.$fileExt';
    final storagePath = '$userId/$fileName';

    // 1. Upload to Supabase Storage Bucket 'progress-photos'
    final file = File(filePath);
    await _client.storage.from('progress-photos').upload(storagePath, file);

    // 2. Get Public or Signed URL
    final photoUrl = _client.storage.from('progress-photos').getPublicUrl(storagePath);

    // 3. Insert record into database
    final record = {
      'user_id': userId,
      'photo_url': photoUrl,
      'storage_path': storagePath,
      'taken_at': takenAt.toIso8601String(),
      'pose': pose,
      if (notes != null) 'notes': notes,
    };

    final response = await _client
        .from('progress_photos')
        .insert(record)
        .select()
        .single();

    return ProgressPhotoModel.fromJson(response);
  }

  @override
  Future<void> deletePhoto({
    required String id,
    required String storagePath,
  }) async {
    // 1. Remove from database
    await _client.from('progress_photos').delete().eq('id', id);

    // 2. Remove from storage
    try {
      await _client.storage.from('progress-photos').remove([storagePath]);
    } catch (_) {
      // Best effort deletion from storage bucket
    }
  }
}
