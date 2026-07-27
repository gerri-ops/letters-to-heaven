import 'dart:io';

import 'dart:typed_data';

Future<bool> fileExists(String path) => File(path).exists();

Future<void> ensureDirectory(String path) async {
  final dir = Directory(path);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}

Future<void> copyFile(String source, String dest) async {
  await File(source).copy(dest);
}

Future<Uint8List> readBytes(String path) => File(path).readAsBytes();

Future<void> writeBytes(String path, List<int> bytes) async {
  await File(path).writeAsBytes(bytes);
}

File fileFromPath(String path) => File(path);
