import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'local_file_io.dart' if (dart.library.html) 'local_file_web.dart' as io;

/// Copies picked images into durable app storage (not the gallery temp cache).
///
/// On web, the picker path (often a blob URL) is kept as-is.
class LocalMediaStore {
  LocalMediaStore();

  static const _uuid = Uuid();

  /// Persist a picked image. Returns a path/URL to store on the entry.
  Future<String> persistImage({
    required String sourcePath,
    String? ownerUid,
    String? preferredName,
  }) {
    return persistFile(
      sourcePath: sourcePath,
      ownerUid: ownerUid,
      preferredName: preferredName,
      defaultExtension: '.jpg',
    );
  }

  /// Persist any local file (image, audio, etc.) into app media storage.
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
        path.startsWith('blob:')) {
      return true;
    }
    if (kIsWeb) {
      return false;
    }
    return io.fileExists(path);
  }
}
