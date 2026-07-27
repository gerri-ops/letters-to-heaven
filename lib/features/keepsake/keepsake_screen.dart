import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';
import 'keepsake_catalog.dart';

class KeepsakeScreen extends StatelessWidget {
  const KeepsakeScreen({super.key});

  void _openExport(BuildContext context, ExportTheme theme) {
    final premium = AppScope.of(context).premium;
    final themeParam = Uri.encodeComponent(theme.name);
    context.push(
      premium
          ? '/export?theme=$themeParam'
          : '/keepsake-preview?theme=$themeParam',
    );
  }

  IconData _iconFor(ExportTheme theme) {
    switch (theme) {
      case ExportTheme.journalPdf:
        return Icons.menu_book_outlined;
      case ExportTheme.simple:
        return Icons.description_outlined;
      case ExportTheme.inkSaver:
        return Icons.invert_colors_off_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final premium = AppScope.of(context).premium;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('Keepsake'),
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
          Text(
            'Choose an export',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          for (final style in ExportTheme.values) ...[
            _ExportStyleTile(
              icon: _iconFor(style),
              title: style.label,
              subtitle: style.blurb,
              onTap: () => _openExport(context, style),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          FilledButton(
            onPressed: () => _openExport(context, ExportTheme.journalPdf),
            child: Text(
              premium ? 'Open Keepsake Builder' : 'Preview a keepsake',
            ),
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

class _ExportStyleTile extends StatelessWidget {
  const _ExportStyleTile({
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
    return Material(
      color: AppColors.parchment,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.cardinalRed.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.burgundy, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedInk,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.mutedOlive),
            ],
          ),
        ),
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
