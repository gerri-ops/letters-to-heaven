import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ai/ai_product_stance.dart';
import '../../core/privacy/privacy_trust_copy.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';
import 'privacy_trust_widgets.dart';

/// Privacy sold as a product feature — readable promises first, legal second.
class PrivacyTrustScreen extends StatelessWidget {
  const PrivacyTrustScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const LettersAppBar(
        title: Text(PrivacyTrustCopy.screenTitle),
        intro: PrivacyTrustCopy.screenIntro,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          const PrivacyTrustMessageList(),
          const SizedBox(height: 28),
          Text(
            AiProductStance.settingsSectionTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.burgundy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AiProductStance.positionHeadline,
            style: theme.textTheme.titleMedium?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            AiProductStance.positionSupporting,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedInk,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Helpers we may offer',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.mutedOlive,
            ),
          ),
          const SizedBox(height: 6),
          for (final item in AiProductStance.safeFunctions)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '· $item',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedInk,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'We never include',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.mutedOlive,
            ),
          ),
          const SizedBox(height: 6),
          for (final item in AiProductStance.forbiddenFunctions)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '· $item',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedInk,
                ),
              ),
            ),
          const SizedBox(height: 28),
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse(PrivacyTrustCopy.legalPolicyUrl),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text(PrivacyTrustCopy.legalPolicyLabel),
          ),
          TextButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/shell/home');
              }
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
