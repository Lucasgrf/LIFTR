import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/constants/supabase_config.dart';
import 'package:personal_fitness_os/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  try {
    return SupabaseProfileRemoteDataSource(Supabase.instance.client);
  } catch (_) {
    return null;
  }
});

@immutable
class ProfileControllerState {
  const ProfileControllerState({
    this.isLoading = false,
    this.isUploadingAvatar = false,
    this.email,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isUploadingAvatar;
  final String? email;
  final String? errorMessage;

  ProfileControllerState copyWith({
    bool? isLoading,
    bool? isUploadingAvatar,
    String? email,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileControllerState(
      isLoading: isLoading ?? this.isLoading,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      email: email ?? this.email,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ProfileController extends StateNotifier<ProfileControllerState> {
  ProfileController(this._ref, this._remoteDataSource)
      : super(const ProfileControllerState()) {
    loadProfile();
  }

  final Ref _ref;
  final ProfileRemoteDataSource? _remoteDataSource;

  Future<void> loadProfile() async {
    final remote = _remoteDataSource;
    if (remote == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await remote.fetchProfile();
      if (profile != null) {
        state = state.copyWith(isLoading: false, email: profile.email);
        final settingsNotifier = _ref.read(userSettingsProvider.notifier);
        settingsNotifier.updateProfileIdentity(
          displayName: profile.displayName,
          avatarUrl: profile.avatarUrl,
          avatarStoragePath: profile.avatarStoragePath,
        );
        if (profile.biologicalSex != null ||
            profile.age != null ||
            profile.heightCm != null ||
            profile.weightKg != null) {
          settingsNotifier.updateBodyData(
            biologicalSex: profile.biologicalSex,
            age: profile.age,
            heightCm: profile.heightCm,
            weightKg: profile.weightKg,
            bodyFatPercent: profile.bodyFatPercent,
          );
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> uploadAvatar(String filePath) async {
    final remote = _remoteDataSource;
    final previousPath = _ref.read(userSettingsProvider).avatarStoragePath;
    state = state.copyWith(isUploadingAvatar: true, clearError: true);

    if (remote == null) {
      // Local-only mode fallback when Supabase is not configured.
      _ref.read(userSettingsProvider.notifier).updateProfileIdentity(
            avatarUrl: filePath,
            avatarStoragePath: filePath,
          );
      state = state.copyWith(isUploadingAvatar: false);
      return true;
    }

    try {
      final result = await remote.uploadAvatar(
        filePath,
        previousStoragePath: previousPath,
      );
      _ref.read(userSettingsProvider.notifier).updateProfileIdentity(
            avatarUrl: result.avatarUrl,
            avatarStoragePath: result.storagePath,
          );
      state = state.copyWith(isUploadingAvatar: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploadingAvatar: false,
        errorMessage: 'Não foi possível enviar a foto de perfil: $e',
      );
      return false;
    }
  }

  Future<void> removeAvatar() async {
    final storagePath = _ref.read(userSettingsProvider).avatarStoragePath;
    _ref.read(userSettingsProvider.notifier).updateProfileIdentity(
          clearAvatar: true,
        );
    final remote = _remoteDataSource;
    if (remote != null) {
      await remote.removeAvatar(storagePath);
    }
  }

  Future<void> updateDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _ref.read(userSettingsProvider.notifier).updateProfileIdentity(
          displayName: trimmed,
        );
    await syncSettingsToRemote();
  }

  Future<void> syncSettingsToRemote() async {
    final remote = _remoteDataSource;
    if (remote == null) return;
    final settings = _ref.read(userSettingsProvider);
    try {
      await remote.saveProfile(
        displayName: settings.displayName,
        biologicalSex: settings.biologicalSex,
        age: settings.age,
        heightCm: settings.heightCm,
        weightKg: settings.weightKg,
        bodyFatPercent: settings.bodyFatPercent,
        goal: settings.goal.name,
        experience: settings.experience.name,
        activityLevel: settings.activityLevel.name,
      );
    } catch (_) {
      // Local settings remain persisted offline.
    }
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileControllerState>((ref) {
  return ProfileController(ref, ref.watch(profileRemoteDataSourceProvider));
});
