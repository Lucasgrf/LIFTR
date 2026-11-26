import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/update/app_update_info.dart';
import 'package:personal_fitness_os/core/update/app_update_platform.dart';
import 'package:personal_fitness_os/core/update/app_update_providers.dart';
import 'package:personal_fitness_os/core/update/app_update_service.dart';
import 'package:personal_fitness_os/core/update/app_update_widgets.dart';
import 'package:personal_fitness_os/core/widgets/liftr_progress_bar.dart';
import 'package:personal_fitness_os/features/settings/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAppUpdatePlatform implements AppUpdatePlatform {
  _FakeAppUpdatePlatform({
    this.isAndroidSupported = true,
    this.installedVersion = const InstalledAppVersion(
      versionName: '0.1.0',
      buildNumber: 100,
    ),
    this.updatesCacheDir,
    this.canInstall = true,
  });

  @override
  bool isAndroidSupported;

  InstalledAppVersion? installedVersion;
  String? updatesCacheDir;
  bool canInstall;
  bool openSettingsCalled = false;
  String? installedApkPath;
  bool installResult = true;

  @override
  Future<InstalledAppVersion?> getInstalledVersion() async => installedVersion;

  @override
  Future<String?> getUpdatesCacheDir() async => updatesCacheDir;

  @override
  Future<bool> canRequestPackageInstalls() async => canInstall;

  @override
  Future<bool> openInstallPermissionSettings() async {
    openSettingsCalled = true;
    return true;
  }

  @override
  Future<bool> installApk(String filePath) async {
    installedApkPath = filePath;
    return installResult;
  }
}

class _FakeAppUpdateHttpClient implements AppUpdateHttpClient {
  _FakeAppUpdateHttpClient({
    this.textResponses = const {},
    this.apkBytes = const [1, 2, 3, 4],
    this.throwOnGet = false,
  });

  Map<String, ({int statusCode, String body})> textResponses;
  List<int> apkBytes;
  bool throwOnGet;
  int getCalls = 0;

  @override
  Future<({int statusCode, String body})> getText(
    Uri uri, {
    Duration timeout = const Duration(seconds: 6),
    Map<String, String> headers = const {},
  }) async {
    getCalls++;
    if (throwOnGet) {
      throw const SocketException('Offline');
    }
    return textResponses[uri.toString()] ??
        (statusCode: 404, body: '{"message":"Not Found"}');
  }

  @override
  Future<void> downloadToFile(
    Uri uri,
    File destination, {
    void Function(int received, int total)? onProgress,
    bool Function()? isCancelled,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (isCancelled?.call() == true) {
      throw const AppUpdateCancelledException();
    }
    final half = apkBytes.length ~/ 2;
    final sink = destination.openWrite();
    try {
      if (half > 0) {
        sink.add(apkBytes.sublist(0, half));
        onProgress?.call(half, apkBytes.length);
      }
      if (isCancelled?.call() == true) {
        throw const AppUpdateCancelledException();
      }
      sink.add(apkBytes.sublist(half));
      onProgress?.call(apkBytes.length, apkBytes.length);
      await sink.flush();
    } finally {
      await sink.close();
    }
  }
}

Map<String, dynamic> _sampleReleaseJson({
  String tagName = 'v0.1.0-build.105',
  bool draft = false,
  bool prerelease = false,
  String body = '- Correções de sessão\n- Melhorias de performance',
}) {
  return {
    'tag_name': tagName,
    'draft': draft,
    'prerelease': prerelease,
    'body': body,
    'html_url': 'https://github.com/Lucasgrf/LIFTR/releases/tag/$tagName',
    'published_at': '2026-11-21T20:00:00Z',
    'assets': [
      {
        'name': 'liftr-universal-release.apk',
        'browser_download_url':
            'https://example.com/liftr-universal-release.apk',
        'size': 70000000,
      },
      {
        'name': 'liftr-arm64-release.apk',
        'browser_download_url': 'https://example.com/liftr-arm64-release.apk',
        'size': 28000000,
      },
      {
        'name': 'liftr-arm64-release.apk.sha256',
        'browser_download_url':
            'https://example.com/liftr-arm64-release.apk.sha256',
        'size': 90,
      },
    ],
  };
}

void main() {
  group('AppUpdateInfo', () {
    test('parseTag supports build suffix, plus build and plain semver', () {
      expect(
        AppUpdateInfo.parseTag('v0.1.0-build.101'),
        (versionName: '0.1.0', buildNumber: 101),
      );
      expect(
        AppUpdateInfo.parseTag('v0.1.0+102'),
        (versionName: '0.1.0', buildNumber: 102),
      );
      expect(
        AppUpdateInfo.parseTag('v0.2.0'),
        (versionName: '0.2.0', buildNumber: 0),
      );
      expect(AppUpdateInfo.parseTag('invalid-tag'), isNull);
    });

    test('tryFromGitHubReleaseJson prefers arm64 asset and ignores draft/prerelease',
        () {
      final parsed = AppUpdateInfo.tryFromGitHubReleaseJson(_sampleReleaseJson());
      expect(parsed, isNotNull);
      expect(parsed!.apkFileName, 'liftr-arm64-release.apk');
      expect(
        parsed.sha256DownloadUrl,
        'https://example.com/liftr-arm64-release.apk.sha256',
      );
      expect(parsed.buildNumber, 105);
      expect(parsed.versionName, '0.1.0');

      expect(
        AppUpdateInfo.tryFromGitHubReleaseJson(_sampleReleaseJson(draft: true)),
        isNull,
      );
      expect(
        AppUpdateInfo.tryFromGitHubReleaseJson(
          _sampleReleaseJson(prerelease: true),
        ),
        isNull,
      );
      expect(
        AppUpdateInfo.tryFromGitHubReleaseJson({
          'tag_name': 'v0.1.0-build.105',
          'assets': const [],
        }),
        isNull,
      );
    });

    test('isNewerThan compares build numbers and semver fallback', () {
      final update = AppUpdateInfo.tryFromGitHubReleaseJson(_sampleReleaseJson())!;

      expect(
        update.isNewerThan(
          const InstalledAppVersion(versionName: '0.1.0', buildNumber: 104),
        ),
        isTrue,
      );
      expect(
        update.isNewerThan(
          const InstalledAppVersion(versionName: '0.1.0', buildNumber: 105),
        ),
        isFalse,
      );
      expect(
        update.isNewerThan(
          const InstalledAppVersion(versionName: '0.1.0', buildNumber: 106),
        ),
        isFalse,
      );

      final semverOnly = AppUpdateInfo.tryFromGitHubReleaseJson(
        _sampleReleaseJson(tagName: 'v0.2.0'),
      )!;
      expect(
        semverOnly.isNewerThan(
          const InstalledAppVersion(versionName: '0.1.9', buildNumber: 100),
        ),
        isTrue,
      );
      expect(
        semverOnly.isNewerThan(
          const InstalledAppVersion(versionName: '0.2.0', buildNumber: 100),
        ),
        isFalse,
      );
    });
  });

  group('AppUpdateService', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('liftr_update_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('downloadAndVerifyApk verifies SHA-256 and cleans stale files', () async {
      final staleApk = File('${tempDir.path}/liftr-build-99.apk')
        ..writeAsStringSync('old');
      final stalePart = File('${tempDir.path}/liftr-build-100.apk.part')
        ..writeAsStringSync('partial');

      final payloadBytes = utf8.encode('fake-apk-binary-payload');
      final validSha = sha256.convert(payloadBytes).toString();
      final info = AppUpdateInfo.tryFromGitHubReleaseJson(_sampleReleaseJson())!;

      final httpClient = _FakeAppUpdateHttpClient(
        apkBytes: payloadBytes,
        textResponses: {
          info.sha256DownloadUrl!: (
            statusCode: 200,
            body: '$validSha  liftr-arm64-release.apk\n',
          ),
        },
      );
      final platform = _FakeAppUpdatePlatform(updatesCacheDir: tempDir.path);
      final service = AppUpdateService(platform: platform, httpClient: httpClient);

      var verifyingCalled = false;
      final progressEvents = <(int, int)>[];

      final savedPath = await service.downloadAndVerifyApk(
        info,
        onProgress: (r, t) => progressEvents.add((r, t)),
        onVerifying: () => verifyingCalled = true,
      );

      expect(staleApk.existsSync(), isFalse);
      expect(stalePart.existsSync(), isFalse);
      expect(verifyingCalled, isTrue);
      expect(progressEvents, isNotEmpty);
      expect(File(savedPath).existsSync(), isTrue);
      expect(File(savedPath).readAsBytesSync(), payloadBytes);
    });

    test('downloadAndVerifyApk rejects corrupted APK and deletes .part file',
        () async {
      final info = AppUpdateInfo.tryFromGitHubReleaseJson(_sampleReleaseJson())!;
      final httpClient = _FakeAppUpdateHttpClient(
        apkBytes: utf8.encode('corrupted-payload'),
        textResponses: {
          info.sha256DownloadUrl!: (
            statusCode: 200,
            body: '${'0' * 64}  liftr-arm64-release.apk\n',
          ),
        },
      );
      final platform = _FakeAppUpdatePlatform(updatesCacheDir: tempDir.path);
      final service = AppUpdateService(platform: platform, httpClient: httpClient);

      await expectLater(
        () => service.downloadAndVerifyApk(info),
        throwsA(isA<AppUpdateIntegrityException>()),
      );

      final remaining = tempDir.listSync();
      expect(remaining, isEmpty);
    });
  });

  group('AppUpdateNotifier', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('liftr_notifier_test_');
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('checkSilentlyIfDue respects throttle, offline/session guards and silent error',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final platform = _FakeAppUpdatePlatform(updatesCacheDir: tempDir.path);
      final httpClient = _FakeAppUpdateHttpClient(
        textResponses: {
          AppUpdateService.latestReleaseUri.toString(): (
            statusCode: 403,
            body: '{"message":"rate limit"}',
          ),
        },
      );
      final service = AppUpdateService(platform: platform, httpClient: httpClient);
      var currentTime = DateTime(2026, 11, 21, 12, 0);

      final notifier = AppUpdateNotifier(
        service: service,
        platform: platform,
        prefs: prefs,
        now: () => currentTime,
      );

      // Guarded when offline, in active session, or unsupported platform
      await notifier.checkSilentlyIfDue(isOffline: true);
      await notifier.checkSilentlyIfDue(hasActiveSession: true);
      expect(httpClient.getCalls, 0);

      final unsupportedService = AppUpdateService(
        platform: _FakeAppUpdatePlatform(
          isAndroidSupported: false,
          installedVersion: null,
        ),
        httpClient: httpClient,
      );
      final unsupportedRes = await unsupportedService.checkForUpdate();
      expect(unsupportedRes.status, AppUpdateCheckStatus.unsupported);

      // Network SocketException fails silently with no error surfaced
      final offlineHttpService = AppUpdateService(
        platform: platform,
        httpClient: _FakeAppUpdateHttpClient(throwOnGet: true),
      );
      final offlineRes = await offlineHttpService.checkForUpdate();
      expect(offlineRes.status, AppUpdateCheckStatus.failed);

      // Runs once and fails silently on HTTP 403
      await notifier.checkSilentlyIfDue();
      expect(httpClient.getCalls, 1);
      expect(notifier.state.phase, AppUpdatePhase.idle);
      expect(notifier.state.errorMessage, isNull);

      // Throttled within 6h
      currentTime = currentTime.add(const Duration(hours: 2));
      await notifier.checkSilentlyIfDue();
      expect(httpClient.getCalls, 1);

      // Allowed after 6h and surfaces update when available
      currentTime = currentTime.add(const Duration(hours: 5));
      httpClient.textResponses = {
        AppUpdateService.latestReleaseUri.toString(): (
          statusCode: 200,
          body: jsonEncode(_sampleReleaseJson()),
        ),
      };
      await notifier.checkSilentlyIfDue();
      expect(httpClient.getCalls, 2);
      expect(notifier.state.phase, AppUpdatePhase.available);
      expect(notifier.state.shouldShowBanner, isTrue);

      // Dismiss hides banner, checkManually clears dismiss
      await notifier.dismissBanner();
      expect(notifier.state.shouldShowBanner, isFalse);

      final manual = await notifier.checkManually();
      expect(manual.status, AppUpdateCheckStatus.available);
      expect(notifier.state.shouldShowBanner, isTrue);
    });

    test('downloadAndInstall handles permissionRequired then installs on retry',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final payloadBytes = utf8.encode('valid-apk-bytes');
      final validSha = sha256.convert(payloadBytes).toString();
      final releaseJson = _sampleReleaseJson();
      final parsedInfo = AppUpdateInfo.tryFromGitHubReleaseJson(releaseJson)!;

      final platform = _FakeAppUpdatePlatform(
        updatesCacheDir: tempDir.path,
        canInstall: false,
      );
      final httpClient = _FakeAppUpdateHttpClient(
        apkBytes: payloadBytes,
        textResponses: {
          AppUpdateService.latestReleaseUri.toString(): (
            statusCode: 200,
            body: jsonEncode(releaseJson),
          ),
          parsedInfo.sha256DownloadUrl!: (
            statusCode: 200,
            body: validSha,
          ),
        },
      );
      final service = AppUpdateService(platform: platform, httpClient: httpClient);
      final notifier = AppUpdateNotifier(
        service: service,
        platform: platform,
        prefs: prefs,
      );

      await notifier.checkManually();
      await notifier.downloadAndInstall();

      expect(notifier.state.phase, AppUpdatePhase.permissionRequired);
      expect(notifier.state.downloadedApkPath, isNotNull);
      expect(platform.installedApkPath, isNull);

      await notifier.openInstallPermissionSettings();
      expect(platform.openSettingsCalled, isTrue);

      platform.canInstall = true;
      await notifier.retryInstallDownloadedApk();
      expect(notifier.state.phase, AppUpdatePhase.installing);
      expect(platform.installedApkPath, notifier.state.downloadedApkPath);
    });
  });

  group('Update UI widgets & Settings integration', () {
    testWidgets('AppUpdateBanner renders and dispatches callbacks',
        (tester) async {
      var updateTapped = false;
      var dismissed = false;
      final info = AppUpdateInfo.tryFromGitHubReleaseJson(_sampleReleaseJson())!;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: AppUpdateBanner(
              updateInfo: info,
              onUpdateTap: () => updateTapped = true,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.text('Nova versão v0.1.0 disponível'), findsOneWidget);
      await tester.tap(find.text('Atualizar'));
      expect(updateTapped, isTrue);

      await tester.tap(find.bySemanticsLabel('Ocultar aviso de atualização'));
      expect(dismissed, isTrue);
    });

    testWidgets('SettingsScreen displays Atualizações do app and opens sheet',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final releaseJson = _sampleReleaseJson();
      final platform = _FakeAppUpdatePlatform();
      final httpClient = _FakeAppUpdateHttpClient(
        textResponses: {
          AppUpdateService.latestReleaseUri.toString(): (
            statusCode: 200,
            body: jsonEncode(releaseJson),
          ),
        },
      );
      final service = AppUpdateService(platform: platform, httpClient: httpClient);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isOnlineStreamProvider.overrideWith((_) => Stream.value(true)),
            appUpdatePlatformProvider.overrideWithValue(platform),
            appUpdateServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Atualizações do app'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Atualizações do app'));
      await tester.pumpAndSettle();
      expect(find.text('Atualizações do app'), findsOneWidget);
      expect(find.text('v0.1.0 (build 100)'), findsOneWidget);

      await tester.tap(find.text('Atualizações do app'));
      await tester.pumpAndSettle();

      expect(find.text('Nova versão do LIFTR'), findsOneWidget);
      expect(find.text('Atualizar agora'), findsOneWidget);
    });

    testWidgets('AppUpdateSheet renders downloading and permissionRequired states',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final info = AppUpdateInfo.tryFromGitHubReleaseJson(_sampleReleaseJson())!;
      final platform = _FakeAppUpdatePlatform();
      final service = AppUpdateService(
        platform: platform,
        httpClient: _FakeAppUpdateHttpClient(),
      );

      final notifier = AppUpdateNotifier(
        service: service,
        platform: platform,
        prefs: prefs,
      );

      // 1. Downloading state
      notifier.state = AppUpdateState(
        phase: AppUpdatePhase.downloading,
        installedVersion: const InstalledAppVersion(
          versionName: '0.1.0',
          buildNumber: 100,
        ),
        availableUpdate: info,
        receivedBytes: 14 * 1024 * 1024,
        totalBytes: 28 * 1024 * 1024,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appUpdatePlatformProvider.overrideWithValue(platform),
            appUpdateServiceProvider.overrideWithValue(service),
            appUpdateProvider.overrideWith((_) => notifier),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(body: AppUpdateSheet()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LiftrProgressBar), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      // 2. PermissionRequired state
      notifier.state = notifier.state.copyWith(
        phase: AppUpdatePhase.permissionRequired,
        downloadedApkPath: '/tmp/liftr-build-105.apk',
      );
      await tester.pump();

      expect(find.text('Permitir instalação'), findsOneWidget);
      expect(find.text('Já permiti, instalar agora'), findsOneWidget);
    });
  });
}
