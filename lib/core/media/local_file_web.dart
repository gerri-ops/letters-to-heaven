import 'dart:typed_data';

import 'package:http/http.dart' as http;

Future<bool> fileExists(String path) async =>
    path.startsWith('blob:') ||
    path.startsWith('http://') ||
    path.startsWith('https://');

Future<void> ensureDirectory(String path) async {}

Future<void> copyFile(String source, String dest) async {}

Future<Uint8List> readBytes(String path) async {
  final response = await http.get(Uri.parse(path));
  if (response.statusCode >= 400) {
    throw StateError('Could not read media at $path');
  }
  return response.bodyBytes;
}

Future<void> writeBytes(String path, List<int> bytes) async {}

Never fileFromPath(String path) =>
    throw UnsupportedError('Local files are not available on web.');
