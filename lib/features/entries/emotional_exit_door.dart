import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';

/// Soft close after writing — saves first, never forces rereading.
abstract final class EmotionalExitCopy {
  static const buttonLabel = 'Save and Step Away';
  static const confirmation =
      'Your entry is safe. You do not have to reread it now.';
  static const returnHome = 'Return Home';
  static const hideForNow = 'Hide This Entry for Now';
  static const setReturnDate = 'Set a Private Return Date';
}

/// Shows after an automatic save from the emotional exit door.
Future<void> showEmotionalExitDoor(
  BuildContext context, {
  required String entryId,
}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              EmotionalExitCopy.confirmation,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 8),
            Text(
              'You can hide photographs and memories from Home without deleting them. '
              'They stay in Library and Search.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'home'),
              child: const Text(EmotionalExitCopy.returnHome),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, 'hide'),
              child: const Text(EmotionalExitCopy.hideForNow),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'returnDate'),
              child: const Text(EmotionalExitCopy.setReturnDate),
            ),
          ],
        ),
      );
    },
  );

  if (!context.mounted || choice == null) {
    return;
  }

  final app = AppScope.of(context);
  final entry = await app.repository.getEntryById(entryId);
  if (entry == null) {
    if (context.mounted) {
      context.go('/shell/home');
    }
    return;
  }

  if (choice == 'hide') {
    await app.repository.upsertEntry(
      entry.copyWith(hiddenFromHome: true),
      forceState: false,
    );
    app.notifyContentChanged();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hidden from Home. Still available in Library and Search.',
          ),
        ),
      );
      context.go('/shell/home');
    }
    return;
  }

  if (choice == 'returnDate') {
    if (!context.mounted) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      helpText: 'Private return date',
    );
    if (picked != null) {
      await app.repository.upsertEntry(
        entry.copyWith(
          hiddenFromHome: true,
          privateReturnDate: DateTime(picked.year, picked.month, picked.day),
        ),
      );
      app.notifyContentChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hidden from Home until your private return date.',
            ),
          ),
        );
      }
    }
    if (context.mounted) {
      context.go('/shell/home');
    }
    return;
  }

  if (context.mounted) {
    context.go('/shell/home');
  }
}
