import 'package:flutter/material.dart';

import 'media_policy.dart';

/// Quiet banner when cloud Storage is disabled.
class LocalOnlyMediaBanner extends StatelessWidget {
  const LocalOnlyMediaBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (MediaPolicy.instance.cloudStorageEnabled) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.phone_android, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              MediaPolicy.instance.localOnlyNotice,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
