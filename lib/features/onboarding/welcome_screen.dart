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
                  const Center(
                    child: CardinalAccent(size: 88),
                  ),
                  const SizedBox(height: 12),
                  const ArtworkImage(
                    asset: ArtworkAssets.dogwood,
                    height: 132,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Letters to Heaven',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.burgundy,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Save the little things before time carries them away.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
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
