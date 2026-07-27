import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/retention/retention_copy.dart';
import '../../core/retention/retention_cue_builder.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../capture/quick_capture_screen.dart';
import '../prompts/optional_prompt_sheet.dart';

/// Calm optional return cues — no badges, streaks, or scores.
class HomeRetentionSection extends StatelessWidget {
  const HomeRetentionSection({
    super.key,
    required this.cues,
    this.onChanged,
  });

  final List<RetentionCue> cues;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    if (cues.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          RetentionCopy.homeSectionTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          RetentionCopy.homeSectionSupporting,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.mutedOlive,
          ),
        ),
        const SizedBox(height: 10),
        for (final cue in cues.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.parchment,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _onTap(context, cue),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(_iconFor(cue.kind), color: AppColors.burgundy, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cue.title,
                              style: theme.textTheme.titleSmall,
                            ),
                            if (cue.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                cue.subtitle!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.mutedInk,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.mutedOlive),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.push('/retention'),
            child: const Text('Adjust return options'),
          ),
        ),
      ],
    );
  }

  IconData _iconFor(RetentionCueKind kind) {
    switch (kind) {
      case RetentionCueKind.draft:
        return Icons.edit_note_outlined;
      case RetentionCueKind.memoryQuestion:
        return Icons.lightbulb_outline;
      case RetentionCueKind.saveBeforeForget:
        return Icons.bookmark_border;
      case RetentionCueKind.importPhoto:
        return Icons.photo_outlined;
      case RetentionCueKind.monthlyKeepsake:
        return Icons.menu_book_outlined;
      case RetentionCueKind.resurface:
        return Icons.favorite_border;
      case RetentionCueKind.remembrance:
        return Icons.calendar_today_outlined;
      case RetentionCueKind.familyContribution:
        return Icons.people_outline;
    }
  }

  Future<void> _onTap(BuildContext context, RetentionCue cue) async {
    final app = AppScope.of(context);
    final now = DateTime.now();
    switch (cue.kind) {
      case RetentionCueKind.draft:
        if (cue.entryId != null) {
          context.push('/entry/${cue.entryId}/edit');
        }
      case RetentionCueKind.memoryQuestion:
        final key = app.memoryQuestionCadence == MemoryQuestionCadence.weekly
            ? _yearWeek(now)
            : _yearMonth(now);
        await app.markMemoryQuestionShown(key);
        if (context.mounted) {
          await showOptionalPromptSheet(context);
          onChanged?.call();
        }
      case RetentionCueKind.saveBeforeForget:
        context.push('/capture?from=widget');
      case RetentionCueKind.importPhoto:
        context.push('/capture?mode=${QuickCaptureMode.photo.name}');
      case RetentionCueKind.monthlyKeepsake:
        await app.markKeepsakePreviewShown(_yearMonth(now));
        if (context.mounted) {
          context.push('/keepsake-preview');
          onChanged?.call();
        }
      case RetentionCueKind.resurface:
        if (cue.entryId != null) {
          final open = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Open this memory?'),
              content: const Text(
                'Only if you want to. You can close it anytime.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Not now'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Open'),
                ),
              ],
            ),
          );
          if (open == true && context.mounted) {
            context.push('/entry/${cue.entryId}');
          }
        }
      case RetentionCueKind.remembrance:
        context.push('/reminders');
      case RetentionCueKind.familyContribution:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Family contributions will appear here when Family Circle is available.',
            ),
          ),
        );
    }
  }

  static String _yearMonth(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static String _yearWeek(DateTime d) {
    final start = DateTime(d.year);
    final dayOfYear = d.difference(start).inDays;
    final week = 1 + dayOfYear ~/ 7;
    return '${d.year}-W${week.toString().padLeft(2, '0')}';
  }
}
