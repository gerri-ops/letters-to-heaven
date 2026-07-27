import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/artwork_assets.dart';
import '../../core/theme/artwork_image.dart';
import '../../core/theme/letters_app_bar.dart';
import '../capture/quick_capture_screen.dart';

/// Screen 5 — no streaks / no pressure (major product differentiator).
class PacePromiseScreen extends StatelessWidget {
  const PacePromiseScreen({super.key});

  Future<void> _continue(BuildContext context) async {
    final app = AppScope.of(context);
    await app.acceptPacePromise();
    if (!app.onboardingComplete) {
      await app.completeOnboarding();
    }
    if (!context.mounted) {
      return;
    }
    final intent = app.onboardingIntent;
    switch (intent) {
      case OnboardingIntent.sentence:
        context.go('/entry/new?type=letter');
      case OnboardingIntent.detail:
        context.go('/entry/new?type=memory');
      case OnboardingIntent.photo:
        context.go('/capture?mode=${QuickCaptureMode.photo.name}');
      case OnboardingIntent.voice:
        context.go('/voice-keepsakes');
      case OnboardingIntent.lookAround:
      case null:
      default:
        context.go('/shell/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('There is nothing to keep up with.'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ArtworkImage(
              asset: ArtworkAssets.dogwood,
              height: 72,
              fit: BoxFit.contain,
              opacity: 0.85,
            ),
            const SizedBox(height: 20),
            Text(
              'No daily streaks. No missed-day messages. No progress bars or '
              'grief scores. Write once, return often, or step away for months—'
              'that does not mean the app failed.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.mutedInk,
                height: 1.45,
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => _continue(context),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
