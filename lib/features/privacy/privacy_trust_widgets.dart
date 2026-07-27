import 'package:flutter/material.dart';

import '../../core/privacy/privacy_trust_copy.dart';
import '../../core/theme/app_theme.dart';

/// Product-facing privacy promises — plain language, not a legal wall of text.
class PrivacyTrustMessageList extends StatelessWidget {
  const PrivacyTrustMessageList({
    super.key,
    this.showAnalyticsAdvantage = true,
    this.dense = false,
  });

  final bool showAnalyticsAdvantage;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = dense
        ? theme.textTheme.bodyMedium?.copyWith(height: 1.35)
        : theme.textTheme.bodyLarge?.copyWith(height: 1.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final message in PrivacyTrustCopy.messages) ...[
          Padding(
            padding: EdgeInsets.only(bottom: dense ? 10 : 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: AppColors.mutedOlive,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(message, style: bodyStyle),
                ),
              ],
            ),
          ),
        ],
        if (showAnalyticsAdvantage) ...[
          SizedBox(height: dense ? 8 : 12),
          Text(
            PrivacyTrustCopy.analyticsAdvantageHeadline,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.burgundy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            PrivacyTrustCopy.analyticsAdvantageBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedInk,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in PrivacyTrustCopy.neverInAnalytics)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '· $item',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedOlive,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Compact trust band for paywalls and footers.
class PrivacyTrustBand extends StatelessWidget {
  const PrivacyTrustBand({super.key, this.messages});

  final List<String>? messages;

  @override
  Widget build(BuildContext context) {
    final lines = messages ??
        const [
          PrivacyTrustCopy.privateByDefault,
          PrivacyTrustCopy.doNotSell,
          PrivacyTrustCopy.noAds,
          PrivacyTrustCopy.remainsAfterCancel,
        ];
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.softBlush.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Text(
              lines[i],
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}
