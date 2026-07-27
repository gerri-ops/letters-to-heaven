import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../data/models/models.dart';
import '../../firebase_options.dart';
import '../firebase/auth_service.dart';
import '../firebase/firebase_bootstrap.dart';
import 'local_file_io.dart' if (dart.library.html) 'local_file_web.dart' as io;

/// Uploads entry media via Firebase Storage REST.
class CloudMediaUploader {
  CloudMediaUploader._();
  static final instance = CloudMediaUploader._();

  final http.Client _client = http.Client();

  bool get isAvailable =>
      FirebaseBootstrap.isReady && AuthService.instance.currentUser != null;

  /// Returns the storage object path on success.
  Future<String> upload(MediaAttachment media) async {
    if (!FirebaseBootstrap.isReady) {
      throw StateError('Firebase is not initialized.');
    }
    final uid = AuthService.instance.firebaseUid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in before uploading photos.');
    }
    if (media.ownerUid != uid) {
      debugPrint(
        'Media ownerUid ${media.ownerUid} differs from auth uid $uid; '
        'uploading under auth uid.',
      );
    }

    final bytes = await io.readBytes(media.localPath);
    if (bytes.isEmpty) {
      throw StateError('Local media file missing: ${media.localPath}');
    }

    final safeName = _safeFileName(
      media.fileName ?? p.basename(media.localPath),
    );
    final objectPath =
        'users/$uid/entries/${media.entryId}/${media.id}_$safeName';
    final encodedPath = Uri.encodeComponent(objectPath);
    final uri = Uri.parse(
      'https://firebasestorage.googleapis.com/v0/b/'
      '${FirebaseConfig.storageBucket}/o'
      '?uploadType=media&name=$encodedPath',
    );

    final idToken = await AuthService.instance.getValidIdToken();
    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Firebase $idToken',
        'Content-Type': media.mimeType ?? _guessMime(safeName),
      },
      body: bytes,
    );
    if (response.statusCode >= 400) {
      throw StateError(
        'Storage upload failed (${response.statusCode}): ${response.body}',
      );
    }
    return objectPath;
  }

  String _safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    return cleaned.isEmpty ? 'photo.jpg' : cleaned;
  }

  String _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }
}
