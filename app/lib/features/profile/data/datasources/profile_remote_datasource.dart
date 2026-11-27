import 'dart:io';

import 'package:personal_fitness_os/core/constants/supabase_config.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileData {
  const UserProfileData({
    this.displayName,
    this.email,
    this.avatarUrl,
    this.avatarStoragePath,
    this.biologicalSex,
    this.age,
    this.heightCm,
    this.weightKg,
    this.bodyFatPercent,
    this.goal,
    this.experience,
    this.activityLevel,
  });

  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final String? avatarStoragePath;
  final String? biologicalSex;
  final int? age;
  final int? heightCm;
  final double? weightKg;
  final double? bodyFatPercent;
  final String? goal;
  final String? experience;
  final String? activityLevel;
}

abstract class ProfileRemoteDataSource {
  Future<UserProfileData?> fetchProfile();
  Future<({String avatarUrl, String storagePath})> uploadAvatar(
    String filePath, {
    String? previousStoragePath,
  });
  Future<void> removeAvatar(String? storagePath);
  Future<void> saveProfile({
    String? displayName,
    String? biologicalSex,
    int? age,
    int? heightCm,
    double? weightKg,
    double? bodyFatPercent,
    String? goal,
    String? experience,
    String? activityLevel,
  });
}

class SupabaseProfileRemoteDataSource implements ProfileRemoteDataSource {
  const SupabaseProfileRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const String _bucket = 'avatars';

  String _contentTypeForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  Future<String> _resolveAvatarUrl(
    String storagePath, {
    required String fallbackUrl,
  }) async {
    if (storagePath.isEmpty) return fallbackUrl;
    try {
      return await _client.storage
          .from(_bucket)
          .createSignedUrl(storagePath, 60 * 60 * 24 * 7);
    } catch (_) {
      final publicUrl = _client.storage.from(_bucket).getPublicUrl(storagePath);
      return fallbackUrl.isNotEmpty ? fallbackUrl : publicUrl;
    }
  }

  /// Reads avatar metadata exclusively from `auth.userMetadata` so a failed
  /// mirror write on `user_profiles` never resurrects a removed profile photo.
  static ({String? avatarUrl, String? storagePath}) resolveAvatarMetadata(
    Map<String, dynamic> authMetadata,
  ) {
    String? nonEmpty(dynamic raw) {
      if (raw is! String) return null;
      final trimmed = raw.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return (
      avatarUrl: nonEmpty(authMetadata['avatar_url']),
      storagePath: nonEmpty(authMetadata['avatar_storage_path']),
    );
  }

  @override
  Future<UserProfileData?> fetchProfile() async {
    if (!SupabaseConfig.isConfigured) return null;
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final meta = user.userMetadata ?? const <String, dynamic>{};
    Map<String, dynamic>? row;
    try {
      row = await _client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (_) {
      row = null;
    }

    final resolvedAvatar = resolveAvatarMetadata(meta);
    final storagePath = resolvedAvatar.storagePath;
    var avatarUrl = resolvedAvatar.avatarUrl;

    if (storagePath != null && storagePath.isNotEmpty) {
      avatarUrl = await _resolveAvatarUrl(
        storagePath,
        fallbackUrl: avatarUrl ?? '',
      );
    }

    return UserProfileData(
      displayName: (row?['display_name'] as String?) ??
          (meta['displayName'] as String?) ??
          (meta['name'] as String?) ??
          (meta['full_name'] as String?),
      email: user.email,
      avatarUrl: avatarUrl,
      avatarStoragePath: storagePath,
      biologicalSex: (row?['biological_sex'] as String?) ??
          (meta['biologicalSex'] as String?),
      age: (row?['age'] as num?)?.toInt() ?? (meta['age'] as num?)?.toInt(),
      heightCm: (row?['height_cm'] as num?)?.toInt() ??
          (meta['heightCm'] as num?)?.toInt(),
      weightKg: (row?['weight_kg'] as num?)?.toDouble() ??
          (meta['weightKg'] as num?)?.toDouble(),
      bodyFatPercent: (row?['body_fat_percent'] as num?)?.toDouble() ??
          (meta['bodyFatPercent'] as num?)?.toDouble(),
      goal: (row?['goal'] as String?) ?? (meta['goal'] as String?),
      experience: (row?['experience'] as String?) ??
          (meta['experience'] as String?),
      activityLevel: (row?['activity_level'] as String?) ??
          (meta['activityLevel'] as String?),
    );
  }

  @override
  Future<({String avatarUrl, String storagePath})> uploadAvatar(
    String filePath, {
    String? previousStoragePath,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    final parts = filePath.split('.');
    final rawExt = parts.length > 1 ? parts.last.toLowerCase() : 'jpg';
    final ext = rawExt.isEmpty || rawExt.length > 5 ? 'jpg' : rawExt;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '${user.id}/avatar_$timestamp.$ext';
    final file = File(filePath);

    await _client.storage.from(_bucket).upload(
          storagePath,
          file,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeForExtension(ext),
          ),
        );

    if (previousStoragePath != null &&
        previousStoragePath.isNotEmpty &&
        previousStoragePath != storagePath) {
      try {
        await _client.storage.from(_bucket).remove([previousStoragePath]);
      } catch (_) {}
    }

    final publicBase = _client.storage.from(_bucket).getPublicUrl(storagePath);
    final versionedPublic = '$publicBase?v=$timestamp';
    final resolvedUrl = await _resolveAvatarUrl(
      storagePath,
      fallbackUrl: versionedPublic,
    );

    await _client.auth.updateUser(
      UserAttributes(
        data: {
          'avatar_url': resolvedUrl,
          'avatar_storage_path': storagePath,
        },
      ),
    );

    try {
      await _client.from('user_profiles').upsert({
        'id': user.id,
        'avatar_url': resolvedUrl,
        'avatar_storage_path': storagePath,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Best-effort mirror to user_profiles if table exists.
    }

    return (avatarUrl: resolvedUrl, storagePath: storagePath);
  }

  /// Clears auth metadata first, then clears `user_profiles` best-effort,
  /// and finally removes the file from Storage (logging failures without rollback).
  static Future<void> removeAvatarOrdered({
    required Future<void> Function() clearAuthMetadata,
    required Future<void> Function() clearProfileTable,
    required Future<void> Function(String storagePath) removeFromStorage,
    String? storagePath,
  }) async {
    await clearAuthMetadata();

    try {
      await clearProfileTable();
    } catch (error, stackTrace) {
      appErrorLogger(
        error,
        stackTrace: stackTrace,
        context: 'ProfileRemoteDataSource.removeAvatar.profileTable',
      );
    }

    if (storagePath != null && storagePath.isNotEmpty) {
      try {
        await removeFromStorage(storagePath);
      } catch (error, stackTrace) {
        appErrorLogger(
          error,
          stackTrace: stackTrace,
          context: 'ProfileRemoteDataSource.removeAvatar.storage',
        );
      }
    }
  }

  @override
  Future<void> removeAvatar(String? storagePath) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await removeAvatarOrdered(
      storagePath: storagePath,
      clearAuthMetadata: () => _client.auth.updateUser(
        UserAttributes(
          data: {
            'avatar_url': null,
            'avatar_storage_path': null,
          },
        ),
      ),
      clearProfileTable: () => _client.from('user_profiles').update({
        'avatar_url': null,
        'avatar_storage_path': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id),
      removeFromStorage: (path) => _client.storage.from(_bucket).remove([path]),
    );
  }

  /// Updates auth display name (when provided) and persists the profile row
  /// best-effort, logging upsert failures via [appErrorLogger] without
  /// changing caller-visible UX behavior.
  static Future<void> saveProfileOrdered({
    Future<void> Function()? updateAuthDisplayName,
    required Future<void> Function() upsertProfileRow,
  }) async {
    if (updateAuthDisplayName != null) {
      await updateAuthDisplayName();
    }

    try {
      await upsertProfileRow();
    } catch (error, stackTrace) {
      appErrorLogger(
        error,
        stackTrace: stackTrace,
        context: 'ProfileRemoteDataSource.saveProfile.upsert',
      );
    }
  }

  @override
  Future<void> saveProfile({
    String? displayName,
    String? biologicalSex,
    int? age,
    int? heightCm,
    double? weightKg,
    double? bodyFatPercent,
    String? goal,
    String? experience,
    String? activityLevel,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await saveProfileOrdered(
      updateAuthDisplayName: displayName != null
          ? () => _client.auth.updateUser(
                UserAttributes(data: {'name': displayName}),
              )
          : null,
      upsertProfileRow: () => _client.from('user_profiles').upsert({
        'id': user.id,
        'display_name': ?displayName,
        'biological_sex': ?biologicalSex,
        'age': ?age,
        'height_cm': ?heightCm,
        'weight_kg': ?weightKg,
        'body_fat_percent': ?bodyFatPercent,
        'goal': ?goal,
        'experience': ?experience,
        'activity_level': ?activityLevel,
        'updated_at': DateTime.now().toIso8601String(),
      }),
    );
  }
}
