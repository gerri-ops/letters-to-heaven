import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics/analytics.dart';
import '../../core/billing/premium_upgrade_sheet.dart';
import '../../core/billing/trust_paywall_copy.dart';
import '../../core/media/media_policy.dart';
import '../../core/privacy/privacy_trust_copy.dart';
import '../../core/reviews/review_request_copy.dart';
import '../../core/reviews/review_request_service.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _biometricSupported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBiometric());
  }

  Future<void> _loadBiometric() async {
    final app = AppScope.of(context);
    final supported = await app.biometricLock.isDeviceSupported();
    final enabled = await app.biometricLock.isEnabled();
    if (mounted) {
      setState(() {
        _biometricSupported = supported;
        _biometricEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final app = AppScope.of(context);
    if (value) {
      final ok = await app.biometricLock.authenticate();
      if (!ok) {
        return;
      }
    }
    await app.biometricLock.setEnabled(value);
    PrivacySafeAnalytics.instance.log(
      value ? 'biometric_enabled' : 'biometric_disabled',
    );
    setState(() => _biometricEnabled = value);
  }

  Future<void> _editScreenName() async {
    final app = AppScope.of(context);
    final controller = TextEditingController(text: app.displayName);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Screen name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'How your name appears',
            hintText: 'Enter a screen name',
          ),
          onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted || next == null) {
      return;
    }
    final trimmed = next.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a screen name.')),
      );
      return;
    }
    await app.setScreenName(trimmed);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Screen name updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('Settings'),
        intro: 'Adjust memorial details, privacy, and day-to-day preferences.',
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Screen name'),
            subtitle: Text(
              app.displayName.trim().isEmpty
                  ? 'Not set'
                  : app.displayName.trim(),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editScreenName,
          ),
          ListTile(
            title: const Text('Memorials'),
            subtitle: Text(
              app.currentMemorial == null
                  ? 'Not set'
                  : app.premium
                      ? 'Remembering ${app.currentMemorial!.displayName}'
                      : '${app.currentMemorial!.displayName} · Add more with Premium',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/memorials'),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              PrivacyTrustCopy.settingsSectionTitle,
              style: TextStyle(
                color: AppColors.burgundy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListTile(
            title: const Text(PrivacyTrustCopy.openTrustLabel),
            subtitle: const Text(PrivacyTrustCopy.privateByDefault),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy-trust'),
          ),
          SwitchListTile(
            title: const Text('Biometric lock'),
            subtitle: _biometricSupported
                ? const Text('Require unlock when opening the app')
                : const Text('Not available on this device'),
            value: _biometricEnabled,
            onChanged:
                _biometricSupported ? _toggleBiometric : null,
          ),
          SwitchListTile(
            title: const Text('Encrypted cloud backup'),
            subtitle: Text(
              AppScope.of(context).premium
                  ? MediaPolicy.instance.localOnlyNotice
                  : 'Secure encrypted cloud backup is part of Premium. '
                      'On Basic, photos stay on this device.',
            ),
            value: MediaPolicy.instance.cloudStorageEnabled &&
                AppScope.of(context).premium,
            onChanged: (value) async {
              final app = AppScope.of(context);
              if (value && !app.premium) {
                await showPremiumUpgradeSheet(
                  context,
                  title: 'Cloud backup & sync',
                  body: '',
                  trigger: PaywallTrigger.privateBackup,
                );
                return;
              }
              if (value) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Enable encrypted cloud backup?'),
                    content: const Text(
                      'Photos will upload to your private Firebase Storage '
                      'folder when you are signed in and online. '
                      'App artwork does not use Storage.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Not yet'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Enable'),
                      ),
                    ],
                  ),
                );
                if (confirm != true) {
                  return;
                }
              }
              await MediaPolicy.instance.setCloudStorageEnabled(value);
              if (!mounted) {
                return;
              }
              if (value) {
                await app.repository.queueLocalMediaForCloudBackup();
                await app.syncService.flushPendingUploads();
              }
              if (!context.mounted) {
                return;
              }
              setState(() {});
              final notice = MediaPolicy.instance.localOnlyNotice;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(notice)),
              );
              if (value && context.mounted) {
                await ReviewRequestService.instance.maybeAsk(
                  context,
                  trigger: ReviewTrigger.backupCompleted,
                );
              }
            },
          ),
          ListTile(
            title: const Text('Export your data'),
            subtitle: const Text('Plain text or JSON — yours anytime'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/data-rights'),
          ),
          ListTile(
            title: const Text('Delete account & data'),
            subtitle: const Text('Remove your journal from this device and cloud'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/data-rights'),
          ),
          ListTile(
            title: const Text(PrivacyTrustCopy.legalPolicyLabel),
            subtitle: const Text(PrivacyTrustCopy.legalPolicySubtitle),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(
              Uri.parse(PrivacyTrustCopy.legalPolicyUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Text size'),
            subtitle: Text('Use your device accessibility text size settings.'),
          ),
          SwitchListTile(
            title: const Text('Reduce motion'),
            value: app.reducedMotion,
            onChanged: (v) => app.setReducedMotion(v),
          ),
          ListTile(
            title: const Text('Hide prompt categories'),
            subtitle: Text(
              app.hiddenPromptCategories.isEmpty
                  ? 'None hidden'
                  : app.hiddenPromptCategories.join(', '),
            ),
            onTap: () => _showCategoryPicker(context),
          ),
          SwitchListTile(
            title: const Text('Pause all reminders'),
            value: app.remindersPaused,
            onChanged: (v) => app.setRemindersPaused(v),
          ),
          ListTile(
            title: const Text('Reminders'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/reminders'),
          ),
          ListTile(
            title: const Text('Returning at your pace'),
            subtitle: const Text('Drafts, questions, widget—never streaks'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/retention'),
          ),
          const Divider(),
          ListTile(
            title: const Text('Support resources'),
            subtitle: const Text('988 Suicide & Crisis Lifeline (US)'),
            onTap: () => launchUrl(Uri.parse('tel:988')),
          ),
          ListTile(
            title: const Text('International crisis resources'),
            onTap: () => launchUrl(
              Uri.parse('https://www.iasp.info/suicidalthoughts/'),
            ),
          ),
          ListTile(
            title: const Text('Subscription'),
            onTap: () => context.go('/shell/subscribe'),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Letters to Heaven is a private memorial journal and memory '
              'keeper—not therapy, medical care, or AI grief counseling. '
              'Technology protects and organizes the memory; it does not tell '
              'you what the memory means. If you are in crisis, please reach '
              'out to a qualified professional or crisis line.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedOlive,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategoryPicker(BuildContext context) async {
    const categories = [
      'letters',
      'memories',
      'signs',
      'gratitude',
      'holidays',
    ];
    final app = AppScope.of(context);
    final selected = Set<String>.from(app.hiddenPromptCategories);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return ListView(
              children: [
                const ListTile(title: Text('Hide sensitive categories')),
                ...categories.map(
                  (c) => CheckboxListTile(
                    value: selected.contains(c),
                    title: Text(c),
                    onChanged: (v) {
                      setModalState(() {
                        if (v == true) {
                          selected.add(c);
                        } else {
                          selected.remove(c);
                        }
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: () async {
                      await app.setHiddenPromptCategories(selected);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
