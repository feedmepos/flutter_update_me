import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:update_me/release_info.dart';

downloadFile(
  Uri uri, {
  required String filename,
  Function(DownloadProgress)? onChunk,
  Function(File)? onComplete,
}) async {
  var request = http.Request('GET', uri);
  var response = request.send();
  String dir = (await getTemporaryDirectory()).path;

  List<List<int>> chunks = [];
  int downloaded = 0;

  response.asStream().listen((http.StreamedResponse r) {
    final size = r.contentLength!;
    r.stream.listen((List<int> chunk) {
      onChunk?.call(DownloadProgress(downloaded: downloaded, totalSize: size));
      // Display percentage of completion
      chunks.add(chunk);
      downloaded += chunk.length;
    }, onDone: () async {
      // Save the file
      File file = File('$dir/$filename');
      final Uint8List bytes = Uint8List(size);
      int offset = 0;
      for (List<int> chunk in chunks) {
        bytes.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }
      await file.writeAsBytes(bytes);
      onComplete?.call(file);
    });
  });
}
