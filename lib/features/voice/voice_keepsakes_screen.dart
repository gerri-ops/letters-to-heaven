import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/billing/premium_upgrade_sheet.dart';
import '../../core/billing/trust_paywall_copy.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/artwork_assets.dart';
import '../../core/theme/artwork_image.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../core/utils/entry_helpers.dart';
import '../../data/models/models.dart';
import 'voice_keepsake_models.dart';

/// Dedicated home for preserving voice — a premium hero surface.
class VoiceKeepsakesScreen extends StatefulWidget {
  const VoiceKeepsakesScreen({super.key});

  @override
  State<VoiceKeepsakesScreen> createState() => _VoiceKeepsakesScreenState();
}

class _VoiceKeepsakesScreenState extends State<VoiceKeepsakesScreen> {
  List<Entry> _entries = [];
  bool _loading = true;
  AppState? _app;
  int _lastEpoch = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (!identical(_app, app)) {
      _app?.removeListener(_onAppChanged);
      _app = app;
      _app!.addListener(_onAppChanged);
    }
    _refresh();
  }

  @override
  void dispose() {
    _app?.removeListener(_onAppChanged);
    super.dispose();
  }

  void _onAppChanged() {
    if (!mounted || _app == null) {
      return;
    }
    if (_app!.contentEpoch != _lastEpoch) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final app = _app ?? AppScope.of(context);
    _lastEpoch = app.contentEpoch;
    final memorial = app.currentMemorial;
    if (memorial == null) {
      if (mounted) {
        setState(() {
          _entries = [];
          _loading = false;
        });
      }
      return;
    }
    final all = await app.repository.listEntries(memorialId: memorial.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _entries = all.where(isVoiceKeepsake).toList()
        ..sort((a, b) {
          final ad = a.updatedAt ?? a.createdAt ?? DateTime(1970);
          final bd = b.updatedAt ?? b.createdAt ?? DateTime(1970);
          return bd.compareTo(ad);
        });
      _loading = false;
    });
  }

  void _openNew() {
    final app = AppScope.of(context);
    if (!app.premium) {
      showPremiumUpgradeSheet(
        context,
        title: '',
        body: '',
        trigger: PaywallTrigger.voiceRecording,
      );
      return;
    }
    context.push('/voice-keepsakes/new');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('Voice Keepsakes'),
        intro: voicePremiumHero,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNew,
        icon: const Icon(Icons.mic_none),
        label: Text(app.premium ? 'Add voice' : 'Premium'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
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
                        Text(
                          app.premium
                              ? 'Your private voice shelf'
                              : 'A premium place for voice',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'People fear forgetting a laugh, a sleepy voice, a '
                          'song, a saying, a nickname. Keep the sound—and the '
                          'story around it.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.mutedInk,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          voiceNoCloneDisclaimer,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedOlive,
                          ),
                        ),
                        if (!app.premium) ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => showPremiumUpgradeSheet(
                              context,
                              title: '',
                              body: '',
                              trigger: PaywallTrigger.voiceRecording,
                            ),
                            child: const Text('Start 14-Day Free Trial'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_entries.isEmpty) ...[
                    const ArtworkImage(
                      asset: ArtworkAssets.dogwood,
                      height: 100,
                      opacity: 0.85,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      app.premium
                          ? 'No voice keepsakes yet. Add a recording when you are ready.'
                          : 'Voice keepsakes are part of Premium. Your writing stays free on this device.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ] else
                    ..._entries.map((e) {
                      final speaker = voiceSpeaker(e);
                      final period = voiceTimePeriod(e);
                      final meta = [
                        if (speaker != null && speaker.isNotEmpty) speaker,
                        if (period != null && period.isNotEmpty) period,
                        entryTypeLabel(e.type),
                      ].join(' · ');
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.graphic_eq),
                        title: Text(
                          e.title.isEmpty
                              ? (e.body.trim().isEmpty
                                  ? 'Voice keepsake'
                                  : e.body.trim())
                              : e.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(meta),
                        onTap: () =>
                            context.push('/voice-keepsakes/${e.id}/edit'),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
