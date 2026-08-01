import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics.dart';
import '../../core/billing/premium_pricing.dart';
import '../../core/billing/stripe_billing_service.dart';
import '../../core/billing/trust_paywall_copy.dart';
import '../../core/firebase/auth_service.dart';
import '../../core/privacy/privacy_trust_copy.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';
import '../privacy/privacy_trust_widgets.dart';

/// Trust-centered Premium paywall — never auto-shown on first launch.
class TrustPaywallScreen extends StatefulWidget {
  const TrustPaywallScreen({
    super.key,
    this.trigger = PaywallTrigger.browsePlans,
    this.nextPath,
    this.embeddedInShell = false,
    this.checkoutResult,
  });

  final PaywallTrigger trigger;
  final String? nextPath;
  final bool embeddedInShell;
  /// `success` or `cancel` when returning from Stripe Checkout.
  final String? checkoutResult;

  @override
  State<TrustPaywallScreen> createState() => _TrustPaywallScreenState();
}

class _TrustPaywallScreenState extends State<TrustPaywallScreen> {
  bool _busy = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleCheckoutReturn());
  }

  Future<void> _handleCheckoutReturn() async {
    final result = widget.checkoutResult;
    if (result == null || result.isEmpty) {
      return;
    }
    if (result == 'success') {
      PrivacySafeAnalytics.instance.log('subscription_started');
      setState(() {
        _busy = true;
        _statusMessage = 'Confirming your Premium subscription…';
      });
      try {
        await AppScope.of(context).syncStripeEntitlement();
        if (!mounted) return;
        setState(() {
          _statusMessage = AppScope.of(context).premium
              ? 'Premium is active. Thank you.'
              : 'Payment received. Premium will unlock in a moment—pull to refresh or reopen Subscribe.';
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _statusMessage = 'Could not confirm Premium yet. Try again shortly.');
      } finally {
        if (mounted) {
          setState(() => _busy = false);
        }
      }
    } else if (result == 'cancel') {
      setState(() => _statusMessage = 'Checkout canceled. You can subscribe anytime.');
    }
  }

  void _continueBasic(BuildContext context) {
    final next = widget.nextPath;
    if (next != null && next.isNotEmpty) {
      context.go(next);
      return;
    }
    if (widget.embeddedInShell) {
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
    final next = widget.nextPath;
    if (next != null && next.isNotEmpty) {
      context.go(next);
    } else if (widget.embeddedInShell) {
      // Stay on Subscribe so the active state is visible.
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/shell/home');
    }
  }

  Future<void> _subscribe(StripePlan plan) async {
    final app = AppScope.of(context);
    if (!app.hasCloudAccount) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Register to subscribe'),
          content: const Text(
            'Create a private account so Premium can follow you across devices '
            'and Stripe can send receipts to your email.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Register'),
            ),
          ],
        ),
      );
      if (go == true && mounted) {
        context.push('/account?next=home&reason=backup');
      }
      return;
    }

    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    try {
      PrivacySafeAnalytics.instance.log('subscription_started');
      final uid = AuthService.instance.firebaseUid ?? app.uid;
      if (uid == null || uid.isEmpty) {
        throw StripeBillingException('Sign in to subscribe.');
      }
      // Prefer Pricing Table (monthly + annual) on all platforms.
      await StripeBillingService.instance.openPricingTable(
        uid: uid,
        email: app.email ?? AuthService.instance.currentUser?.email,
      );
    } on StripeBillingException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open plans: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openPlans() => _subscribe(StripePlan.monthly);

  Future<void> _manageBilling() async {
    setState(() => _busy = true);
    try {
      await StripeBillingService.instance.openCustomerPortal();
    } on StripeBillingException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open billing portal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final forSecondMemorial = widget.trigger == PaywallTrigger.secondMemorial;
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
        automaticallyImplyLeading: !widget.embeddedInShell,
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
          const SizedBox(height: 4),
          Text(
            TrustPaywallCopy.stripePlanNotice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.mutedOlive,
            ),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _statusMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.burgundy,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (app.onStripePremium) ...[
            const FilledButton(
              onPressed: null,
              child: Text('Premium active'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _busy ? null : _manageBilling,
              child: const Text('Manage billing'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.push('/voice-keepsakes'),
              child: const Text('Open Voice Keepsakes'),
            ),
          ] else if (app.premium) ...[
            Text(
              app.onPremiumTrial
                  ? (app.premiumTrialEndsAt == null
                      ? 'Your Premium trial is active.'
                      : 'Your Premium trial is active through '
                          '${MaterialLocalizations.of(context).formatMediumDate(app.premiumTrialEndsAt!)}.')
                  : 'Premium is active on this device.',
              style: theme.textTheme.titleMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 8),
            Text(
              app.onPremiumTrial
                  ? 'Subscribe with Stripe anytime so Premium continues after this device trial.'
                  : 'Choose a plan to keep Premium across devices with Stripe.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedInk,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _openPlans,
              child: const Text(TrustPaywallCopy.choosePlanLabel),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.push('/voice-keepsakes'),
              child: const Text('Open Voice Keepsakes'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _busy ? null : () => _continueBasic(context),
              child: const Text(TrustPaywallCopy.continueBasicLabel),
            ),
          ] else ...[
            FilledButton(
              onPressed: _busy ? null : () => _startTrial(context),
              child: const Text(TrustPaywallCopy.startTrialLabel),
            ),
            const SizedBox(height: 6),
            Text(
              TrustPaywallCopy.localTrialNotice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.mutedOlive,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _busy ? null : _openPlans,
              child: const Text(TrustPaywallCopy.choosePlanLabel),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _busy ? null : () => _continueBasic(context),
              child: const Text(TrustPaywallCopy.continueBasicLabel),
            ),
          ],
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
