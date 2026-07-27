import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';
import '../voice/voice_keepsake_models.dart';
import 'keepsake_catalog.dart';

class KeepsakeScreen extends StatelessWidget {
  const KeepsakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final premium = AppScope.of(context).premium;
    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('Keepsake'),
        intro:
            'The space between a private journal and a finished family keepsake.',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.parchment,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.cardinalRed.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Keepsake Builder',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  KeepsakePreviewCopy.headline,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  KeepsakePreviewCopy.supporting,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedInk,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => context.push(
                    premium ? '/export' : '/keepsake-preview',
                  ),
                  child: Text(
                    premium
                        ? 'Open Keepsake Builder'
                        : 'Preview your memory book',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Book formats',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          for (final book in KeepsakeBookType.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '·  ${book.title}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedInk,
                    ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Styles: Cardinal Garden · Soft Neutral · Ink-Saving Simple',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedOlive,
                ),
          ),
          const SizedBox(height: 16),
          _LinkTile(
            icon: Icons.graphic_eq,
            title: 'Voice Keepsakes',
            subtitle: voicePremiumHero,
            onTap: () => context.push('/voice-keepsakes'),
          ),
          _LinkTile(
            icon: Icons.timeline,
            title: 'Timeline',
            subtitle: 'Browse entries by date',
            onTap: () => context.push('/timeline'),
          ),
          _LinkTile(
            icon: Icons.search,
            title: 'Search',
            subtitle: 'Find words across your journal',
            onTap: () => context.push('/search'),
          ),
          _LinkTile(
            icon: Icons.description_outlined,
            title: 'Plain-text & data export',
            subtitle: 'Always free on Basic',
            onTap: () => context.push('/data-rights'),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.group_outlined),
              title: const Text('Family circle'),
              subtitle: Text(
                'Invite loved ones to contribute—Premium, when released.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedInk,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
