import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import 'reminder_copy.dart';

/// Opt-in only — never shown on first launch.
Future<ReminderOptInChoice?> showReminderOptInSheet(BuildContext context) {
  return showModalBottomSheet<ReminderOptInChoice>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quiet reminders',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              ReminderCopy.optInQuestion,
              style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Reminders can sting. You choose every date, time, and what may '
              'appear—and you can pause or silence them anytime.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, ReminderOptInChoice.remindMe),
              child: const Text(ReminderCopy.remindMe),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () =>
                  Navigator.pop(ctx, ReminderOptInChoice.returnOnMyOwn),
              child: const Text(ReminderCopy.returnOnMyOwn),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, ReminderOptInChoice.askMeLater),
              child: const Text(ReminderCopy.askMeLater),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> offerReminderOptInIfNeeded(BuildContext context) async {
  final app = AppScope.of(context);
  if (!app.shouldOfferReminderOptIn) {
    return;
  }
  final choice = await showReminderOptInSheet(context);
  if (choice == null || !context.mounted) {
    return;
  }
  await app.setReminderOptInChoice(choice);
  if (choice == ReminderOptInChoice.remindMe && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'You can set dates and privacy in Reminders whenever you are ready.',
        ),
      ),
    );
  }
}
