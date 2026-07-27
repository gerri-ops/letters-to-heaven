import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/artwork_assets.dart';
import '../../core/theme/artwork_image.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../core/utils/entry_helpers.dart';
import '../../data/models/models.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  List<Entry> _entries = [];
  bool _loading = true;
  AppState? _app;
  int _lastEpoch = -1;

  /// `null` means All; otherwise filter to that entry type.
  EntryType? _typeFilter;

  static final _monthFormat = DateFormat('MMMM yyyy');
  static final _dayFormat = DateFormat('EEE, MMM d');

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

  DateTime _sortDate(Entry e) =>
      e.entryDate ?? e.createdAt ?? e.updatedAt ?? DateTime(1970);

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
    all.sort((a, b) => _sortDate(b).compareTo(_sortDate(a)));
    if (!mounted) {
      return;
    }
    setState(() {
      _entries = all;
      _loading = false;
    });
  }

  /// Present entry types, in a stable display order.
  List<EntryType> _presentTypes(List<Entry> entries) {
    final present = entries.map((e) => e.type).toSet();
    return EntryType.values.where(present.contains).toList();
  }

  List<_MonthGroup> _grouped(List<Entry> entries, EntryType? typeFilter) {
    final filtered = typeFilter == null
        ? entries
        : entries.where((e) => e.type == typeFilter).toList();
    final groups = <_MonthGroup>[];
    String? currentKey;
    List<Entry> bucket = [];
    DateTime? monthAnchor;

    for (final e in filtered) {
      final d = _sortDate(e);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      if (key != currentKey) {
        if (bucket.isNotEmpty && monthAnchor != null) {
          groups.add(_MonthGroup(month: monthAnchor, entries: bucket));
        }
        currentKey = key;
        monthAnchor = DateTime(d.year, d.month);
        bucket = [e];
      } else {
        bucket.add(e);
      }
    }
    if (bucket.isNotEmpty && monthAnchor != null) {
      groups.add(_MonthGroup(month: monthAnchor, entries: bucket));
    }
    return groups;
  }

  String _preview(Entry e) {
    final body = e.body.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (body.isEmpty) {
      return entryTypeLabel(e.type);
    }
    if (body.length <= 90) {
      return body;
    }
    return '${body.substring(0, 90)}…';
  }

  @override
  Widget build(BuildContext context) {
    final types = _presentTypes(_entries);
    final activeFilter =
        _typeFilter != null && types.contains(_typeFilter) ? _typeFilter : null;
    if (activeFilter != _typeFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _typeFilter != activeFilter) {
          setState(() => _typeFilter = activeFilter);
        }
      });
    }
    final groups = _grouped(_entries, activeFilter);

    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('Timeline'),
        intro: 'Your entries in the order they happened.',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (types.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: activeFilter == null,
                      onSelected: (_) => setState(() => _typeFilter = null),
                      selectedColor: AppColors.softBlush,
                      checkmarkColor: AppColors.burgundy,
                      labelStyle: TextStyle(
                        color: activeFilter == null
                            ? AppColors.burgundy
                            : AppColors.mutedInk,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: activeFilter == null
                            ? AppColors.cardinalRed.withValues(alpha: 0.4)
                            : AppColors.softBlush,
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  for (final type in types)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(entryTypeLabel(type)),
                        selected: activeFilter == type,
                        onSelected: (_) => setState(() => _typeFilter = type),
                        selectedColor: AppColors.softBlush,
                        checkmarkColor: AppColors.burgundy,
                        labelStyle: TextStyle(
                          color: activeFilter == type
                              ? AppColors.burgundy
                              : AppColors.mutedInk,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: activeFilter == type
                              ? AppColors.cardinalRed.withValues(alpha: 0.4)
                              : AppColors.softBlush,
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: groups.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 48),
                              Center(
                                child: ArtworkImage(
                                  asset: ArtworkAssets.branch,
                                  height: 56,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(height: 20),
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
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            itemCount: groups.length,
                            itemBuilder: (context, index) {
                              final group = groups[index];
                              return _MonthSection(
                                label: _monthFormat.format(group.month),
                                entries: group.entries,
                                dayFormat: _dayFormat,
                                sortDate: _sortDate,
                                preview: _preview,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MonthGroup {
  const _MonthGroup({required this.month, required this.entries});

  final DateTime month;
  final List<Entry> entries;
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.label,
    required this.entries,
    required this.dayFormat,
    required this.sortDate,
    required this.preview,
  });

  final String label;
  final List<Entry> entries;
  final DateFormat dayFormat;
  final DateTime Function(Entry) sortDate;
  final String Function(Entry) preview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'Georgia',
                  color: AppColors.burgundy,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        for (var i = 0; i < entries.length; i++)
          _TimelineRow(
            entry: entries[i],
            dateLabel: dayFormat.format(sortDate(entries[i])),
            preview: preview(entries[i]),
            isLast: i == entries.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.dateLabel,
    required this.preview,
    required this.isLast,
  });

  final Entry entry;
  final String dateLabel;
  final String preview;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.isFavorite
                        ? AppColors.cardinalRed
                        : AppColors.antiqueGold,
                    border: Border.all(
                      color: AppColors.burgundy.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.softBlush,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 20),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.push('/entry/${entry.id}'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.mutedOlive,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.title.isEmpty
                            ? entryTypeLabel(entry.type)
                            : entry.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entryTypeLabel(entry.type)} · $preview',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedInk,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (entry.isFavorite)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.favorite, size: 16, color: AppColors.cardinalRed),
            ),
        ],
      ),
    );
  }
}
