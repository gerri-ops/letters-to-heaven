import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/artwork_assets.dart';
import '../../core/theme/artwork_image.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../core/utils/entry_helpers.dart';
import '../../data/models/models.dart';

abstract class FilteredEntriesScreen extends StatefulWidget {
  const FilteredEntriesScreen({
    super.key,
    required this.title,
    required this.types,
    this.intro,
  });

  final String title;
  final Set<EntryType> types;
  final String? intro;

  @override
  State<FilteredEntriesScreen> createState() => FilteredEntriesScreenState();
}

class FilteredEntriesScreenState extends State<FilteredEntriesScreen> {
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
      _entries = all.where((e) => widget.types.contains(e.type)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LettersAppBar(
        title: Text(widget.title),
        intro: widget.intro,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _entries.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 48),
                        Center(
                          child: ArtworkImage(
                            asset: ArtworkAssets.dogwood,
                            height: 140,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Nothing Here Yet. Add Something When You\'re Ready.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final e = _entries[index];
                        final hidden = !e.isVisibleOnHome;
                        final title = e.title.isEmpty
                            ? entryTypeLabel(e.type)
                            : e.title;
                        final preview = e.body.trim().isEmpty
                            ? null
                            : e.body.trim();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: AppColors.parchment,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => context.push('/entry/${e.id}'),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  12,
                                  12,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          if (preview != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              preview,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: AppColors.mutedInk,
                                                    height: 1.35,
                                                  ),
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          Text(
                                            hidden
                                                ? '${entryTypeLabel(e.type)} · Hidden from Home'
                                                : entryTypeLabel(e.type),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: AppColors.mutedOlive,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (hidden || e.isFavorite)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Column(
                                          children: [
                                            if (hidden)
                                              const Icon(
                                                Icons.visibility_off_outlined,
                                                size: 18,
                                              ),
                                            if (hidden && e.isFavorite)
                                              const SizedBox(height: 6),
                                            if (e.isFavorite)
                                              const Icon(
                                                Icons.favorite,
                                                size: 18,
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
