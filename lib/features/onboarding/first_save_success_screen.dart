import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/billing/trust_paywall_copy.dart';
import '../../core/reminders/reminder_opt_in_sheet.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/artwork_assets.dart';
import '../../core/theme/artwork_image.dart';

/// Shown once after the user’s first saved fragment (activation).
class FirstSaveSuccessScreen extends StatefulWidget {
  const FirstSaveSuccessScreen({required this.entryId, super.key});

  final String entryId;

  @override
  State<FirstSaveSuccessScreen> createState() => _FirstSaveSuccessScreenState();
}

class _FirstSaveSuccessScreenState extends State<FirstSaveSuccessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final app = AppScope.of(context);
      if (!app.firstSaveSuccessSeen) {
        await app.markFirstSaveSuccessSeen();
      }
      if (!app.onboardingComplete) {
        await app.completeOnboarding();
      }
    });
  }

  Future<void> _returnHome() async {
    final app = AppScope.of(context);
    if (!mounted) return;
    await offerReminderOptInIfNeeded(context);
    if (!mounted) return;
    if (await app.shouldOfferFirstSavePaywall()) {
      await app.markFirstSavePaywallOffered();
      if (!mounted) return;
      context.go(
        '/paywall?trigger=${PaywallTrigger.firstMemorySaved.queryValue}'
        '&next=${Uri.encodeComponent('/shell/home')}',
      );
      return;
    }
    if (!mounted) return;
    context.go('/shell/home');
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
                height: 96,
                fit: BoxFit.contain,
                opacity: 0.9,
              ),
              const SizedBox(height: 28),
              Text(
                'Saved. That is enough for today.',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'You can add more now or return whenever you are ready.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.mutedInk,
                  height: 1.4,
                ),
              ),
              const Spacer(flex: 3),
              FilledButton(
                onPressed: widget.entryId.isEmpty
                    ? null
                    : () {
                        context.go('/entry/${widget.entryId}/edit');
                      },
                child: const Text('Add One More Detail'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _returnHome,
                child: const Text('Return Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
