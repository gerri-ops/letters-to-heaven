import 'package:barcode/barcode.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/media/local_file_io.dart'
    if (dart.library.html) '../../core/media/local_file_web.dart' as io;
import '../../core/theme/artwork_assets.dart';
import '../../core/utils/entry_helpers.dart';
import '../../data/models/models.dart';
import '../entries/entry_placement.dart';
import '../voice/voice_keepsake_models.dart';
import 'keepsake_catalog.dart';

export 'keepsake_catalog.dart' show ExportTheme, KeepsakeBookType;

/// Builds a giftable, printable keepsake PDF — not a database dump.
class KeepsakePdfBuilder {
  KeepsakePdfBuilder({
    required this.memorial,
    required this.entries,
    required this.theme,
    this.bookType = KeepsakeBookType.lettersToHeaven,
    this.mediaByEntryId = const {},
    this.previewOnly = false,
  });

  final Memorial memorial;
  final List<Entry> entries;
  final ExportTheme theme;
  final KeepsakeBookType bookType;
  final Map<String, List<MediaAttachment>> mediaByEntryId;
  /// When true, caps content for an in-app conversion preview.
  final bool previewOnly;

  static final _shortDate = DateFormat.yMMMd();

  Future<pw.Document> build() async {
    final titleFont = await PdfGoogleFonts.libreBaskervilleRegular();
    final titleItalic = await PdfGoogleFonts.libreBaskervilleItalic();
    final bodyFont = await PdfGoogleFonts.sourceSans3Regular();
    final bodyBold = await PdfGoogleFonts.sourceSans3SemiBold();

    final palette = _Palette.forTheme(theme);
    final art = await _loadArt(theme);

    var sorted = List<Entry>.from(entries)
      ..sort((a, b) {
        final ad = a.entryDate ?? a.createdAt ?? DateTime(1970);
        final bd = b.entryDate ?? b.createdAt ?? DateTime(1970);
        return ad.compareTo(bd);
      });
    if (previewOnly && sorted.length > 3) {
      sorted = sorted.take(3).toList();
    }
    if (bookType == KeepsakeBookType.onePageRemembrance && sorted.length > 1) {
      sorted = sorted.take(1).toList();
    }

    final prepared = <String, List<_PdfPlacement>>{};
    for (final entry in sorted) {
      prepared[entry.id] = await _preparePlacements(entry);
    }

    final doc = pw.Document(
      title: '${bookType.title} — ${memorial.displayName}',
      author: 'Letters to Heaven',
      subject: 'Private memorial keepsake',
    );

    if (bookType == KeepsakeBookType.onePageRemembrance) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.fromLTRB(48, 52, 48, 52),
          build: (context) => _OnePageRemembrance(
            memorial: memorial,
            entry: sorted.isEmpty ? null : sorted.first,
            placements: sorted.isEmpty
                ? const []
                : prepared[sorted.first.id] ?? const [],
            palette: palette,
            titleFont: titleFont,
            titleItalic: titleItalic,
            bodyFont: bodyFont,
            bodyBold: bodyBold,
            art: art,
            theme: theme,
          ),
        ),
      );
      return doc;
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: pw.EdgeInsets.zero,
        build: (context) => _CoverPage(
          memorial: memorial,
          bookType: bookType,
          palette: palette,
          art: art,
          titleFont: titleFont,
          titleItalic: titleItalic,
          bodyFont: bodyFont,
          entryCount: sorted.length,
          theme: theme,
          previewOnly: previewOnly,
        ),
      ),
    );

    if (sorted.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.fromLTRB(48, 52, 48, 56),
            theme: pw.ThemeData.withFont(
              base: bodyFont,
              bold: bodyBold,
              italic: titleItalic,
            ),
            buildBackground: theme == ExportTheme.journalPdf
                ? (context) => pw.FullPage(
                      ignoreMargins: true,
                      child: pw.Container(color: palette.pageBg),
                    )
                : null,
          ),
          header: (context) => _pageHeader(
            palette: palette,
            titleFont: titleFont,
            bodyFont: bodyFont,
            bookTitle: bookType.shortLabel,
          ),
          footer: (context) => _pageFooter(
            context: context,
            palette: palette,
            bodyFont: bodyFont,
          ),
          build: (context) => [
            for (var i = 0; i < sorted.length; i++) ...[
              _EntryBlock(
                entry: sorted[i],
                placements: prepared[sorted[i].id] ?? const [],
                media: mediaByEntryId[sorted[i].id] ?? const [],
                palette: palette,
                titleFont: titleFont,
                bodyFont: bodyFont,
                bodyBold: bodyBold,
                theme: theme,
              ),
              if (i < sorted.length - 1) pw.SizedBox(height: 6),
            ],
            pw.SizedBox(height: 28),
            _Closing(
              palette: palette,
              titleItalic: titleItalic,
              bodyFont: bodyFont,
            ),
          ],
        ),
      );
    }

    return doc;
  }

  Future<List<_PdfPlacement>> _preparePlacements(Entry entry) async {
    final media = mediaByEntryId[entry.id] ?? const <MediaAttachment>[];
    final pathByMediaId = {for (final m in media) m.id: m.localPath};
    final placements = placementsFromExtension(entry.extensionJson).map((p) {
      if ((p.localPath == null || p.localPath!.isEmpty) && p.mediaId != null) {
        return p.copyWith(localPath: pathByMediaId[p.mediaId!]);
      }
      return p;
    }).toList();

    // Legacy entries without a placements layout: include all media once.
    if (!entry.extensionJson.containsKey('placements')) {
      for (final m in media) {
        final already = placements.any((p) => p.mediaId == m.id);
        if (!already) {
          placements.add(
            EntryPlacement(
              id: 'pdf-${m.id}',
              mediaId: m.id,
              localPath: m.localPath,
              x: 0.08 + (placements.length % 3) * 0.3,
              y: 0.08 + (placements.length ~/ 3) * 0.34,
              scale: 0.3,
            ),
          );
        }
      }
    }

    final prepared = <_PdfPlacement>[];
    for (final p in placements) {
      Uint8List? bytes;
      if (p.localPath != null) {
        try {
          bytes = await io.readBytes(p.localPath!);
        } catch (_) {
          bytes = null;
        }
      }
      if (bytes == null || bytes.isEmpty) {
        continue;
      }
      prepared.add(_PdfPlacement(placement: p, image: pw.MemoryImage(bytes)));
    }
    return prepared;
  }

  Future<_Art?> _loadArt(ExportTheme theme) async {
    // Ink-saving stays plain; other styles use dogwood on the cover.
    if (theme == ExportTheme.inkSaver) {
      return null;
    }
    try {
      final dogwood =
          (await rootBundle.load(ArtworkAssets.dogwood)).buffer.asUint8List();
      return _Art(dogwood: pw.MemoryImage(dogwood));
    } catch (_) {
      return null;
    }
  }

  pw.Widget _pageHeader({
    required _Palette palette,
    required pw.Font titleFont,
    required pw.Font bodyFont,
    required String bookTitle,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    bookTitle,
                    style: pw.TextStyle(
                      font: titleFont,
                      fontSize: 11,
                      color: palette.brand,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'In memory of ${memorial.displayName}',
                    style: pw.TextStyle(
                      font: bodyFont,
                      fontSize: 9,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 1, color: palette.rule),
        pw.SizedBox(height: 16),
      ],
    );
  }

  pw.Widget _pageFooter({
    required pw.Context context,
    required _Palette palette,
    required pw.Font bodyFont,
  }) {
    return pw.Column(
      children: [
        pw.Container(height: 1, color: palette.rule),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Private keepsake · Cardinal Memorials',
              style: pw.TextStyle(
                font: bodyFont,
                fontSize: 8,
                color: palette.muted,
              ),
            ),
            pw.Text(
              '${context.pageNumber}',
              style: pw.TextStyle(
                font: bodyFont,
                fontSize: 8,
                color: palette.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Art {
  const _Art({required this.dogwood});

  final pw.MemoryImage dogwood;
}

class _Palette {
  const _Palette({
    required this.pageBg,
    required this.brand,
    required this.accent,
    required this.ink,
    required this.muted,
    required this.rule,
    required this.cardBg,
    required this.cardBorder,
    required this.chipBg,
    required this.chipText,
  });

  final PdfColor pageBg;
  final PdfColor brand;
  final PdfColor accent;
  final PdfColor ink;
  final PdfColor muted;
  final PdfColor rule;
  final PdfColor cardBg;
  final PdfColor cardBorder;
  final PdfColor chipBg;
  final PdfColor chipText;

  static _Palette forTheme(ExportTheme theme) {
    switch (theme) {
      case ExportTheme.journalPdf:
        return const _Palette(
          pageBg: PdfColor.fromInt(0xFFF7F1E8),
          brand: PdfColor.fromInt(0xFF6E1423),
          accent: PdfColor.fromInt(0xFFC4A35A),
          ink: PdfColor.fromInt(0xFF2C2419),
          muted: PdfColor.fromInt(0xFF6B7A5A),
          rule: PdfColor.fromInt(0xFFE8C4C4),
          cardBg: PdfColor.fromInt(0xFFFBF7F0),
          cardBorder: PdfColor.fromInt(0xFFE8C4C4),
          chipBg: PdfColor.fromInt(0xFFEDE4D4),
          chipText: PdfColor.fromInt(0xFF6E1423),
        );
      case ExportTheme.simple:
        return const _Palette(
          pageBg: PdfColor.fromInt(0xFFF9F7F4),
          brand: PdfColor.fromInt(0xFF2C2419),
          accent: PdfColor.fromInt(0xFF8A8074),
          ink: PdfColor.fromInt(0xFF2C2419),
          muted: PdfColor.fromInt(0xFF5C5348),
          rule: PdfColor.fromInt(0xFFD8D0C4),
          cardBg: PdfColor.fromInt(0xFFFFFDFB),
          cardBorder: PdfColor.fromInt(0xFFD8D0C4),
          chipBg: PdfColor.fromInt(0xFFF0EBE3),
          chipText: PdfColor.fromInt(0xFF5C5348),
        );
      case ExportTheme.inkSaver:
        return const _Palette(
          pageBg: PdfColors.white,
          brand: PdfColors.black,
          accent: PdfColors.grey700,
          ink: PdfColors.black,
          muted: PdfColors.grey700,
          rule: PdfColors.grey400,
          cardBg: PdfColors.white,
          cardBorder: PdfColors.grey400,
          chipBg: PdfColors.white,
          chipText: PdfColors.black,
        );
    }
  }
}

class _CoverPage extends pw.StatelessWidget {
  _CoverPage({
    required this.memorial,
    required this.bookType,
    required this.palette,
    required this.art,
    required this.titleFont,
    required this.titleItalic,
    required this.bodyFont,
    required this.entryCount,
    required this.theme,
    this.previewOnly = false,
  });

  final Memorial memorial;
  final KeepsakeBookType bookType;
  final _Palette palette;
  final _Art? art;
  final pw.Font titleFont;
  final pw.Font titleItalic;
  final pw.Font bodyFont;
  final int entryCount;
  final ExportTheme theme;
  final bool previewOnly;

  @override
  pw.Widget build(pw.Context context) {
    final lifeSpan = _lifeSpan(memorial);
    final relationship = memorial.relationship?.trim();
    final ornate = theme == ExportTheme.journalPdf;
    final format = context.page.pageFormat;
    final frameInset = ornate ? 36.0 : 44.0;
    final innerPad = ornate ? 40.0 : 36.0;

    final block = pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'LETTERS TO HEAVEN',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: bodyFont,
            fontSize: 9,
            color: palette.muted,
            letterSpacing: 2.4,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          bookType.title.toUpperCase(),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: bodyFont,
            fontSize: 10,
            color: palette.brand,
            letterSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(width: 56, height: 1, color: palette.accent),
        pw.SizedBox(height: 28),
        pw.Text(
          'In memory of',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: titleItalic,
            fontSize: 12,
            color: palette.muted,
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Text(
          memorial.displayName,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: titleFont,
            fontSize: 30,
            color: palette.brand,
            lineSpacing: 1.15,
          ),
        ),
        if (relationship != null && relationship.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text(
            relationship,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              font: bodyFont,
              fontSize: 12,
              color: palette.muted,
            ),
          ),
        ],
        if (lifeSpan != null) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            lifeSpan,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              font: bodyFont,
              fontSize: 11,
              color: palette.muted,
            ),
          ),
        ],
        pw.SizedBox(height: 28),
        pw.Text(
          entryCount == 1
              ? 'One memory, kept with care'
              : '$entryCount memories, kept with care',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: titleItalic,
            fontSize: 11,
            color: palette.muted,
          ),
        ),
        if (previewOnly) ...[
          pw.SizedBox(height: 16),
          pw.Text(
            'Private preview',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              font: bodyFont,
              fontSize: 9,
              color: palette.accent,
              letterSpacing: 1.1,
            ),
          ),
        ],
        if (art?.dogwood != null) ...[
          pw.SizedBox(height: ornate ? 36 : 28),
          pw.Image(
            art!.dogwood,
            height: theme == ExportTheme.journalPdf ? 110 : 96,
            fit: pw.BoxFit.contain,
          ),
        ] else if (theme != ExportTheme.inkSaver) ...[
          pw.SizedBox(height: 24),
          pw.Container(width: 40, height: 1, color: palette.rule),
        ],
        pw.SizedBox(height: 24),
        pw.Text(
          'A private memorial journal · Not therapy or medical advice',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: bodyFont,
            fontSize: 8,
            color: palette.muted,
          ),
        ),
      ],
    );

    return pw.Container(
      width: format.width,
      height: format.height,
      color: palette.pageBg,
      child: pw.Padding(
        padding: pw.EdgeInsets.all(frameInset),
        child: pw.Container(
          decoration: ornate
              ? pw.BoxDecoration(
                  border: pw.Border.all(color: palette.accent, width: 1.2),
                )
              : pw.BoxDecoration(
                  border: pw.Border.all(color: palette.rule, width: 0.8),
                ),
          child: pw.Padding(
            padding: pw.EdgeInsets.all(innerPad),
            child: pw.Center(child: block),
          ),
        ),
      ),
    );
  }

  static String? _lifeSpan(Memorial memorial) {
    final birth = memorial.birthDate;
    final passing = memorial.passingDate;
    if (birth == null && passing == null) {
      return null;
    }
    final b = birth == null ? '' : '${birth.year}';
    final p = passing == null ? '' : '${passing.year}';
    if (b.isEmpty) return p;
    if (p.isEmpty) return b;
    return '$b – $p';
  }
}

class _PdfPlacement {
  const _PdfPlacement({required this.placement, required this.image});

  final EntryPlacement placement;
  final pw.MemoryImage image;
}

class _EntryBlock extends pw.StatelessWidget {
  _EntryBlock({
    required this.entry,
    required this.placements,
    required this.media,
    required this.palette,
    required this.titleFont,
    required this.bodyFont,
    required this.bodyBold,
    required this.theme,
  });

  final Entry entry;
  final List<_PdfPlacement> placements;
  final List<MediaAttachment> media;
  final _Palette palette;
  final pw.Font titleFont;
  final pw.Font bodyFont;
  final pw.Font bodyBold;
  final ExportTheme theme;

  @override
  pw.Widget build(pw.Context context) {
    final date = entry.entryDate ?? entry.createdAt;
    final title = entry.title.trim().isEmpty
        ? (isVoiceKeepsake(entry) ? 'Voice keepsake' : entryTypeLabel(entry.type))
        : entry.title.trim();
    final body = entry.body.trim();
    final typeLabel = isVoiceKeepsake(entry)
        ? 'VOICE KEEPSAKE'
        : entryTypeLabel(entry.type).toUpperCase();
    final framed = theme == ExportTheme.journalPdf;
    final compact = theme == ExportTheme.inkSaver;
    final speaker = voiceSpeaker(entry)?.trim();
    final period = voiceTimePeriod(entry)?.trim();
    final transcript = voiceTranscript(entry)?.trim();
    MediaAttachment? audioMedia;
    for (final m in media) {
      final mime = m.mimeType ?? '';
      if (mime.startsWith('audio/') || mime.startsWith('video/')) {
        audioMedia = m;
        break;
      }
    }
    audioMedia ??= media.isEmpty ? null : media.first;
    final listenUrl = voicePrivateListenUrl(audioMedia);

    final content = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: framed
                  ? pw.BoxDecoration(
                      color: palette.chipBg,
                      borderRadius: pw.BorderRadius.circular(2),
                    )
                  : pw.BoxDecoration(
                      border: pw.Border.all(color: palette.rule, width: 0.6),
                    ),
              child: pw.Text(
                typeLabel,
                style: pw.TextStyle(
                  font: bodyBold,
                  fontSize: 7.5,
                  color: palette.chipText,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            if (date != null) ...[
              pw.SizedBox(width: 10),
              pw.Text(
                KeepsakePdfBuilder._shortDate.format(date),
                style: pw.TextStyle(
                  font: bodyFont,
                  fontSize: 9,
                  color: palette.muted,
                ),
              ),
            ],
            if (entry.isFavorite) ...[
              pw.Spacer(),
              pw.Text(
                '★',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: palette.accent,
                ),
              ),
            ],
          ],
        ),
        pw.SizedBox(height: compact ? 6 : 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            font: titleFont,
            fontSize: compact ? 13 : 14,
            color: palette.brand,
          ),
        ),
        if (theme == ExportTheme.journalPdf) ...[
          pw.SizedBox(height: 6),
          pw.Container(
            width: 36,
            height: 1.2,
            color: palette.accent,
          ),
        ],
        if (isVoiceKeepsake(entry)) ...[
          if (speaker != null && speaker.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Speaking: $speaker',
              style: pw.TextStyle(
                font: bodyFont,
                fontSize: 9,
                color: palette.muted,
              ),
            ),
          ],
          if (period != null && period.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'When: $period',
              style: pw.TextStyle(
                font: bodyFont,
                fontSize: 9,
                color: palette.muted,
              ),
            ),
          ],
        ],
        if (placements.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _PdfScrapbook(
            placements: placements,
            palette: palette,
            height: compact ? 160 : 190,
          ),
        ],
        if (body.isNotEmpty) ...[
          pw.SizedBox(height: compact ? 8 : 10),
          pw.Text(
            body,
            style: pw.TextStyle(
              font: bodyFont,
              fontSize: compact ? 10 : 10.5,
              color: palette.ink,
              lineSpacing: 1.45,
            ),
          ),
        ],
        if (transcript != null && transcript.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            'Transcript',
            style: pw.TextStyle(
              font: bodyBold,
              fontSize: 9,
              color: palette.brand,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            transcript,
            style: pw.TextStyle(
              font: bodyFont,
              fontSize: compact ? 9.5 : 10,
              color: palette.ink,
              lineSpacing: 1.4,
            ),
          ),
        ],
        if (isVoiceKeepsake(entry)) ...[
          pw.SizedBox(height: 12),
          if (listenUrl != null)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: listenUrl,
                  width: 64,
                  height: 64,
                  color: palette.ink,
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Text(
                    'Scan for private audio access.\n'
                    'Preserve not only what happened, but how they sounded.',
                    style: pw.TextStyle(
                      font: bodyFont,
                      fontSize: 8,
                      color: palette.muted,
                      lineSpacing: 1.35,
                    ),
                  ),
                ),
              ],
            )
          else
            pw.Text(
              'Audio lives privately with this journal. A QR link will appear '
              'in the PDF when encrypted backup can provide durable private '
              'access. Until then, the transcript above keeps the words safe '
              'on the page.\n'
              'We never generate new speech in a loved one’s voice.',
              style: pw.TextStyle(
                font: bodyFont,
                fontSize: 8,
                color: palette.muted,
                lineSpacing: 1.35,
              ),
            ),
        ],
        if (entry.tags.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final tag in entry.tags)
                pw.Text(
                  '#$tag',
                  style: pw.TextStyle(
                    font: bodyFont,
                    fontSize: 8,
                    color: palette.muted,
                  ),
                ),
            ],
          ),
        ],
      ],
    );

    if (framed) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 14),
        padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: pw.BoxDecoration(
          color: palette.cardBg,
          border: pw.Border.all(color: palette.cardBorder, width: 0.8),
        ),
        child: content,
      );
    }

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: compact ? 10 : 14),
      padding: pw.EdgeInsets.only(bottom: compact ? 10 : 14),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: palette.rule, width: 0.6),
        ),
      ),
      child: content,
    );
  }
}

class _PdfScrapbook extends pw.StatelessWidget {
  _PdfScrapbook({
    required this.placements,
    required this.palette,
    required this.height,
  });

  final List<_PdfPlacement> placements;
  final _Palette palette;
  final double height;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      height: height,
      width: double.infinity,
      decoration: pw.BoxDecoration(
        color: palette.pageBg,
        border: pw.Border.all(color: palette.rule, width: 0.7),
      ),
      child: pw.Stack(
        children: [
          for (final item in placements)
            pw.Positioned(
              left: item.placement.x * 460,
              top: item.placement.y * height,
              child: pw.Transform.rotate(
                angle: item.placement.rotation,
                child: pw.Image(
                  item.image,
                  width: (item.placement.scale * 460).clamp(48, 200),
                  height: (item.placement.scale * 460).clamp(48, 200),
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OnePageRemembrance extends pw.StatelessWidget {
  _OnePageRemembrance({
    required this.memorial,
    required this.entry,
    required this.placements,
    required this.palette,
    required this.titleFont,
    required this.titleItalic,
    required this.bodyFont,
    required this.bodyBold,
    required this.art,
    required this.theme,
  });

  final Memorial memorial;
  final Entry? entry;
  final List<_PdfPlacement> placements;
  final _Palette palette;
  final pw.Font titleFont;
  final pw.Font titleItalic;
  final pw.Font bodyFont;
  final pw.Font bodyBold;
  final _Art? art;
  final ExportTheme theme;

  @override
  pw.Widget build(pw.Context context) {
    final body = entry?.body.trim() ?? '';
    final title = entry?.title.trim() ?? '';
    return pw.Container(
      color: palette.pageBg,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'IN REMEMBRANCE',
            style: pw.TextStyle(
              font: bodyFont,
              fontSize: 9,
              color: palette.muted,
              letterSpacing: 2.2,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            memorial.displayName,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              font: titleFont,
              fontSize: 26,
              color: palette.brand,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(width: 48, height: 1, color: palette.accent),
          pw.SizedBox(height: 18),
          if (title.isNotEmpty)
            pw.Text(
              title,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: titleItalic,
                fontSize: 13,
                color: palette.ink,
              ),
            ),
          if (body.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text(
              body.length > 900 ? '${body.substring(0, 900)}…' : body,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: bodyFont,
                fontSize: 11,
                color: palette.ink,
                lineSpacing: 1.45,
              ),
            ),
          ],
          if (placements.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Image(
              placements.first.image,
              height: 160,
              fit: pw.BoxFit.contain,
            ),
          ] else if (art != null) ...[
            pw.SizedBox(height: 24),
            pw.Image(art!.dogwood, height: 72, fit: pw.BoxFit.contain),
          ],
          pw.Spacer(),
          pw.Text(
            'Letters to Heaven · Cardinal Memorials',
            style: pw.TextStyle(
              font: bodyFont,
              fontSize: 8,
              color: palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Closing extends pw.StatelessWidget {
  _Closing({
    required this.palette,
    required this.titleItalic,
    required this.bodyFont,
  });

  final _Palette palette;
  final pw.Font titleItalic;
  final pw.Font bodyFont;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(height: 8),
        pw.Container(width: 64, height: 1, color: palette.rule),
        pw.SizedBox(height: 14),
        pw.Text(
          'Held with love.',
          style: pw.TextStyle(
            font: titleItalic,
            fontSize: 11,
            color: palette.muted,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Letters to Heaven by Cardinal Memorials',
          style: pw.TextStyle(
            font: bodyFont,
            fontSize: 8,
            color: palette.muted,
          ),
        ),
      ],
    );
  }
}
