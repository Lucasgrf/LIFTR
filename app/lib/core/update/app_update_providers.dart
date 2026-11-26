import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/update/app_update_info.dart';
import 'package:personal_fitness_os/core/update/app_update_platform.dart';
import 'package:personal_fitness_os/core/update/app_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppUpdatePhase {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  verifying,
  permissionRequired,
  installing,
  error,
}

@immutable
class AppUpdateState {
  const AppUpdateState({
    this.phase = AppUpdatePhase.idle,
    this.installedVersion,
    this.availableUpdate,
    this.downloadedApkPath,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
    this.dismissedTag,
  });

  final AppUpdatePhase phase;
  final InstalledAppVersion? installedVersion;
  final AppUpdateInfo? availableUpdate;
  final String? downloadedApkPath;
  final int receivedBytes;
  final int totalBytes;
  final String? errorMessage;
  final String? dismissedTag;

  bool get shouldShowBanner =>
      phase == AppUpdatePhase.available &&
      availableUpdate != null &&
      dismissedTag != availableUpdate!.tagName;

  double? get progress =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : null;

  AppUpdateState copyWith({
    AppUpdatePhase? phase,
    InstalledAppVersion? installedVersion,
    AppUpdateInfo? availableUpdate,
    bool clearAvailableUpdate = false,
    String? downloadedApkPath,
    bool clearDownloadedApkPath = false,
    int? receivedBytes,
    int? totalBytes,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? dismissedTag,
  }) {
    return AppUpdateState(
      phase: phase ?? this.phase,
      installedVersion: installedVersion ?? this.installedVersion,
      availableUpdate: clearAvailableUpdate
          ? null
          : (availableUpdate ?? this.availableUpdate),
      downloadedApkPath: clearDownloadedApkPath
          ? null
          : (downloadedApkPath ?? this.downloadedApkPath),
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      dismissedTag: dismissedTag ?? this.dismissedTag,
    );
  }
}

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  AppUpdateNotifier({
    required this._service,
    required this._platform,
    SharedPreferences? prefs,
    DateTime Function()? now,
  })  : _prefs = prefs,
        _now = now ?? DateTime.now,
        super(
          AppUpdateState(
            dismissedTag: prefs?.getString(_dismissedTagKey),
          ),
        );

  static const String _lastCheckedMsKey = 'liftr_update_last_checked_ms';
  static const String _dismissedTagKey = 'liftr_update_dismissed_tag';
  static const Duration checkThrottle = Duration(hours: 6);

  final AppUpdateService _service;
  final AppUpdatePlatform _platform;
  final SharedPreferences? _prefs;
  final DateTime Function() _now;

  bool _isBusy = false;
  bool _cancelRequested = false;

  Future<void> loadInstalledVersion() async {
    if (!_platform.isAndroidSupported) return;
    final installed = await _platform.getInstalledVersion();
    if (installed != null && mounted) {
      state = state.copyWith(installedVersion: installed);
    }
  }

  Future<void> checkSilentlyIfDue({
    bool isOffline = false,
    bool hasActiveSession = false,
  }) async {
    if (!_platform.isAndroidSupported || isOffline || hasActiveSession) return;
    if (_isBusy) return;
    if (state.phase == AppUpdatePhase.downloading ||
        state.phase == AppUpdatePhase.verifying ||
        state.phase == AppUpdatePhase.permissionRequired ||
        state.phase == AppUpdatePhase.installing) {
      return;
    }

    final currentNow = _now();
    final lastCheckedMs = _prefs?.getInt(_lastCheckedMsKey);
    if (lastCheckedMs != null) {
      final elapsed = currentNow.millisecondsSinceEpoch - lastCheckedMs;
      if (elapsed >= 0 && elapsed < checkThrottle.inMilliseconds) {
        await loadInstalledVersion();
        return;
      }
    }

    _isBusy = true;
    try {
      await _prefs?.setInt(_lastCheckedMsKey, currentNow.millisecondsSinceEpoch);
      final result = await _service.checkForUpdate();
      if (!mounted) return;
      switch (result.status) {
        case AppUpdateCheckStatus.available:
          state = state.copyWith(
            phase: AppUpdatePhase.available,
            installedVersion: result.installedVersion,
            availableUpdate: result.updateInfo,
            dismissedTag: _prefs?.getString(_dismissedTagKey),
            clearErrorMessage: true,
          );
          break;
        case AppUpdateCheckStatus.upToDate:
          state = state.copyWith(
            phase: AppUpdatePhase.upToDate,
            installedVersion: result.installedVersion,
            clearAvailableUpdate: true,
            clearErrorMessage: true,
          );
          break;
        case AppUpdateCheckStatus.unsupported:
        case AppUpdateCheckStatus.failed:
          state = state.copyWith(
            phase: AppUpdatePhase.idle,
            installedVersion: result.installedVersion,
            clearErrorMessage: true,
          );
          break;
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(phase: AppUpdatePhase.idle);
      }
    } finally {
      _isBusy = false;
    }
  }

  Future<AppUpdateCheckResult> checkManually() async {
    if (!_platform.isAndroidSupported) {
      return const AppUpdateCheckResult(
        status: AppUpdateCheckStatus.unsupported,
      );
    }
    if (_isBusy) {
      return AppUpdateCheckResult(
        status: state.availableUpdate != null
            ? AppUpdateCheckStatus.available
            : AppUpdateCheckStatus.upToDate,
        installedVersion: state.installedVersion,
        updateInfo: state.availableUpdate,
      );
    }

    _isBusy = true;
    state = state.copyWith(
      phase: AppUpdatePhase.checking,
      clearErrorMessage: true,
    );

    try {
      await _prefs?.setInt(_lastCheckedMsKey, _now().millisecondsSinceEpoch);
      final result = await _service.checkForUpdate();
      if (!mounted) return result;

      switch (result.status) {
        case AppUpdateCheckStatus.available:
          await _prefs?.remove(_dismissedTagKey);
          state = AppUpdateState(
            phase: AppUpdatePhase.available,
            installedVersion: result.installedVersion,
            availableUpdate: result.updateInfo,
            downloadedApkPath: state.downloadedApkPath,
          );
          break;
        case AppUpdateCheckStatus.upToDate:
          state = state.copyWith(
            phase: AppUpdatePhase.upToDate,
            installedVersion: result.installedVersion,
            clearAvailableUpdate: true,
            clearErrorMessage: true,
          );
          break;
        case AppUpdateCheckStatus.unsupported:
          state = state.copyWith(
            phase: AppUpdatePhase.idle,
            clearErrorMessage: true,
          );
          break;
        case AppUpdateCheckStatus.failed:
          state = state.copyWith(
            phase: AppUpdatePhase.error,
            installedVersion: result.installedVersion,
            errorMessage: result.errorMessage ??
                'Não foi possível verificar atualizações.',
          );
          break;
      }
      return result;
    } finally {
      _isBusy = false;
    }
  }

  Future<void> downloadAndInstall() async {
    final update = state.availableUpdate;
    if (update == null || _isBusy) return;

    _isBusy = true;
    _cancelRequested = false;
    state = state.copyWith(
      phase: AppUpdatePhase.downloading,
      receivedBytes: 0,
      totalBytes: update.apkSizeBytes,
      clearErrorMessage: true,
      clearDownloadedApkPath: true,
    );

    try {
      final apkPath = await _service.downloadAndVerifyApk(
        update,
        onProgress: (received, total) {
          if (!mounted) return;
          state = state.copyWith(
            receivedBytes: received,
            totalBytes: total > 0 ? total : update.apkSizeBytes,
          );
        },
        onVerifying: () {
          if (!mounted) return;
          state = state.copyWith(phase: AppUpdatePhase.verifying);
        },
        isCancelled: () => _cancelRequested,
      );

      if (!mounted) return;
      final installResult = await _service.triggerInstall(apkPath);
      if (!mounted) return;
      switch (installResult) {
        case ApkInstallTriggerResult.launched:
          state = state.copyWith(
            phase: AppUpdatePhase.installing,
            downloadedApkPath: apkPath,
            clearErrorMessage: true,
          );
          break;
        case ApkInstallTriggerResult.permissionRequired:
          state = state.copyWith(
            phase: AppUpdatePhase.permissionRequired,
            downloadedApkPath: apkPath,
            clearErrorMessage: true,
          );
          break;
        case ApkInstallTriggerResult.failed:
          state = state.copyWith(
            phase: AppUpdatePhase.error,
            downloadedApkPath: apkPath,
            errorMessage: 'Não foi possível abrir o instalador do Android.',
          );
          break;
      }
    } on AppUpdateCancelledException {
      if (mounted) {
        state = state.copyWith(
          phase: AppUpdatePhase.available,
          receivedBytes: 0,
          clearErrorMessage: true,
        );
      }
    } on AppUpdateIntegrityException catch (e) {
      if (mounted) {
        state = state.copyWith(
          phase: AppUpdatePhase.error,
          errorMessage: e.message,
        );
      }
    } catch (e, st) {
      if (mounted) {
        state = state.copyWith(
          phase: AppUpdatePhase.error,
          errorMessage: userFacingMessage(
            e,
            stackTrace: st,
            context: 'AppUpdateNotifier.downloadAndInstall',
          ),
        );
      }
    } finally {
      _isBusy = false;
    }
  }

  Future<void> openInstallPermissionSettings() async {
    await _platform.openInstallPermissionSettings();
  }

  Future<void> retryInstallDownloadedApk() async {
    final apkPath = state.downloadedApkPath;
    if (apkPath == null || apkPath.isEmpty) {
      await downloadAndInstall();
      return;
    }

    final installResult = await _service.triggerInstall(apkPath);
    if (!mounted) return;
    switch (installResult) {
      case ApkInstallTriggerResult.launched:
        state = state.copyWith(
          phase: AppUpdatePhase.installing,
          clearErrorMessage: true,
        );
        break;
      case ApkInstallTriggerResult.permissionRequired:
        state = state.copyWith(
          phase: AppUpdatePhase.permissionRequired,
          clearErrorMessage: true,
        );
        break;
      case ApkInstallTriggerResult.failed:
        state = state.copyWith(
          phase: AppUpdatePhase.error,
          errorMessage: 'Não foi possível abrir o instalador do Android.',
        );
        break;
    }
  }

  void cancelDownload() {
    _cancelRequested = true;
  }

  Future<void> dismissBanner() async {
    final tag = state.availableUpdate?.tagName;
    if (tag == null) return;
    await _prefs?.setString(_dismissedTagKey, tag);
    if (mounted) {
      state = state.copyWith(dismissedTag: tag);
    }
  }
}

final appUpdatePlatformProvider = Provider<AppUpdatePlatform>((ref) {
  return const MethodChannelAppUpdatePlatform();
});

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService(platform: ref.watch(appUpdatePlatformProvider));
});

final appUpdateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  return AppUpdateNotifier(
    service: ref.watch(appUpdateServiceProvider),
    platform: ref.watch(appUpdatePlatformProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});
