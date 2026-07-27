import 'package:flutter/material.dart';

import 'local_path_image_helpers.dart';

Widget buildLocalPathImage({
  required String path,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  return Image.network(
    path,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, _, _) => brokenLocalImage(width: width, height: height),
  );
}
