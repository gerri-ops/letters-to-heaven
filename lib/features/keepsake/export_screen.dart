import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../core/analytics/analytics.dart';
import '../../core/reviews/review_request_copy.dart';
import '../../core/reviews/review_request_service.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../core/utils/entry_helpers.dart';
import '../../data/models/models.dart';
import 'keepsake_catalog.dart';
import 'keepsake_pdf_builder.dart';

/// Premium Keepsake Builder — select entries and produce a giftable book.
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  List<Entry> _all = [];
  List<Entry> _entries = [];
  final Set<String> _selected = {};
  ExportTheme _theme = ExportTheme.cardinalGarden;
  KeepsakeBookType _bookType = KeepsakeBookType.lettersToHeaven;
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final app = AppScope.of(context);
    if (!app.premium) {
      if (mounted) {
        context.go('/keepsake-preview');
      }
      return;
    }
    await _load();
  }

  Future<void> _load() async {
    final memorial = AppScope.of(context).currentMemorial;
    if (memorial == null) {
      setState(() => _loading = false);
      return;
    }
    final entries =
        await AppScope.of(context).repository.listEntries(memorialId: memorial.id);
    if (!mounted) {
      return;
    }
    final visible = entries.where((e) => !e.hiddenFromExport).toList()
      ..sort((a, b) {
        final ad = a.entryDate ?? a.createdAt ?? DateTime(1970);
        final bd = b.entryDate ?? b.createdAt ?? DateTime(1970);
        return ad.compareTo(bd);
      });
    setState(() {
      _all = visible;
      _applyBookType(notify: false);
      _loading = false;
    });
  }

  void _applyBookType({bool notify = true}) {
    final suggested = _bookType.suggestedEntries(_all);
    _entries = suggested;
    _selected
      ..clear()
      ..addAll(_entries.map((e) => e.id));
    if (notify) {
      setState(() {});
    }
  }

  Future<void> _export() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one entry.')),
      );
      return;
    }
    final memorial = AppScope.of(context).currentMemorial;
    if (memorial == null) {
      return;
    }
    setState(() => _exporting = true);
    try {
      PrivacySafeAnalytics.instance.log('export_started');
      final chosen = _all.where((e) => _selected.contains(e.id)).toList();
      final mediaByEntry = <String, List<MediaAttachment>>{};
      final repo = AppScope.of(context).repository;
      for (final entry in chosen) {
        mediaByEntry[entry.id] = await repo.listMediaForEntry(entry.id);
      }
      final doc = await KeepsakePdfBuilder(
        memorial: memorial,
        entries: chosen,
        theme: _theme,
        bookType: _bookType,
        mediaByEntryId: mediaByEntry,
      ).build();
      final bytes = await doc.save();
      final safeName = memorial.displayName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final bookSlug = _bookType.shortLabel
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w]+'), '_');
      final filename = safeName.isEmpty
          ? 'letters_to_heaven_$bookSlug.pdf'
          : '${bookSlug}_$safeName.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);
      PrivacySafeAnalytics.instance.log('export_completed');
      if (mounted) {
        await ReviewRequestService.instance.maybeAsk(
          context,
          trigger: ReviewTrigger.keepsakeExported,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create keepsake: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  void _selectAll(bool all) {
    setState(() {
      _selected.clear();
      if (all) {
        _selected.addAll(_entries.map((e) => e.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LettersAppBar(
        title: const Text('Keepsake Builder'),
        intro: 'Choose a book, a style, and the memories to include.',
        actions: [
          IconButton(
            tooltip: 'Preview',
            onPressed: () => context.push('/keepsake-preview'),
            icon: const Icon(Icons.visibility_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    'Book type',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    children: [
                      for (final book in KeepsakeBookType.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(book.shortLabel),
                            selected: _bookType == book,
                            onSelected: (_) {
                              setState(() {
                                _bookType = book;
                                _applyBookType(notify: false);
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    _bookType.blurb,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedOlive,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Text(
                    'Export style',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SegmentedButton<ExportTheme>(
                    segments: const [
                      ButtonSegment(
                        value: ExportTheme.cardinalGarden,
                        label: Text('Garden'),
                      ),
                      ButtonSegment(
                        value: ExportTheme.softNeutral,
                        label: Text('Neutral'),
                      ),
                      ButtonSegment(
                        value: ExportTheme.inkSavingSimple,
                        label: Text('Ink-save'),
                      ),
                    ],
                    selected: {_theme},
                    onSelectionChanged: (s) => setState(() => _theme = s.first),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    _theme.blurb,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedOlive,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => _selectAll(true),
                        child: const Text('Select all'),
                      ),
                      TextButton(
                        onPressed: () => _selectAll(false),
                        child: const Text('Clear'),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${_selected.length} selected',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: AppColors.mutedInk),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _entries.isEmpty
                      ? const Center(
                          child: Text('No entries available for this book yet.'),
                        )
                      : ListView.builder(
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final e = _entries[index];
                            final date = e.entryDate ?? e.createdAt;
                            return CheckboxListTile(
                              value: _selected.contains(e.id),
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selected.add(e.id);
                                  } else {
                                    _selected.remove(e.id);
                                  }
                                });
                              },
                              title: Text(
                                e.title.isEmpty
                                    ? entryTypeLabel(e.type)
                                    : e.title,
                              ),
                              subtitle: Text(
                                [
                                  entryTypeLabel(e.type),
                                  if (date != null)
                                    MaterialLocalizations.of(context)
                                        .formatMediumDate(date),
                                ].join(' · '),
                              ),
                            );
                          },
                        ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: _exporting ? null : _export,
                      child: _exporting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create printable keepsake'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
