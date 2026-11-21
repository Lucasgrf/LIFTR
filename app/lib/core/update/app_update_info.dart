import 'package:flutter/foundation.dart';

/// Version information read from the running Android package.
@immutable
class InstalledAppVersion {
  const InstalledAppVersion({
    required this.versionName,
    required this.buildNumber,
  });

  final String versionName;
  final int buildNumber;

  String get formattedLabel =>
      buildNumber > 0 ? 'v$versionName (build $buildNumber)' : 'v$versionName';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InstalledAppVersion &&
        other.versionName == versionName &&
        other.buildNumber == buildNumber;
  }

  @override
  int get hashCode => Object.hash(versionName, buildNumber);
}

/// Metadata for an available GitHub Release containing an Android APK asset.
@immutable
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.tagName,
    required this.versionName,
    required this.buildNumber,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.apkFileName,
    required this.apkSizeBytes,
    this.sha256DownloadUrl,
    this.htmlUrl,
    this.publishedAt,
  });

  final String tagName;
  final String versionName;
  final int buildNumber;
  final String releaseNotes;
  final String apkDownloadUrl;
  final String apkFileName;
  final int apkSizeBytes;
  final String? sha256DownloadUrl;
  final String? htmlUrl;
  final DateTime? publishedAt;

  static final RegExp _tagPattern = RegExp(
    r'^v?(\d+\.\d+\.\d+)(?:[-+]build\.?(\d+)|\+(\d+))?$',
    caseSensitive: false,
  );

  /// Parses release tags like `v0.1.0-build.101`, `v0.1.0+101`, or `v0.1.0`.
  static ({String versionName, int buildNumber})? parseTag(String tag) {
    final match = _tagPattern.firstMatch(tag.trim());
    if (match == null) return null;
    final versionName = match.group(1)!;
    final rawBuild = match.group(2) ?? match.group(3);
    final buildNumber = rawBuild != null ? int.tryParse(rawBuild) ?? 0 : 0;
    return (versionName: versionName, buildNumber: buildNumber);
  }

  /// Parses a GitHub Releases API payload, preferring an `arm64` APK asset.
  static AppUpdateInfo? tryFromGitHubReleaseJson(Map<String, dynamic> json) {
    if (json['draft'] == true || json['prerelease'] == true) {
      return null;
    }

    final tagName = (json['tag_name'] as String?)?.trim() ?? '';
    final parsed = parseTag(tagName);
    if (parsed == null) return null;

    final rawAssets = json['assets'];
    if (rawAssets is! List) return null;

    final assets = rawAssets
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final apkAssets = assets.where((asset) {
      final name = (asset['name'] as String?)?.toLowerCase() ?? '';
      final url = (asset['browser_download_url'] as String?)?.trim() ?? '';
      return name.endsWith('.apk') && url.isNotEmpty;
    }).toList();

    if (apkAssets.isEmpty) return null;

    final selectedApk = apkAssets.firstWhere(
      (asset) =>
          ((asset['name'] as String?)?.toLowerCase() ?? '').contains('arm64'),
      orElse: () => apkAssets.first,
    );

    final apkFileName = (selectedApk['name'] as String).trim();
    final apkDownloadUrl =
        (selectedApk['browser_download_url'] as String).trim();
    final apkSizeBytes = (selectedApk['size'] as num?)?.toInt() ?? 0;

    final shaAssets = assets.where((asset) {
      final name = (asset['name'] as String?)?.toLowerCase() ?? '';
      final url = (asset['browser_download_url'] as String?)?.trim() ?? '';
      return name.endsWith('.sha256') && url.isNotEmpty;
    }).toList();

    Map<String, dynamic>? matchedSha;
    for (final sha in shaAssets) {
      final shaName = (sha['name'] as String?)?.toLowerCase() ?? '';
      if (shaName == '${apkFileName.toLowerCase()}.sha256') {
        matchedSha = sha;
        break;
      }
    }
    matchedSha ??= shaAssets.isNotEmpty ? shaAssets.first : null;

    return AppUpdateInfo(
      tagName: tagName,
      versionName: parsed.versionName,
      buildNumber: parsed.buildNumber,
      releaseNotes: (json['body'] as String?)?.trim() ?? '',
      apkDownloadUrl: apkDownloadUrl,
      apkFileName: apkFileName,
      apkSizeBytes: apkSizeBytes,
      sha256DownloadUrl:
          (matchedSha?['browser_download_url'] as String?)?.trim(),
      htmlUrl: (json['html_url'] as String?)?.trim(),
      publishedAt: json['published_at'] is String
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
    );
  }

  /// Compares two semantic version strings (`major.minor.patch`).
  static int compareSemver(String a, String b) {
    List<int> parseParts(String raw) {
      final core = raw.split('+').first.split('-').first;
      final segments = core.split('.');
      return [
        for (var i = 0; i < 3; i++)
          i < segments.length ? int.tryParse(segments[i].trim()) ?? 0 : 0,
      ];
    }

    final partsA = parseParts(a);
    final partsB = parseParts(b);
    for (var i = 0; i < 3; i++) {
      if (partsA[i] != partsB[i]) {
        return partsA[i].compareTo(partsB[i]);
      }
    }
    return 0;
  }

  /// Returns `true` when this release is newer than [installed].
  bool isNewerThan(InstalledAppVersion installed) {
    if (buildNumber > 0 && installed.buildNumber > 0) {
      if (buildNumber != installed.buildNumber) {
        return buildNumber > installed.buildNumber;
      }
      return compareSemver(versionName, installed.versionName) > 0;
    }

    final semverCmp = compareSemver(versionName, installed.versionName);
    if (semverCmp != 0) return semverCmp > 0;
    return buildNumber > installed.buildNumber;
  }

  String get formattedSize {
    if (apkSizeBytes <= 0) return '--';
    final mb = apkSizeBytes / (1024 * 1024);
    if (mb < 1) {
      final kb = (apkSizeBytes / 1024).round();
      return '$kb KB';
    }
    return '${mb.toStringAsFixed(1).replaceAll('.', ',')} MB';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUpdateInfo &&
        other.tagName == tagName &&
        other.versionName == versionName &&
        other.buildNumber == buildNumber &&
        other.releaseNotes == releaseNotes &&
        other.apkDownloadUrl == apkDownloadUrl &&
        other.apkFileName == apkFileName &&
        other.apkSizeBytes == apkSizeBytes &&
        other.sha256DownloadUrl == sha256DownloadUrl &&
        other.htmlUrl == htmlUrl &&
        other.publishedAt == publishedAt;
  }

  @override
  int get hashCode => Object.hash(
        tagName,
        versionName,
        buildNumber,
        releaseNotes,
        apkDownloadUrl,
        apkFileName,
        apkSizeBytes,
        sha256DownloadUrl,
        htmlUrl,
        publishedAt,
      );
}
