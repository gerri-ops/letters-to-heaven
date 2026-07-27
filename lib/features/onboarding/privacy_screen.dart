import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/privacy/privacy_trust_copy.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';
import '../privacy/privacy_trust_widgets.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<void> _continue(BuildContext context) async {
    await AppScope.of(context).acceptPrivacy();
    if (context.mounted) {
      context.push('/pace-promise');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('Your memories stay yours.'),
        intro: PrivacyTrustCopy.screenIntro,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text(
            PrivacyTrustCopy.privateByDefault,
            style: theme.textTheme.titleMedium?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 16),
          const PrivacyTrustMessageList(
            showAnalyticsAdvantage: false,
            dense: true,
          ),
          const SizedBox(height: 12),
          Text(
            'The full legal policy is available anytime. These promises are '
            'part of the product itself.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.mutedOlive,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _continue(context),
            child: const Text('Continue'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}
