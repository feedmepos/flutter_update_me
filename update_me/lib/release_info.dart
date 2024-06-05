import 'package:pub_semver/pub_semver.dart';

import 'package:update_me/installer.dart';

class DownloadProgress {
  int totalSize;
  int downloaded;
  DownloadProgress({
    required this.totalSize,
    required this.downloaded,
  });
}

class ReleaseInfo {
  final bool hasUpdate;
  final String? enforceAt;
  final Version version;
  final String releaseAt;
  final String releaseNote;
  Future<void> Function({
    Function(DownloadProgress)? onProgress,
    Function(BaseInstaller)? onComplete,
  }) startDownload;

  ReleaseInfo({
    required this.hasUpdate,
    this.enforceAt,
    required this.version,
    required this.releaseAt,
    required this.releaseNote,
    required this.startDownload,
  });

  @override
  String toString() {
    return 'ReleaseInfo(hasUpdate: $hasUpdate, enforceAt: $enforceAt, version: $version, releaseAt: $releaseAt, releaseNote: $releaseNote, startDownload: $startDownload)';
  }
}
