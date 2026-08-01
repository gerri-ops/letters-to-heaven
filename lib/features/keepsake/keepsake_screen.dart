import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';
import 'keepsake_catalog.dart';

class KeepsakeScreen extends StatelessWidget {
  const KeepsakeScreen({super.key});

  void _openBook(BuildContext context, ExportTheme theme) {
    final premium = AppScope.of(context).premium;
    final themeParam = Uri.encodeComponent(theme.name);
    context.push(
      premium
          ? '/export?theme=$themeParam'
          : '/keepsake-preview?theme=$themeParam',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final premium = AppScope.of(context).premium;
    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('Keepsake'),
        showDogwood: false,
        intro:
            'Create a printable keepsake from what you have already saved—this is what makes the app unique.',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            KeepsakePreviewCopy.headline,
            style: theme.textTheme.titleLarge?.copyWith(height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            KeepsakePreviewCopy.supporting,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedInk,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => _openBook(context, ExportTheme.journalPdf),
            child: Text(
              premium ? 'Open Keepsake Builder' : 'Preview a keepsake',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Book formats',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          for (final style in ExportTheme.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(style.label),
              subtitle: Text(style.blurb),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openBook(context, style),
            ),
          const SizedBox(height: 22),
          Text(
            'Also here',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
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
            icon: Icons.graphic_eq,
            title: 'Voice Keepsakes',
            subtitle: 'Private voice notes that can appear in your print',
            onTap: () => context.push('/voice-keepsakes'),
          ),
          _LinkTile(
            icon: Icons.description_outlined,
            title: 'Plain-text & data export',
            subtitle: 'Always free on Basic',
            onTap: () => context.push('/data-rights'),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.burgundy),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
