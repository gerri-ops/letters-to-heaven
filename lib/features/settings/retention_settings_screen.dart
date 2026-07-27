import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/retention/retention_copy.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';

/// User controls for episodic return — never streaks or scores.
class RetentionSettingsScreen extends StatelessWidget {
  const RetentionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const LettersAppBar(
        title: Text(RetentionCopy.settingsTitle),
        intro: RetentionCopy.settingsIntro,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              RetentionCopy.principle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedInk,
                height: 1.4,
              ),
            ),
          ),
          ListTile(
            title: const Text('Memory question'),
            subtitle: Text(_cadenceLabel(app.memoryQuestionCadence)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickCadence(context),
          ),
          SwitchListTile(
            title: const Text('Monthly keepsake preview'),
            subtitle: const Text(
              'A quiet optional peek once a month—never a deadline',
            ),
            value: app.monthlyKeepsakePreview,
            onChanged: (v) => app.setMonthlyKeepsakePreview(v),
          ),
          ListTile(
            title: const Text('Memory resurfacing'),
            subtitle: Text(_resurfacingLabel(app.memoryResurfacingMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickResurfacing(context),
          ),
          ListTile(
            title: const Text('Birthday & anniversary reminders'),
            subtitle: const Text('Optional remembrance dates'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/reminders'),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Home-screen widget',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.burgundy,
              ),
            ),
          ),
          ListTile(
            title: const Text(RetentionCopy.widgetLabel),
            subtitle: const Text(RetentionCopy.widgetDescription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/capture?from=widget'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Add this widget from your phone’s widget gallery when available. '
              'It only opens a private capture—no streaks, no counts.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.mutedOlive,
                height: 1.35,
              ),
            ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'We never use',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.burgundy,
              ),
            ),
          ),
          for (final item in RetentionCopy.avoidPatterns)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              child: Text(
                '· $item',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedOlive,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _cadenceLabel(MemoryQuestionCadence c) {
    switch (c) {
      case MemoryQuestionCadence.off:
        return RetentionCopy.cadenceOff;
      case MemoryQuestionCadence.weekly:
        return RetentionCopy.cadenceWeekly;
      case MemoryQuestionCadence.monthly:
        return RetentionCopy.cadenceMonthly;
    }
  }

  String _resurfacingLabel(MemoryResurfacingMode m) {
    switch (m) {
      case MemoryResurfacingMode.off:
        return RetentionCopy.resurfacingOff;
      case MemoryResurfacingMode.favoritesWhenAsked:
        return RetentionCopy.resurfacingFavorites;
      case MemoryResurfacingMode.gentleWhenAsked:
        return RetentionCopy.resurfacingGentle;
    }
  }

  Future<void> _pickCadence(BuildContext context) async {
    final app = AppScope.of(context);
    final choice = await showModalBottomSheet<MemoryQuestionCadence>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in MemoryQuestionCadence.values)
              ListTile(
                title: Text(_cadenceLabel(c)),
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (choice != null) {
      await app.setMemoryQuestionCadence(choice);
    }
  }

  Future<void> _pickResurfacing(BuildContext context) async {
    final app = AppScope.of(context);
    final choice = await showModalBottomSheet<MemoryResurfacingMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in MemoryResurfacingMode.values)
              ListTile(
                title: Text(_resurfacingLabel(m)),
                onTap: () => Navigator.pop(ctx, m),
              ),
          ],
        ),
      ),
    );
    if (choice != null) {
      await app.setMemoryResurfacingMode(choice);
    }
  }
}
