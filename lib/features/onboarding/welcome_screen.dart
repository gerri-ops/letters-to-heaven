import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/artwork_assets.dart';
import '../../core/theme/artwork_image.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.cream),
          Align(
            alignment: Alignment.bottomCenter,
            child: ArtworkImage(
              asset: ArtworkAssets.splashHero,
              height: MediaQuery.sizeOf(context).height * 0.42,
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              opacity: 0.9,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: const ArtworkImage(
                        asset: ArtworkAssets.appIcon,
                        height: 72,
                        width: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Letters to Heaven',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.burgundy,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Save the little things before time carries them away.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'The private place that catches a memory before it disappears.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.mutedInk,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => context.push('/first-action'),
                    child: const Text('Begin Gently'),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'This app is not therapy or crisis care.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedOlive,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
