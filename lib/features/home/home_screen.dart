import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/retention/retention_cue_builder.dart';
import '../../core/reviews/review_request_service.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/artwork_assets.dart';
import '../../core/theme/artwork_image.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../core/utils/entry_helpers.dart';
import '../../data/models/models.dart';
import '../prompts/optional_prompt_sheet.dart';
import 'home_retention_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Entry> _recent = [];
  List<RetentionCue> _cues = [];
  bool _loading = true;
  bool _subscribed = false;
  bool _reviewCheckScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_subscribed) {
      _subscribed = true;
      AppScope.of(context).addListener(_load);
      _load();
    }
    if (!_reviewCheckScheduled) {
      _reviewCheckScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final app = AppScope.of(context);
        if (!app.onboardingComplete) return;
        // ignore: unawaited_futures
        ReviewRequestService.instance.presentFromHome(context);
      });
    }
  }

  @override
  void dispose() {
    if (_subscribed) {
      AppScope.of(context).removeListener(_load);
    }
    super.dispose();
  }

  Future<void> _load() async {
    final app = AppScope.of(context);
    final memorial = app.currentMemorial;
    if (memorial == null) {
      setState(() {
        _recent = [];
        _cues = [];
        _loading = false;
      });
      return;
    }
    final entries = await app.repository.listEntries(memorialId: memorial.id);
    entries.sort((a, b) {
      final ad = a.updatedAt ?? a.createdAt ?? DateTime(1970);
      final bd = b.updatedAt ?? b.createdAt ?? DateTime(1970);
      return bd.compareTo(ad);
    });
    final dates = await app.repository.listRemembranceDates(memorial.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _recent = entries.where((e) => e.isVisibleOnHome).take(5).toList();
      _cues = RetentionCueBuilder.build(
        entries: entries,
        questionCadence: app.memoryQuestionCadence,
        monthlyKeepsakeEnabled: app.monthlyKeepsakePreview,
        resurfacingMode: app.memoryResurfacingMode,
        hasRemembranceDates: dates.isNotEmpty,
        hasFamilyContributionWaiting: app.familyContributionWaiting,
        now: DateTime.now(),
        lastKeepsakePreviewYearMonth: app.lastKeepsakePreviewYearMonth,
        lastQuestionYearWeekOrMonth: app.lastMemoryQuestionKey,
      );
      _loading = false;
    });
  }

  void _showMoreIdeas() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    'Optional starting points',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '  Still just four places to save—these are ideas, not homework.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedInk,
                      ),
                ),
                const SizedBox(height: 8),
                _MoreWayTile(
                  icon: Icons.graphic_eq,
                  title: 'Voice Keepsakes',
                  onTap: () {
                    Navigator.pop(context);
                    this.context.push('/voice-keepsakes');
                  },
                ),
                _MoreWayTile(
                  icon: Icons.lightbulb_outline,
                  title: 'One optional question',
                  onTap: () {
                    Navigator.pop(context);
                    showOptionalPromptSheet(this.context);
                  },
                ),
                _MoreWayTile(
                  icon: Icons.menu_book_outlined,
                  title: 'Browse prompt library',
                  onTap: () {
                    Navigator.pop(context);
                    this.context.push('/prompts');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final memorial = app.currentMemorial;
    final greeting = greetingForTimeOfDay(DateTime.now());

    return Scaffold(
      appBar: LettersAppBar(
        title: const Text('Home'),
        showDogwood: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CardinalAccent(size: 56),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting${app.displayName.isNotEmpty ? ', ${app.displayName}' : ''}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (memorial != null) ...[
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => context.push('/memorials'),
                                child: Text(
                                  'Thinking of ${memorial.displayName} today.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppColors.mutedInk),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Save something',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Catch something before it fades. Voice and a quick note sit ready—'
                    'the rest is optional.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedOlive,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryAction(
                    title: 'Letter',
                    subtitle: entryTypeBlurb(EntryType.letter),
                    icon: Icons.mail_outline,
                    onTap: () => context.push('/entry/new?type=letter'),
                  ),
                  _PrimaryAction(
                    title: 'Memory',
                    subtitle: entryTypeBlurb(EntryType.memory),
                    icon: Icons.auto_stories_outlined,
                    onTap: () => context.push('/entry/new?type=memory'),
                  ),
                  _PrimaryAction(
                    title: 'Meaningful Moment',
                    subtitle: entryTypeBlurb(EntryType.meaningfulMoment),
                    icon: Icons.nights_stay_outlined,
                    onTap: () =>
                        context.push('/entry/new?type=meaningfulMoment'),
                  ),
                  _PrimaryAction(
                    title: 'Keepsake',
                    subtitle: entryTypeBlurb(EntryType.keepsake),
                    icon: Icons.photo_camera_outlined,
                    onTap: () => context.push('/entry/new?type=keepsake'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _showMoreIdeas,
                    child: const Text('Need a gentle nudge?'),
                  ),
                  HomeRetentionSection(
                    cues: _cues,
                    onChanged: _load,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Recent',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_recent.isEmpty)
                    Column(
                      children: [
                        const ArtworkImage(
                          asset: ArtworkAssets.dogwood,
                          height: 100,
                          opacity: 0.85,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nothing here yet. Capture something when you\'re ready.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else
                    ..._recent.map(
                      (e) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          e.title.isEmpty
                              ? (e.body.trim().isEmpty
                                  ? entryTypeLabel(e.type)
                                  : e.body.trim())
                              : e.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(entryTypeLabel(e.type)),
                        onTap: () => context.push('/entry/${e.id}'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.burgundy, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedInk,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.mutedOlive),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreWayTile extends StatelessWidget {
  const _MoreWayTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.burgundy),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
