import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../core/utils/entry_helpers.dart';
import '../../data/models/models.dart';
import 'entry_placement.dart';
import 'entry_scrapbook_canvas.dart';
import 'entry_templates.dart';

class EntryDetailScreen extends StatefulWidget {
  const EntryDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  Entry? _entry;
  List<EntryPlacement> _placements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = AppScope.of(context).repository;
    final entry = await repo.getEntryById(widget.entryId);
    if (entry == null) {
      if (mounted) {
        setState(() {
          _entry = null;
          _loading = false;
        });
      }
      return;
    }
    final media = await repo.listMediaForEntry(entry.id);
    if (!mounted) {
      return;
    }
    final pathByMediaId = {for (final m in media) m.id: m.localPath};
    final hasSavedLayout = entry.extensionJson.containsKey('placements');
    final placements = placementsFromExtension(entry.extensionJson).map((p) {
      if ((p.localPath == null || p.localPath!.isEmpty) && p.mediaId != null) {
        return p.copyWith(localPath: pathByMediaId[p.mediaId!]);
      }
      return p;
    }).toList();

    // Legacy entries without a placements layout: seed once from media.
    if (!hasSavedLayout) {
      for (final m in media) {
        final already = placements.any((p) => p.mediaId == m.id);
        if (!already) {
          placements.add(
            EntryPlacement(
              id: 'detail-${m.id}',
              mediaId: m.id,
              localPath: m.localPath,
              x: 0.1 + (placements.length % 3) * 0.28,
              y: 0.12 + (placements.length ~/ 3) * 0.3,
              scale: 0.32,
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _entry = entry;
        _placements = placements;
        _loading = false;
      });
    }
  }

  Future<void> _toggleHideFromHome() async {
    final entry = _entry;
    if (entry == null) {
      return;
    }
    final app = AppScope.of(context);
    final hide = entry.isVisibleOnHome;
    final updated = entry.copyWith(
      hiddenFromHome: hide,
      clearPrivateReturnDate: !hide,
    );
    await app.repository.upsertEntry(updated);
    app.notifyContentChanged();
    if (!mounted) {
      return;
    }
    setState(() => _entry = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hide
              ? 'Hidden from Home. Still in Library and Search.'
              : 'Showing on Home again.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final entry = _entry;
    if (entry == null) {
      return const Scaffold(
        appBar: LettersAppBar(
          showDogwood: false,
          intro: 'This entry could not be found.',
        ),
        body: Center(child: Text('Entry not found')),
      );
    }
    final date = entry.entryDate ?? entry.updatedAt ?? entry.createdAt;
    final details = _detailRows(entry);
    final hiddenFromHome = !entry.isVisibleOnHome;

    return Scaffold(
      appBar: LettersAppBar(
        title: Text(
          entry.title.isEmpty ? entryTypeLabel(entry.type) : entry.title,
        ),
        showDogwood: false,
        intro: 'A moment you have saved.',
        actions: [
          IconButton(
            tooltip: hiddenFromHome ? 'Show on Home' : 'Hide from Home',
            icon: Icon(
              hiddenFromHome
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: _toggleHideFromHome,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/entry/${entry.id}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete entry?'),
                  content: const Text(
                    'This removes the entry from your journal.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                final app = AppScope.of(context);
                await app.repository.softDelete(entry.id);
                // ignore: unawaited_futures
                app.syncCloud();
                if (context.mounted) {
                  app.notifyContentChanged();
                  context.pop();
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            entryTypeLabel(entry.type),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (date != null)
            Text(
              DateFormat.yMMMd().format(date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (hiddenFromHome) ...[
            const SizedBox(height: 8),
            Text(
              entry.privateReturnDate != null
                  ? 'Hidden from Home until '
                      '${DateFormat.yMMMd().format(entry.privateReturnDate!)}'
                  : 'Hidden from Home — still in Library and Search',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedOlive,
                  ),
            ),
          ],
          if (_placements.isNotEmpty) ...[
            const SizedBox(height: 16),
            EntryScrapbookCanvas(
              placements: _placements,
              editable: false,
              height: 260,
            ),
          ],
          const SizedBox(height: 16),
          if (entry.body.trim().isNotEmpty)
            Text(entry.body, style: Theme.of(context).textTheme.bodyLarge),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.burgundy,
                  ),
            ),
            const SizedBox(height: 8),
            for (final row in details) ...[
              Text(
                row.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.mutedOlive,
                    ),
              ),
              const SizedBox(height: 2),
              Text(row.value, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
            ],
          ],
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              children: entry.tags.map((t) => Chip(label: Text(t))).toList(),
            ),
          ],
        ],
      ),
    );
  }

  List<({String label, String value})> _detailRows(Entry entry) {
    final rows = <({String label, String value})>[];
    final template = templateFor(entry.type);
    final seen = <String>{};

    for (final field in template.fields) {
      final raw = entry.extensionJson[field.key]?.toString().trim() ?? '';
      if (raw.isEmpty) {
        continue;
      }
      rows.add((label: field.label, value: raw));
      seen.add(field.key);
    }

    for (final entryField in entry.extensionJson.entries) {
      if (entryField.key == 'stickers' ||
          entryField.key == 'placements' ||
          seen.contains(entryField.key)) {
        continue;
      }
      final value = entryField.value?.toString().trim() ?? '';
      if (value.isEmpty) {
        continue;
      }
      final label =
          fieldLabelForKey(entry.type, entryField.key) ?? entryField.key;
      rows.add((label: label, value: value));
    }
    return rows;
  }
}
