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
  final bool isCompulsory;
  final Version version;
  final String releaseDate;
  final String releaseNote;
  Future<void> Function(
    Function(DownloadProgress)? onProgress,
    Function(BaseInstaller)? onComplete,
  ) startDownload;

  ReleaseInfo({
    required this.hasUpdate,
    required this.isCompulsory,
    required this.version,
    required this.releaseDate,
    required this.releaseNote,
    required this.startDownload,
  });
}
