/// Limits for user-uploaded images (local + cloud).
abstract final class MediaUploadLimits {
  /// Reject originals larger than this before processing.
  static const int maxSourceBytes = 12 * 1024 * 1024;

  static const int maxEdgePixels = 2048;
  static const int webpQuality = 85;
  static const String webpMimeType = 'image/webp';
}
