import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../core/analytics/analytics.dart';
import '../../core/billing/trust_paywall_copy.dart';
import '../../core/reviews/review_request_copy.dart';
import '../../core/reviews/review_request_service.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../core/utils/entry_helpers.dart';
import '../../data/models/models.dart';
import 'keepsake_book_type_picker.dart';
import 'keepsake_catalog.dart';
import 'keepsake_pdf_builder.dart';
import 'keepsake_template_fallback.dart';

/// Premium Keepsake Builder — select entries and produce a giftable book.
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key, this.initialTheme});

  final ExportTheme? initialTheme;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  Memorial? _memorial;
  List<Entry> _all = [];
  List<Entry> _entries = [];
  final Set<String> _selected = {};
  late ExportTheme _theme =
      widget.initialTheme ?? ExportTheme.journalPdf;
  Set<KeepsakeBookType> _bookTypes = {};
  bool _loading = true;
  bool _exporting = false;
  Map<String, List<MediaAttachment>> _previewMedia = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
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
      _memorial = memorial;
      _all = visible;
      _applyBookTypes(notify: false);
      _loading = false;
    });
    await _refreshPreviewMedia();
  }

  Future<void> _refreshPreviewMedia() async {
    final memorial = _memorial;
    if (memorial == null) {
      return;
    }
    final previewEntries = _previewEntriesForPdf();
    final repo = AppScope.of(context).repository;
    final mediaByEntry = <String, List<MediaAttachment>>{};
    for (final entry in previewEntries) {
      if (KeepsakePreviewSamples.isTemplateId(entry.id)) {
        continue;
      }
      mediaByEntry[entry.id] = await repo.listMediaForEntry(entry.id);
    }
    if (!mounted) {
      return;
    }
    setState(() => _previewMedia = mediaByEntry);
  }

  List<Entry> _previewEntriesForPdf() {
    final chosen =
        _all.where((e) => _selected.contains(e.id)).toList();
    if (chosen.isNotEmpty) {
      return chosen;
    }
    if (_all.isEmpty) {
      final memorial = _memorial;
      if (memorial == null) {
        return const [];
      }
      return KeepsakePreviewSamples.templateEntries(memorial);
    }
    return suggestedEntriesForBookTypes(_bookTypes, _all).take(3).toList();
  }

  void _applyBookTypes({bool notify = true}) {
    final available = availableBookTypesFor(_all).toSet();
    _bookTypes.removeWhere((type) => !available.contains(type));
    final suggested = suggestedEntriesForBookTypes(_bookTypes, _all);
    _entries = suggested;
    _selected
      ..clear()
      ..addAll(_entries.map((e) => e.id));
    if (notify) {
      setState(() {});
    }
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final memorial = _memorial;
    if (memorial == null) {
      return Uint8List(0);
    }
    final previewEntries = _previewEntriesForPdf();
    final templateOnly = _all.isEmpty && previewEntries.isEmpty;
    final doc = await KeepsakePdfBuilder(
      memorial: memorial,
      entries: templateOnly ? const [] : previewEntries,
      theme: _theme,
      bookType: primaryBookType(_bookTypes),
      mediaByEntryId: _previewMedia,
      previewOnly: _all.isEmpty,
    ).build();
    return doc.save();
  }

  Future<void> _export() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one entry.')),
      );
      return;
    }
    final memorial = _memorial;
    if (memorial == null) {
      return;
    }
    if (!AppScope.of(context).premium) {
      await _requirePremiumForExport();
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
        bookType: primaryBookType(_bookTypes),
        mediaByEntryId: mediaByEntry,
      ).build();
      final bytes = await doc.save();
      final safeName = memorial.displayName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final bookSlug = bookFocusSlug(_bookTypes);
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

  Future<void> _requirePremiumForExport() async {
    if (!mounted) {
      return;
    }
    context.push(
      '/paywall?trigger=${PaywallTrigger.keepsakePreview.queryValue}'
      '&next=${Uri.encodeComponent('/export?theme=${_theme.name}')}',
    );
  }

  List<Widget> _previewActions(bool premium) {
    return [
      PdfPreviewAction(
        icon: Icon(premium ? Icons.print_outlined : Icons.lock_outline),
        onPressed: (context, build, format) async {
          if (!AppScope.of(context).premium) {
            await _requirePremiumForExport();
            return;
          }
          await Printing.layoutPdf(onLayout: build, name: 'keepsake.pdf');
        },
      ),
      PdfPreviewAction(
        icon: Icon(premium ? Icons.share_outlined : Icons.lock_outline),
        onPressed: (context, build, format) async {
          if (!AppScope.of(context).premium) {
            await _requirePremiumForExport();
            return;
          }
          final bytes = await build(format);
          await Printing.sharePdf(bytes: bytes, filename: 'keepsake.pdf');
        },
      ),
    ];
  }

  void _selectAll(bool all) {
    setState(() {
      _selected.clear();
      if (all) {
        _selected.addAll(_entries.map((e) => e.id));
      }
    });
    _refreshPreviewMedia();
  }

  @override
  Widget build(BuildContext context) {
    final memorial = _memorial;
    final showingTemplate = _all.isEmpty;
    final premium = AppScope.of(context).premium;

    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('Keepsake Builder'),
        showDogwood: false,
        intro:
            'Pick Journal PDF, Simple, or Ink Saver—then choose what to include.',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : memorial == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Set up a memorial first, then build your keepsake.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                        segments: [
                          for (final style in ExportTheme.values)
                            ButtonSegment(
                              value: style,
                              label: Text(style.shortLabel),
                              tooltip: style.label,
                            ),
                        ],
                        selected: {_theme},
                        onSelectionChanged: (s) {
                          setState(() => _theme = s.first);
                        },
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
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Text(
                        'Book focus',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: KeepsakeBookTypePicker(
                        selected: _bookTypes,
                        entries: _all,
                        onChanged: (value) async {
                          setState(() => _bookTypes = value);
                          _applyBookTypes(notify: true);
                          await _refreshPreviewMedia();
                        },
                      ),
                    ),
                    if (showingTemplate)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          'Template preview — your saved entries will replace these pages.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.mutedInk,
                                height: 1.35,
                              ),
                        ),
                      ),
                    if (!showingTemplate) ...[
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
                    ],
                    if (!showingTemplate)
                      SizedBox(
                        height: 160,
                        child: _entries.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'No entries match this book focus yet. '
                                    'Try another focus or save more memories.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.mutedInk),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _entries.length,
                                itemBuilder: (context, index) {
                                  final e = _entries[index];
                                  final date = e.entryDate ?? e.createdAt;
                                  return CheckboxListTile(
                                    dense: true,
                                    value: _selected.contains(e.id),
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selected.add(e.id);
                                        } else {
                                          _selected.remove(e.id);
                                        }
                                      });
                                      _refreshPreviewMedia();
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
                    Expanded(
                      child: PdfPreview(
                        key: ValueKey(
                          'builder-${_theme.name}-'
                          '${bookFocusSlug(_bookTypes)}-'
                          '${_selected.length}-$premium',
                        ),
                        build: _buildPdf,
                        // Built-in buttons bypass our paywall; use custom actions.
                        allowPrinting: false,
                        allowSharing: false,
                        canChangePageFormat: false,
                        canChangeOrientation: false,
                        canDebug: false,
                        pdfFileName: 'keepsake.pdf',
                        actions: _previewActions(premium),
                        onError: (context, error) {
                          final memorial = _memorial;
                          if (memorial == null) {
                            return Center(
                              child: Text(
                                'Could not preview keepsake: $error',
                              ),
                            );
                          }
                          return KeepsakeTemplateFallback(
                            memorial: memorial,
                            theme: _theme,
                            bookType: primaryBookType(_bookTypes),
                            error: error,
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FilledButton(
                          onPressed: _exporting || showingTemplate
                              ? null
                              : _export,
                          child: _exporting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  showingTemplate
                                      ? 'Save entries to export'
                                      : premium
                                          ? 'Create ${_theme.label}'
                                          : 'Unlock ${_theme.label}',
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
