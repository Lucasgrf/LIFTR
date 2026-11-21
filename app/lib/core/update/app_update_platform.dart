import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:personal_fitness_os/core/update/app_update_info.dart';

/// Platform abstraction over native Android APK version/install capabilities.
abstract class AppUpdatePlatform {
  bool get isAndroidSupported;
  Future<InstalledAppVersion?> getInstalledVersion();
  Future<String?> getUpdatesCacheDir();
  Future<bool> canRequestPackageInstalls();
  Future<bool> openInstallPermissionSettings();
  Future<bool> installApk(String filePath);
}

class MethodChannelAppUpdatePlatform implements AppUpdatePlatform {
  const MethodChannelAppUpdatePlatform();

  static const MethodChannel _channel =
      MethodChannel('com.personalfitnessos.liftr/app_updater');

  @override
  bool get isAndroidSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<InstalledAppVersion?> getInstalledVersion() async {
    if (!isAndroidSupported) return null;
    try {
      final raw =
          await _channel.invokeMapMethod<String, dynamic>('getAppVersion');
      if (raw == null) return null;
      final versionName = (raw['versionName'] as String?)?.trim() ?? '0.0.0';
      final buildNumber = (raw['buildNumber'] as num?)?.toInt() ?? 0;
      return InstalledAppVersion(
        versionName: versionName,
        buildNumber: buildNumber,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<String?> getUpdatesCacheDir() async {
    if (!isAndroidSupported) return null;
    try {
      return await _channel.invokeMethod<String>('getUpdatesCacheDir');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<bool> canRequestPackageInstalls() async {
    if (!isAndroidSupported) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('canRequestPackageInstalls');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> openInstallPermissionSettings() async {
    if (!isAndroidSupported) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('openInstallPermissionSettings');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> installApk(String filePath) async {
    if (!isAndroidSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'installApk',
        {'filePath': filePath},
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
