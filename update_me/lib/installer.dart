import 'dart:io';

import 'package:app_installer/app_installer.dart';

abstract class BaseInstaller {
  File installerFile;
  BaseInstaller({
    required this.installerFile,
  });
  Future<void> install(Function() exitApplication);
}

class ApkInstaller extends BaseInstaller {
  ApkInstaller({required super.installerFile});

  @override
  install(Function() exitApplication) async {
    await AppInstaller.installApk(installerFile.path);
    exitApplication();
  }
}

class ExeInstaller extends BaseInstaller {
  ExeInstaller({required super.installerFile});

  @override
  install(Function() exitApplication) async {
    final List<String> args = ['/S'];
    await Process.start(installerFile.path, args,
        runInShell: true, mode: ProcessStartMode.detached);
    exitApplication();
  }
}
