import 'package:package_info_plus/package_info_plus.dart';
import 'package:update_me/src/store.dart';

export 'package:update_me/src/store.dart'
    show MeStoreUpdateConfig, AppStoreUpdateConfig, PlayStoreUpdateConfig;

checkForUpdate({
  AppStoreUpdateConfig? appStore,
  PlayStoreUpdateConfig? playStore,
  MeStoreUpdateConfig? meStore,
}) async {
  PackageInfo info = await PackageInfo.fromPlatform();
  final installerStore = info.installerStore;
  if (installerStore == "com.android.vending") {
    return getPlayStoreReleaseInfo(
        playStore ?? PlayStoreUpdateConfig(compulsoryPriority: 0));
  }
  if (installerStore == 'com.apple') {
    return getAppStoreReleaseInfo(
        packageInfo: info, config: AppStoreUpdateConfig());
  }
  return getMeStoreReleaseInfo(
      packageInfo: info,
      config:
          meStore ?? MeStoreUpdateConfig(releaseUri: Uri.parse('example.com')));
}
