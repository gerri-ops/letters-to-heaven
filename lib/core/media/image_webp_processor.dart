import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'media_upload_limits.dart';

class ImageProcessingException implements Exception {
  ImageProcessingException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Normalizes photos to a single WebP asset for storage efficiency.
class ImageWebpProcessor {
  Uint8List processForStorage(Uint8List sourceBytes) {
    if (sourceBytes.length > MediaUploadLimits.maxSourceBytes) {
      throw ImageProcessingException(
        'That photo is too large. Please choose an image under '
        '${MediaUploadLimits.maxSourceBytes ~/ (1024 * 1024)} MB.',
      );
    }
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      throw ImageProcessingException('Could not read that image.');
    }
    var working = decoded;
    final longest = working.width > working.height ? working.width : working.height;
    if (longest > MediaUploadLimits.maxEdgePixels) {
      if (working.width >= working.height) {
        working = img.copyResize(
          working,
          width: MediaUploadLimits.maxEdgePixels,
        );
      } else {
        working = img.copyResize(
          working,
          height: MediaUploadLimits.maxEdgePixels,
        );
      }
    }
    return Uint8List.fromList(img.encodeWebP(working));
  }
}
