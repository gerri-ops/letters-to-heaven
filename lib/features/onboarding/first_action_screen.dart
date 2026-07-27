import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';

/// Screen 2 — choose what feels possible before naming or account.
class FirstActionScreen extends StatelessWidget {
  const FirstActionScreen({super.key});

  Future<void> _choose(BuildContext context, String intent) async {
    await AppScope.of(context).setOnboardingIntent(intent);
    if (context.mounted) {
      context.push('/memorial-setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('What feels possible right now?'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text(
            'There is no wrong place to start.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedInk,
                ),
          ),
          const SizedBox(height: 16),
          _ChoiceTile(
            icon: Icons.edit_outlined,
            title: 'Write one sentence',
            onTap: () => _choose(context, OnboardingIntent.sentence),
          ),
          _ChoiceTile(
            icon: Icons.auto_stories_outlined,
            title: 'Save a small detail',
            onTap: () => _choose(context, OnboardingIntent.detail),
          ),
          _ChoiceTile(
            icon: Icons.add_photo_alternate_outlined,
            title: 'Add a photo',
            onTap: () => _choose(context, OnboardingIntent.photo),
          ),
          _ChoiceTile(
            icon: Icons.mic_none,
            title: 'Record a voice note',
            onTap: () => _choose(context, OnboardingIntent.voice),
          ),
          _ChoiceTile(
            icon: Icons.explore_outlined,
            title: 'Look around first',
            onTap: () => _choose(context, OnboardingIntent.lookAround),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.burgundy),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.mutedOlive),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
