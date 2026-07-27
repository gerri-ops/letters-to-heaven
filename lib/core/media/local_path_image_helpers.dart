import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Widget brokenLocalImage({double? width, double? height}) => Container(
      width: width,
      height: height,
      color: Colors.black12,
      child: const Icon(Icons.broken_image),
    );

bool isNetworkLikePath(String path) =>
    kIsWeb ||
    path.startsWith('http://') ||
    path.startsWith('https://') ||
    path.startsWith('blob:');
