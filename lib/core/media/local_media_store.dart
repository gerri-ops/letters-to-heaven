import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'image_webp_processor.dart';
import 'local_file_io.dart' if (dart.library.html) 'local_file_web.dart' as io;
import 'stored_media_uri.dart';

/// Copies picked images into durable app storage as WebP only.
class LocalMediaStore {
  LocalMediaStore();

  static const _uuid = Uuid();
  final _processor = ImageWebpProcessor();

  /// Persist a picked image. Returns a path/URL to store on the entry.
  Future<String> persistImage({
    required String sourcePath,
    String? ownerUid,
    String? preferredName,
  }) async {
    final raw = await _readSourceBytes(sourcePath);
    final webp = _processor.processForStorage(raw);

    if (kIsWeb) {
      return StoredMediaUri.dataUrlFromWebp(webp);
    }

    final docs = await getApplicationDocumentsDirectory();
    final rootPath = p.join(docs.path, 'letters_to_heaven_media');
    await io.ensureDirectory(rootPath);
    final ownerPath = p.join(rootPath, ownerUid ?? 'local');
    await io.ensureDirectory(ownerPath);

    final baseName = preferredName != null && preferredName.isNotEmpty
        ? p.basenameWithoutExtension(preferredName)
        : _uuid.v4();
    final destPath = p.join(ownerPath, '$baseName.webp');
    await io.writeBytes(destPath, webp);
    return destPath;
  }

  /// Persist any local file (audio, etc.) into app media storage.
  Future<String> persistFile({
    required String sourcePath,
    String? ownerUid,
    String? preferredName,
    String defaultExtension = '.bin',
  }) async {
    if (kIsWeb) {
      return sourcePath;
    }

    if (!await io.fileExists(sourcePath)) {
      throw StateError('Source file not found: $sourcePath');
    }

    final docs = await getApplicationDocumentsDirectory();
    final rootPath = p.join(docs.path, 'letters_to_heaven_media');
    await io.ensureDirectory(rootPath);
    final ownerPath = p.join(rootPath, ownerUid ?? 'local');
    await io.ensureDirectory(ownerPath);

    final ext = p.extension(sourcePath).isEmpty
        ? defaultExtension
        : p.extension(sourcePath).toLowerCase();
    final name = preferredName ?? '${_uuid.v4()}$ext';
    final destPath = p.join(ownerPath, name);
    await io.copyFile(sourcePath, destPath);
    return destPath;
  }

  Future<bool> exists(String? path) async {
    if (path == null || path.isEmpty) {
      return false;
    }
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:') ||
        path.startsWith('data:')) {
      return true;
    }
    if (kIsWeb) {
      return false;
    }
    return io.fileExists(path);
  }

  Future<Uint8List> _readSourceBytes(String sourcePath) async {
    if (kIsWeb) {
      return io.readBytes(sourcePath);
    }
    if (!await io.fileExists(sourcePath)) {
      throw StateError('Source file not found: $sourcePath');
    }
    return io.readBytes(sourcePath);
  }
}
