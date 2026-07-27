import 'package:flutter/material.dart';

import 'local_path_image_helpers.dart';
import 'local_path_image_io.dart'
    if (dart.library.html) 'local_path_image_web.dart' as impl;

/// Shows a local file path on IO, or a network/blob URL on web.
class LocalPathImage extends StatelessWidget {
  const LocalPathImage({
    required this.path,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = impl.buildLocalPathImage(
      path: path,
      width: width,
      height: height,
      fit: fit,
    );
    if (borderRadius == null) {
      return image;
    }
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
