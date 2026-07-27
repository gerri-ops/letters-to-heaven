import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'artwork_assets.dart';
import 'artwork_image.dart';

/// App bar with optional dogwood under the title and a parchment intro stripe.
class LettersAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LettersAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.dogwoodHeight = 72,
    this.showDogwood = true,
    this.intro,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final double dogwoodHeight;
  final bool showDogwood;
  final String? intro;

  static const _dogwoodBottomPad = 10.0;
  static const _introHeight = 52.0;

  double get _dogwoodBlockHeight =>
      showDogwood ? dogwoodHeight + _dogwoodBottomPad : 0;

  double get _introBlockHeight => intro == null ? 0 : _introHeight;

  @override
  Size get preferredSize {
    final extra = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(
      kToolbarHeight + _dogwoodBlockHeight + _introBlockHeight + extra,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasExtras =
        showDogwood || intro != null || bottom != null;
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: hasExtras
          ? PreferredSize(
              preferredSize: Size.fromHeight(
                _dogwoodBlockHeight +
                    _introBlockHeight +
                    (bottom?.preferredSize.height ?? 0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showDogwood) ...[
                    ArtworkImage(
                      asset: ArtworkAssets.dogwood,
                      height: dogwoodHeight,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: _dogwoodBottomPad),
                  ],
                  if (intro != null)
                    Container(
                      width: double.infinity,
                      color: AppColors.parchment,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Text(
                        intro!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedOlive,
                            ),
                      ),
                    ),
                  ?bottom,
                ],
              ),
            )
          : null,
    );
  }
}
