import 'package:flutter/material.dart';

import '../../core/reviews/review_request_copy.dart';
import '../../core/theme/app_theme.dart';

enum ReviewRequestChoice {
  leaveReview,
  notNow,
  doNotAskAgain,
}

/// Soft prompt after a safe success moment — never after a painful letter.
Future<ReviewRequestChoice?> showReviewRequestSheet(BuildContext context) {
  return showModalBottomSheet<ReviewRequestChoice>(
    context: context,
    showDragHandle: true,
    isDismissible: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
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
              ReviewRequestCopy.question,
              style: theme.textTheme.titleMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 10),
            Text(
              ReviewRequestCopy.supporting,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedInk,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, ReviewRequestChoice.leaveReview),
              child: const Text(ReviewRequestCopy.leaveReview),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, ReviewRequestChoice.notNow),
              child: const Text(ReviewRequestCopy.notNow),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, ReviewRequestChoice.doNotAskAgain),
              child: const Text(ReviewRequestCopy.doNotAskAgain),
            ),
          ],
        ),
      );
    },
  );
}
