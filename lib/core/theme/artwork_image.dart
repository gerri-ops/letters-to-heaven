import 'package:flutter/material.dart';

import '../theme/artwork_assets.dart';

/// Loads a bundled artwork asset; fails soft if a file is missing.
class ArtworkImage extends StatelessWidget {
  const ArtworkImage({
    required this.asset,
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.opacity = 1,
  });

  final String asset;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Alignment alignment;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Image.asset(
        asset,
        height: height,
        width: width,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, _, _) => SizedBox(height: height, width: width),
      ),
    );
  }
}

/// Small cardinal motif for list headers / empty states.
class CardinalAccent extends StatelessWidget {
  const CardinalAccent({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ArtworkImage(
      asset: ArtworkAssets.cardinal,
      height: size,
      width: size,
      fit: BoxFit.contain,
    );
  }
}
