import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:update_me/downloader.dart';
import 'package:update_me/installer.dart';
import 'package:update_me/release_info.dart';

class AppStoreUpdateConfig {
  String? country;
  bool Function(Map<String, dynamic>)? isCompulsory;
}

class PlayStoreUpdateConfig {
  int compulsoryPriority;
  PlayStoreUpdateConfig({
    required this.compulsoryPriority,
  });
}

class MeStoreUpdateConfig {
  Uri releaseUri;
  Map<String, dynamic> deviceMeta;
  MeStoreUpdateConfig({required this.releaseUri, this.deviceMeta = const {}});
}

Future<ReleaseInfo> getMeStoreReleaseInfo(
    {required PackageInfo packageInfo,
    required MeStoreUpdateConfig config}) async {
  /** Sample Response
{
  "enforceAt": null,
  "version": "6.44.0",
  "releaseAt": "2024-05-29T15:29:01Z",
  "releaseNote": "This is an awesome update!",
  "bundleUrl": "https://download.feedmepos.com/pos-6.44.0.exe"
}
   */
  var platform = "unknow";
  if (Platform.isAndroid) platform = 'android';
  if (Platform.isIOS) platform = 'ios';
  if (Platform.isWindows) platform = 'windows';
  final uri = config.releaseUri.replace(
      queryParameters: Map.from({
    ...config.deviceMeta,
    'platform': platform,
    'appId': packageInfo.packageName,
  }));
  final res = await http.get(uri);
  if (res.statusCode != 200) {
    throw Exception('Invalid meStore Uri, ${res.body}');
  }

  final decoded = jsonDecode(res.body);
  final currentVersion = Version.parse(packageInfo.version);
  final releaseVersion = Version.parse(decoded['version']);

  return ReleaseInfo(
    hasUpdate: releaseVersion > currentVersion,
    enforceAt: decoded['enforceAt'],
    version: releaseVersion,
    releaseAt: decoded['releaseAt'],
    releaseNote: decoded['releaseNote'],
    startDownload: ({onProgress, onComplete}) async {
      if (Platform.isAndroid || Platform.isWindows) {
        final String fileName =
            Platform.isAndroid ? 'feedme.apk' : 'feedme.exe';

        downloadFile(
          Uri.parse(decoded['bundleUrl']),
          filename: fileName,
          onChunk: onProgress,
          onComplete: (file) {
            if (Platform.isAndroid) {
              return onComplete?.call(ApkInstaller(installerFile: file));
            }
            if (Platform.isWindows) {
              return onComplete?.call(ExeInstaller(installerFile: file));
            }
            throw Exception('Unknows application to install');
          },
        );
      }
    },
  );
}

Future<ReleaseInfo> getPlayStoreReleaseInfo(
    PlayStoreUpdateConfig config) async {
  final info = await InAppUpdate.checkForUpdate();
  final compulsory = info.updatePriority >= config.compulsoryPriority;
  return ReleaseInfo(
    hasUpdate: info.updateAvailability == UpdateAvailability.updateAvailable,
    enforceAt: compulsory ? DateTime.now().toIso8601String() : null,
    version: Version(0, 0, 0),
    releaseAt: "",
    releaseNote: "",
    startDownload: ({onProgress, onComplete}) async {
      if (compulsory) {
        await InAppUpdate.performImmediateUpdate();
      } else {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    },
  );
}

Future<ReleaseInfo> getAppStoreReleaseInfo({
  required PackageInfo packageInfo,
  required AppStoreUpdateConfig config,
}) async {
  /**
 Sample Response
 {
    "resultCount": 1,
    "results": [
        {
            "screenshotUrls": [],
            "ipadScreenshotUrls": [],
            "appletvScreenshotUrls": [],
            "artworkUrl60": "",
            "artworkUrl512": "",
            "artworkUrl100": "",
            "artistViewUrl": "",
            "isGameCenterEnabled": false,
            "features": [
                "iosUniversal"
            ],
            "supportedDevices": [
                "iPhone5s-iPhone5s",
            ],
            "advisories": [],
            "kind": "software",
            "averageUserRatingForCurrentVersion": 5,
            "averageUserRating": 5,
            "trackCensoredName": "FeedMe POS V6",
            "languageCodesISO2A": [
                "EN"
            ],
            "fileSizeBytes": "216399872",
            "formattedPrice": "Free",
            "contentAdvisoryRating": "4+",
            "userRatingCountForCurrentVersion": 1,
            "trackViewUrl": "https://apps.apple.com/my/app/feedme-pos-v6/id1613318772?uo=4",
            "trackContentRating": "4+",
            "currentVersionReleaseDate": "2024-05-29T13:29:31Z",
            "price": 0.00,
            "description": "FeedMe POS. Best F&B Point of sale system in Malaysia.",
            "sellerName": "NEWTONS TECH SDN. BHD.",
            "releaseDate": "2022-03-09T08:00:00Z",
            "currency": "MYR",
            "releaseNotes": "[NEW] iOS able to export logs and logs will send to remote\n[BUGFIX] Remove voucher did not remove the discount\n[BUGFIX] Order display system did not group delivery platform properly",
            "primaryGenreName": "Business",
            "primaryGenreId": 6000,
            "isVppDeviceBasedLicensingEnabled": true,
            "bundleId": "cc.feedme.pos",
            "genreIds": [
                "6000"
            ],
            "trackId": 1613318772,
            "trackName": "FeedMe POS V6",
            "minimumOsVersion": "11.0",
            "genres": [
                "Business"
            ],
            "artistId": 1413635997,
            "artistName": "NEWTONS TECH SDN. BHD.",
            "version": "6.44.0",
            "wrapperType": "software",
            "userRatingCount": 1
        }
    ]
}
         */
  final res = await http.get(Uri.parse(
      'https://itunes.apple.com/lookup?id=${packageInfo.packageName}&country=${config.country ?? ""}'));
  if (res.statusCode == 200) {
    final decoded = jsonDecode(res.body);
    if (decoded['results'].length < 0) {
      throw Exception('no app found in app store');
    }
    final versionInfo = decoded['results'][0];
    final currentVersion = Version.parse(packageInfo.version);
    final remoteVersion = Version.parse(versionInfo['version']);
    final appId = decoded['trackId'];
    return ReleaseInfo(
        hasUpdate: remoteVersion > currentVersion,
        // TODO: decide how ios store perform enforcement
        enforceAt: null,
        version: remoteVersion,
        releaseAt: versionInfo['currentVersionReleaseDate'],
        releaseNote: versionInfo['releaseNotes'],
        startDownload: ({onProgress, onComplete}) async {
          final appStoreUri =
              Uri.parse('itms-apps://itunes.apple.com/app/$appId');
          if (await canLaunchUrl(appStoreUri)) {
            launchUrl(appStoreUri);
          }
        });
  } else {
    throw Exception(
        "Fail to fetch lookup API. Status code: ${res.statusCode}.");
  }
}
