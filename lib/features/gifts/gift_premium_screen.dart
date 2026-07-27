import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/analytics/analytics.dart';
import '../../core/billing/gift_premium_plan.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../data/repositories/app_repository.dart';

/// Purchase or redeem a non-renewing one-year Premium gift.
class GiftPremiumScreen extends StatefulWidget {
  const GiftPremiumScreen({super.key, this.initialMode = GiftScreenMode.give});

  final GiftScreenMode initialMode;

  @override
  State<GiftPremiumScreen> createState() => _GiftPremiumScreenState();
}

enum GiftScreenMode { give, redeem }

class _GiftPremiumScreenState extends State<GiftPremiumScreen> {
  late GiftScreenMode _mode;
  final _codeController = TextEditingController();
  IssuedGiftCode? _issued;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _purchaseGift() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final app = AppScope.of(context);
      final issued = await app.purchaseGiftLocal();
      PrivacySafeAnalytics.instance.log('gift_purchased');
      if (!mounted) return;
      setState(() => _issued = issued);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gift ready to share. It will not renew for the recipient.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareGift() async {
    final code = _issued?.code;
    if (code == null) return;
    final text = '${GiftPremiumPlan.giftMessage}\n\n'
        'Gift code: $code\n'
        '(One year of Letters to Heaven Premium. Does not renew.)';
    await Share.share(text, subject: 'A gift of Letters to Heaven Premium');
  }

  Future<void> _copyMessage() async {
    final code = _issued?.code;
    final text = code == null
        ? GiftPremiumPlan.giftMessage
        : '${GiftPremiumPlan.giftMessage}\n\nGift code: $code';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied gift message.')),
    );
  }

  Future<void> _redeem() async {
    if (_busy) return;
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _busy = true);
    try {
      final app = AppScope.of(context);
      final expires = await app.redeemGiftCodeLocal(code);
      PrivacySafeAnalytics.instance.log('gift_redeemed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gift redeemed. Premium is yours through '
            '${DateFormat.yMMMd().format(expires)} — it will not renew.',
          ),
        ),
      );
      context.go('/shell/home');
    } on GiftRedeemException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not redeem gift: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = AppScope.of(context);

    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('Gift Premium'),
        intro: 'A year of private remembering—without a renewing subscription.',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          SegmentedButton<GiftScreenMode>(
            segments: const [
              ButtonSegment(
                value: GiftScreenMode.give,
                label: Text('Give'),
                icon: Icon(Icons.card_giftcard_outlined),
              ),
              ButtonSegment(
                value: GiftScreenMode.redeem,
                label: Text('Redeem'),
                icon: Icon(Icons.redeem_outlined),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 24),
          if (_mode == GiftScreenMode.give) ...[
            Text(
              GiftPremiumPlan.offerLabel,
              style: theme.textTheme.headlineSmall?.copyWith(height: 1.25),
            ),
            const SizedBox(height: 12),
            Text(
              GiftPremiumPlan.purchaserIntro,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.mutedInk,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              GiftPremiumPlan.nonRenewingNotice,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedOlive,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Suggested gift message',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.burgundy,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.parchment,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.softBlush.withValues(alpha: 0.7),
                ),
              ),
              child: Text(
                GiftPremiumPlan.giftMessage,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _copyMessage,
                child: const Text('Copy message'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _purchaseGift,
              child: Text(
                _issued == null
                    ? GiftPremiumPlan.giveCta
                    : 'Create another gift code',
              ),
            ),
            if (_issued != null) ...[
              const SizedBox(height: 16),
              Text(
                'Gift code',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              SelectableText(
                _issued!.code,
                style: theme.textTheme.titleMedium?.copyWith(
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _shareGift,
                child: const Text(GiftPremiumPlan.shareCta),
              ),
            ],
          ] else ...[
            Text(
              'Redeem a gift',
              style: theme.textTheme.headlineSmall?.copyWith(height: 1.25),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter the code you received. You will get one year of Premium. '
              'It does not renew.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.mutedInk,
                height: 1.4,
              ),
            ),
            if (app.onGiftPremium && app.giftPremiumExpiresAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'You already have gift Premium through '
                '${DateFormat.yMMMd().format(app.giftPremiumExpiresAt!)}.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedOlive,
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Gift code',
                hintText: 'LTH-GIFT-…',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _redeem,
              child: const Text(GiftPremiumPlan.redeemCta),
            ),
          ],
          const SizedBox(height: 28),
          TextButton(
            onPressed: () => context.push('/paywall'),
            child: const Text('View Premium plans'),
          ),
        ],
      ),
    );
  }
}
