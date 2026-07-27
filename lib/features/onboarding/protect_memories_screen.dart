import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/billing/trust_paywall_copy.dart';
import '../../core/reminders/reminder_opt_in_sheet.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/artwork_assets.dart';
import '../../core/theme/artwork_image.dart';

/// Offered after the first local save when the user has no cloud account yet.
class ProtectMemoriesScreen extends StatelessWidget {
  const ProtectMemoriesScreen({super.key});

  Future<void> _keepOnDevice(BuildContext context) async {
    final app = AppScope.of(context);
    if (!app.onboardingComplete) {
      await app.completeOnboarding();
    }
    if (!context.mounted) return;
    await offerReminderOptInIfNeeded(context);
    if (!context.mounted) return;
    if (await app.shouldOfferFirstSavePaywall()) {
      await app.markFirstSavePaywallOffered();
      if (!context.mounted) return;
      context.go(
        '/paywall?trigger=${PaywallTrigger.firstMemorySaved.queryValue}'
        '&next=${Uri.encodeComponent('/shell/home')}',
      );
      return;
    }
    if (context.mounted) {
      context.go('/shell/home');
    }
  }

  Future<void> _protectAcrossDevices(BuildContext context) async {
    final app = AppScope.of(context);
    if (!app.onboardingComplete) {
      await app.completeOnboarding();
    }
    if (!context.mounted) return;
    if (app.premium) {
      context.push('/account?next=home&reason=backup');
      return;
    }
    context.go(
      '/paywall?trigger=${PaywallTrigger.syncAnotherDevice.queryValue}'
      '&next=${Uri.encodeComponent('/account?next=home&reason=backup')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const ArtworkImage(
                asset: ArtworkAssets.dogwood,
                height: 88,
                fit: BoxFit.contain,
                opacity: 0.9,
              ),
              const SizedBox(height: 24),
              Text(
                'Your entry is saved on this device.',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(height: 1.25),
              ),
              const SizedBox(height: 14),
              Text(
                'Register to save it with a private account—encrypted backup '
                'and access from another device when you want them.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.mutedInk,
                  height: 1.4,
                ),
              ),
              const Spacer(flex: 3),
              FilledButton(
                onPressed: () => _protectAcrossDevices(context),
                child: const Text('Register to Save'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => _keepOnDevice(context),
                child: const Text('Keep Using This Device'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
