import 'package:flutter/material.dart';
import 'package:update_me/installer.dart';
import 'package:update_me/release_info.dart';
import 'package:update_me/update_me.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ReleaseInfo? _releaseInfo;
  DownloadProgress? _progress;
  BaseInstaller? _installer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                onPressed: () async {
                  var result = await checkForUpdate(
                      meStore: MeStoreUpdateConfig(
                          deviceMeta: {'restaurantId': 'ab'},
                          releaseUri: Uri.parse(
                              "https://vitame.feedme-dev.workers.dev/version")));
                  setState(() {
                    _releaseInfo = result;
                  });
                },
                child: const Text('Check for Update')),
            if (_releaseInfo != null) ...[
              Text(_releaseInfo.toString()),
              ElevatedButton(
                onPressed: () {
                  _releaseInfo!.startDownload(onProgress: (p) {
                    setState(() {
                      _progress = p;
                    });
                  }, onComplete: (c) {
                    setState(() {
                      _installer = c;
                    });
                  });
                },
                child: const Text('Download'),
              )
            ],
            if (_progress != null)
              Text('${_progress!.downloaded} / ${_progress!.totalSize}'),
            if (_installer != null)
              ElevatedButton(
                  onPressed: () {
                    _installer!.install(() => null);
                  },
                  child: const Text('install'))
          ],
        ),
      ),
    );
  }
}
