import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics.dart';
import '../../core/billing/gift_premium_plan.dart';
import '../../core/billing/premium_pricing.dart';
import '../../core/billing/trust_paywall_copy.dart';
import '../../core/privacy/privacy_trust_copy.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';
import '../privacy/privacy_trust_widgets.dart';

/// Trust-centered Premium paywall — never auto-shown on first launch.
class TrustPaywallScreen extends StatelessWidget {
  const TrustPaywallScreen({
    super.key,
    this.trigger = PaywallTrigger.browsePlans,
    this.nextPath,
    this.embeddedInShell = false,
  });

  final PaywallTrigger trigger;
  final String? nextPath;
  final bool embeddedInShell;

  void _continueBasic(BuildContext context) {
    final next = nextPath;
    if (next != null && next.isNotEmpty) {
      context.go(next);
      return;
    }
    if (embeddedInShell) {
      context.go('/shell/home');
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/shell/home');
  }

  Future<void> _startTrial(BuildContext context) async {
    final app = AppScope.of(context);
    PrivacySafeAnalytics.instance.log('subscription_started');
    final ok = await app.startPremiumTrialLocal();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Your ${PremiumPricing.freeTrialDays}-day premium trial has started.'
              : app.premium
                  ? 'Premium is already active.'
                  : 'A premium trial was already used on this device.',
        ),
      ),
    );
    if (!(ok || app.premium)) {
      return;
    }
    final next = nextPath;
    if (next != null && next.isNotEmpty) {
      context.go(next);
    } else if (embeddedInShell) {
      // Stay on Subscribe so the active state is visible.
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/shell/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final forSecondMemorial = trigger == PaywallTrigger.secondMemorial;
    final headline = forSecondMemorial
        ? TrustPaywallCopy.secondMemorialHeadline
        : TrustPaywallCopy.headline;
    final supporting = forSecondMemorial
        ? TrustPaywallCopy.secondMemorialSupporting
        : TrustPaywallCopy.supporting;

    return Scaffold(
      appBar: LettersAppBar(
        title: const Text('Premium'),
        intro: TrustPaywallCopy.trustStatement,
        automaticallyImplyLeading: !embeddedInShell,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Text(
            headline,
            style: theme.textTheme.headlineSmall?.copyWith(height: 1.25),
          ),
          const SizedBox(height: 12),
          Text(
            supporting,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.mutedInk,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          for (final benefit in TrustPaywallCopy.benefits) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: AppColors.mutedOlive,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      benefit,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const PrivacyTrustBand(),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.push('/privacy-trust'),
            child: const Text(PrivacyTrustCopy.openTrustLabel),
          ),
          const SizedBox(height: 10),
          Text(
            '${PremiumPricing.monthlyLabel} · '
            '${PremiumPricing.annualDisplayedAsMonthly}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.mutedOlive,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Or give ${GiftPremiumPlan.offerLabel} — does not renew.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.mutedOlive,
            ),
          ),
          const SizedBox(height: 24),
          if (app.premium) ...[
            FilledButton(
              onPressed: null,
              child: Text(
                app.onPremiumTrial
                    ? 'Premium trial active'
                    : app.onGiftPremium
                        ? 'Gift Premium active'
                        : 'Premium active',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.push('/voice-keepsakes'),
              child: const Text('Open Voice Keepsakes'),
            ),
          ] else ...[
            FilledButton(
              onPressed: () => _startTrial(context),
              child: const Text(TrustPaywallCopy.startTrialLabel),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _continueBasic(context),
              child: const Text(TrustPaywallCopy.continueBasicLabel),
            ),
          ],
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.push('/gift'),
            child: const Text('Give Premium as a gift'),
          ),
          TextButton(
            onPressed: () => context.push('/gift?mode=redeem'),
            child: const Text(GiftPremiumPlan.redeemCta),
          ),
        ],
      ),
    );
  }
}
