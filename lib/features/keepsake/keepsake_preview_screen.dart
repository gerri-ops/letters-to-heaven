import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../core/analytics/analytics.dart';
import '../../core/billing/premium_pricing.dart';
import '../../core/billing/trust_paywall_copy.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../data/models/models.dart';
import 'keepsake_book_type_picker.dart';
import 'keepsake_catalog.dart';
import 'keepsake_pdf_builder.dart';
import 'keepsake_template_fallback.dart';

/// Conversion surface: show what saved memories become as a giftable book.
class KeepsakePreviewScreen extends StatefulWidget {
  const KeepsakePreviewScreen({super.key, this.initialTheme});

  final ExportTheme? initialTheme;

  @override
  State<KeepsakePreviewScreen> createState() => _KeepsakePreviewScreenState();
}

class _KeepsakePreviewScreenState extends State<KeepsakePreviewScreen> {
  List<Entry> _allVisible = [];
  List<Entry> _entries = [];
  Memorial? _memorial;
  bool _loading = true;
  Set<KeepsakeBookType> _bookTypes = {};
  late ExportTheme _theme =
      widget.initialTheme ?? ExportTheme.journalPdf;
  Map<String, List<MediaAttachment>> _mediaByEntry = {};
  bool _usingTemplatePreview = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final app = AppScope.of(context);
    final memorial = app.currentMemorial;
    if (memorial == null) {
      setState(() => _loading = false);
      return;
    }
    final all = await app.repository.listEntries(memorialId: memorial.id);
    final visible = all.where((e) => !e.hiddenFromExport).toList()
      ..sort((a, b) {
        final ad = a.entryDate ?? a.createdAt ?? DateTime(1970);
        final bd = b.entryDate ?? b.createdAt ?? DateTime(1970);
        return ad.compareTo(bd);
      });
    final available = availableBookTypesFor(visible).toSet();
    _bookTypes.removeWhere((type) => !available.contains(type));
    final suggested = suggestedEntriesForBookTypes(_bookTypes, visible);
    final preview = suggested.take(3).toList();
    final mediaByEntry = <String, List<MediaAttachment>>{};
    for (final entry in preview) {
      mediaByEntry[entry.id] =
          await app.repository.listMediaForEntry(entry.id);
    }
    if (!mounted) return;
    setState(() {
      _memorial = memorial;
      _allVisible = visible;
      _entries = preview;
      _mediaByEntry = mediaByEntry;
      _usingTemplatePreview = visible.isEmpty;
      _loading = false;
    });
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final memorial = _memorial;
    if (memorial == null) {
      return Uint8List(0);
    }
    final doc = await KeepsakePdfBuilder(
      memorial: memorial,
      entries: _entries,
      theme: _theme,
      bookType: primaryBookType(_bookTypes),
      mediaByEntryId: _mediaByEntry,
      previewOnly: true,
    ).build();
    return doc.save();
  }

  Future<void> _startTrial() async {
    final app = AppScope.of(context);
    PrivacySafeAnalytics.instance.log('subscription_started');
    final ok = await app.startPremiumTrialLocal();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Your ${PremiumPricing.freeTrialDays}-day premium trial has started.'
              : app.premium
                  ? 'Premium is already active.'
                  : 'A premium trial was already used on this device.',
        ),
      ),
    );
    if (ok || app.premium) {
      context.push('/export?theme=${_theme.name}');
    }
  }

  Future<void> _requirePremium() async {
    if (!mounted) {
      return;
    }
    context.push(
      '/paywall?trigger=${PaywallTrigger.keepsakePreview.queryValue}',
    );
  }

  List<Widget> _previewActions() {
    return [
      PdfPreviewAction(
        icon: const Icon(Icons.print_outlined),
        onPressed: (context, build, format) async {
          if (!AppScope.of(context).premium) {
            await _requirePremium();
            return;
          }
          await Printing.layoutPdf(onLayout: build, name: 'keepsake_preview.pdf');
        },
      ),
      PdfPreviewAction(
        icon: const Icon(Icons.share_outlined),
        onPressed: (context, build, format) async {
          if (!AppScope.of(context).premium) {
            await _requirePremium();
            return;
          }
          final bytes = await build(format);
          await Printing.sharePdf(
            bytes: bytes,
            filename: 'keepsake_preview.pdf',
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('Keepsake preview'),
        intro: KeepsakePreviewCopy.supporting,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _memorial == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Set up a memorial first, then preview your keepsake template.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Text(
                        _usingTemplatePreview
                            ? 'Template preview'
                            : KeepsakePreviewCopy.headline,
                        style: theme.textTheme.titleLarge?.copyWith(height: 1.3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Text(
                        _usingTemplatePreview
                            ? 'This sample shows how Journal PDF, Simple, and Ink Saver '
                                'will look. Your saved entries will replace these pages.'
                            : KeepsakePreviewCopy.supporting,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedInk,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: KeepsakeBookTypePicker(
                        selected: _bookTypes,
                        entries: _allVisible,
                        onChanged: (value) async {
                          setState(() {
                            _bookTypes = value;
                            _loading = true;
                          });
                          await _load();
                        },
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
                        onSelectionChanged: (s) =>
                            setState(() => _theme = s.first),
                      ),
                    ),
                    Expanded(
                      child: PdfPreview(
                        key: ValueKey(
                          'preview-${_theme.name}-${bookFocusSlug(_bookTypes)}',
                        ),
                        build: _buildPdf,
                        allowPrinting: false,
                        allowSharing: false,
                        canChangePageFormat: false,
                        canChangeOrientation: false,
                        canDebug: false,
                        pdfFileName: 'keepsake_preview.pdf',
                        actions: _previewActions(),
                        onError: (context, error) {
                          final memorial = _memorial;
                          if (memorial == null) {
                            return Center(
                              child: Text('Could not preview keepsake: $error'),
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              KeepsakePreviewCopy.moatLine,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.mutedOlive,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (app.premium)
                              FilledButton(
                                onPressed: () => context.push(
                                  '/export?theme=${_theme.name}',
                                ),
                                child: const Text('Open Keepsake Builder'),
                              )
                            else ...[
                              FilledButton(
                                onPressed: _startTrial,
                                child: const Text(
                                  TrustPaywallCopy.startTrialLabel,
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () => context.push(
                                  '/paywall?trigger='
                                  '${PaywallTrigger.keepsakePreview.queryValue}',
                                ),
                                child: const Text('See Premium details'),
                              ),
                              TextButton(
                                onPressed: () => context.go('/shell/home'),
                                child: const Text(
                                  TrustPaywallCopy.continueBasicLabel,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
