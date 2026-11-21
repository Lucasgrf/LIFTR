import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:personal_fitness_os/core/update/app_update_info.dart';
import 'package:personal_fitness_os/core/update/app_update_platform.dart';

class AppUpdateIntegrityException implements Exception {
  const AppUpdateIntegrityException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppUpdateCancelledException implements Exception {
  const AppUpdateCancelledException();

  @override
  String toString() => 'Download cancelado.';
}

enum AppUpdateCheckStatus {
  unsupported,
  upToDate,
  available,
  failed,
}

enum ApkInstallTriggerResult {
  launched,
  permissionRequired,
  failed,
}

class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.status,
    this.installedVersion,
    this.updateInfo,
    this.errorMessage,
  });

  final AppUpdateCheckStatus status;
  final InstalledAppVersion? installedVersion;
  final AppUpdateInfo? updateInfo;
  final String? errorMessage;
}

/// Minimal HTTP client abstraction so update checks and downloads can be tested
/// without network I/O.
abstract class AppUpdateHttpClient {
  Future<({int statusCode, String body})> getText(
    Uri uri, {
    Duration timeout = const Duration(seconds: 6),
    Map<String, String> headers = const {},
  });

  Future<void> downloadToFile(
    Uri uri,
    File destination, {
    void Function(int received, int total)? onProgress,
    bool Function()? isCancelled,
    Duration timeout = const Duration(seconds: 30),
  });
}

class DartIoAppUpdateHttpClient implements AppUpdateHttpClient {
  const DartIoAppUpdateHttpClient();

  @override
  Future<({int statusCode, String body})> getText(
    Uri uri, {
    Duration timeout = const Duration(seconds: 6),
    Map<String, String> headers = const {},
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      headers.forEach(request.headers.set);
      final response = await request.close().timeout(timeout);
      final body = await response.transform(utf8.decoder).join().timeout(
            timeout,
          );
      return (statusCode: response.statusCode, body: body);
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> downloadToFile(
    Uri uri,
    File destination, {
    void Function(int received, int total)? onProgress,
    bool Function()? isCancelled,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    IOSink? sink;
    try {
      if (isCancelled?.call() == true) {
        throw const AppUpdateCancelledException();
      }
      final request = await client.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.userAgentHeader, 'LIFTR-Android-Updater');
      final response = await request.close().timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Falha no download (HTTP ${response.statusCode})',
          uri: uri,
        );
      }

      final total = response.contentLength > 0 ? response.contentLength : 0;
      sink = destination.openWrite();
      var received = 0;

      await for (final chunk in response) {
        if (isCancelled?.call() == true) {
          throw const AppUpdateCancelledException();
        }
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }

      await sink.flush();
      await sink.close();
      sink = null;
    } finally {
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      client.close(force: true);
    }
  }
}

/// Checks GitHub Releases for newer APK builds, verifies SHA-256 checksums,
/// and invokes the native Android package installer.
class AppUpdateService {
  AppUpdateService({
    required this.platform,
    AppUpdateHttpClient? httpClient,
  }) : _httpClient = httpClient ?? const DartIoAppUpdateHttpClient();

  static const String githubOwner = 'Lucasgrf';
  static const String githubRepo = 'LIFTR';
  static final Uri latestReleaseUri = Uri.https(
    'api.github.com',
    '/repos/$githubOwner/$githubRepo/releases/latest',
  );

  static const Map<String, String> _githubHeaders = {
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'LIFTR-Android-Updater',
  };

  final AppUpdatePlatform platform;
  final AppUpdateHttpClient _httpClient;

  Future<AppUpdateCheckResult> checkForUpdate() async {
    if (!platform.isAndroidSupported) {
      return const AppUpdateCheckResult(
        status: AppUpdateCheckStatus.unsupported,
      );
    }

    final installed = await platform.getInstalledVersion();
    if (installed == null) {
      return const AppUpdateCheckResult(
        status: AppUpdateCheckStatus.failed,
        errorMessage: 'Não foi possível ler a versão instalada.',
      );
    }

    try {
      final response = await _httpClient.getText(
        latestReleaseUri,
        timeout: const Duration(seconds: 6),
        headers: _githubHeaders,
      );
      if (response.statusCode != 200) {
        return AppUpdateCheckResult(
          status: AppUpdateCheckStatus.failed,
          installedVersion: installed,
          errorMessage: 'Erro ao consultar atualização (HTTP ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return AppUpdateCheckResult(
          status: AppUpdateCheckStatus.failed,
          installedVersion: installed,
          errorMessage: 'Resposta inválida do servidor de atualizações.',
        );
      }

      final remote = AppUpdateInfo.tryFromGitHubReleaseJson(
        Map<String, dynamic>.from(decoded),
      );
      if (remote == null || !remote.isNewerThan(installed)) {
        return AppUpdateCheckResult(
          status: AppUpdateCheckStatus.upToDate,
          installedVersion: installed,
        );
      }

      return AppUpdateCheckResult(
        status: AppUpdateCheckStatus.available,
        installedVersion: installed,
        updateInfo: remote,
      );
    } catch (e) {
      return AppUpdateCheckResult(
        status: AppUpdateCheckStatus.failed,
        installedVersion: installed,
        errorMessage: 'Não foi possível verificar atualizações agora.',
      );
    }
  }

  Future<String> downloadAndVerifyApk(
    AppUpdateInfo info, {
    void Function(int received, int total)? onProgress,
    void Function()? onVerifying,
    bool Function()? isCancelled,
  }) async {
    final cacheDirPath = await platform.getUpdatesCacheDir();
    if (cacheDirPath == null || cacheDirPath.isEmpty) {
      throw StateError('Diretório de cache de atualizações indisponível.');
    }

    final updatesDir = Directory(cacheDirPath);
    if (!updatesDir.existsSync()) {
      updatesDir.createSync(recursive: true);
    }

    // Remove stale APK/partial downloads to keep cache bounded.
    try {
      for (final entity in updatesDir.listSync()) {
        if (entity is File &&
            (entity.path.endsWith('.apk') || entity.path.endsWith('.part'))) {
          try {
            entity.deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}

    final buildSuffix = info.buildNumber > 0
        ? 'build-${info.buildNumber}'
        : info.versionName.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '_');
    final targetPath = '${updatesDir.path}/liftr-$buildSuffix.apk';
    final partFile = File('$targetPath.part');
    final targetFile = File(targetPath);

    try {
      await _httpClient.downloadToFile(
        Uri.parse(info.apkDownloadUrl),
        partFile,
        onProgress: onProgress,
        isCancelled: isCancelled,
      );

      if (isCancelled?.call() == true) {
        throw const AppUpdateCancelledException();
      }

      onVerifying?.call();

      final shaUrl = info.sha256DownloadUrl;
      if (shaUrl != null && shaUrl.isNotEmpty) {
        final shaResponse = await _httpClient.getText(
          Uri.parse(shaUrl),
          timeout: const Duration(seconds: 10),
          headers: const {'User-Agent': 'LIFTR-Android-Updater'},
        );
        final expectedHash = shaResponse.statusCode == 200
            ? RegExp(r'\b([a-fA-F0-9]{64})\b')
                .firstMatch(shaResponse.body)
                ?.group(1)
                ?.toLowerCase()
            : null;
        if (expectedHash == null) {
          throw const AppUpdateIntegrityException(
            'Não foi possível validar o checksum SHA-256 da atualização.',
          );
        }

        final digest = await sha256.bind(partFile.openRead()).first;
        if (digest.toString().toLowerCase() != expectedHash) {
          throw const AppUpdateIntegrityException(
            'O arquivo baixado falhou na verificação de integridade (SHA-256).',
          );
        }
      }

      if (targetFile.existsSync()) {
        targetFile.deleteSync();
      }
      await partFile.rename(targetPath);
      return targetPath;
    } catch (_) {
      if (partFile.existsSync()) {
        try {
          partFile.deleteSync();
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<ApkInstallTriggerResult> triggerInstall(String apkPath) async {
    final allowed = await platform.canRequestPackageInstalls();
    if (!allowed) {
      return ApkInstallTriggerResult.permissionRequired;
    }
    final launched = await platform.installApk(apkPath);
    return launched
        ? ApkInstallTriggerResult.launched
        : ApkInstallTriggerResult.failed;
  }
}
