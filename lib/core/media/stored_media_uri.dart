import 'dart:convert';
import 'dart:typed_data';

import 'media_upload_limits.dart';

/// Persists WebP bytes for web (data URL) and native (file path via caller).
abstract final class StoredMediaUri {
  static String dataUrlFromWebp(Uint8List webpBytes) {
    final encoded = base64Encode(webpBytes);
    return 'data:${MediaUploadLimits.webpMimeType};base64,$encoded';
  }

  static bool isDataUrl(String path) => path.startsWith('data:');

  static Uint8List readDataUrl(String dataUrl) {
    final comma = dataUrl.indexOf(',');
    if (comma < 0) {
      throw StateError('Invalid data URL');
    }
    return Uint8List.fromList(base64Decode(dataUrl.substring(comma + 1)));
  }
}
