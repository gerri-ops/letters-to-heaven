import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/entry_helpers.dart';
import '../../data/models/models.dart';
import 'keepsake_catalog.dart';

/// Lightweight Flutter fallback when web PDF.js preview fails.
class KeepsakeTemplateFallback extends StatelessWidget {
  const KeepsakeTemplateFallback({
    super.key,
    required this.memorial,
    required this.theme,
    required this.bookType,
    this.error,
  });

  final Memorial memorial;
  final ExportTheme theme;
  final KeepsakeBookType bookType;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final samples = KeepsakePreviewSamples.templateEntries(memorial);
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (error != null) ...[
          Text(
            'Live PDF preview is unavailable in this browser. '
            'Here is the template layout instead.',
            style: textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: 12),
        ],
        _PaperPage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bookType.shortLabel.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.burgundy,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'In memory of ${memorial.displayName}',
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.burgundy,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                theme.label,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedOlive,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                theme.blurb,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedInk,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final entry in samples) ...[
          _PaperPage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entryTypeLabel(entry.type).toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.burgundy,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.burgundy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.body,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _PaperPage extends StatelessWidget {
  const _PaperPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.softBlush),
      ),
      child: child,
    );
  }
}
