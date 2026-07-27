import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/media/local_file_io.dart'
    if (dart.library.html) '../../core/media/local_file_web.dart' as io;
import '../../core/state/app_scope.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../data/models/models.dart';

class DataRightsScreen extends StatefulWidget {
  const DataRightsScreen({super.key});

  @override
  State<DataRightsScreen> createState() => _DataRightsScreenState();
}

class _DataRightsScreenState extends State<DataRightsScreen> {
  bool _busy = false;

  Future<void> _exportPlainText() async {
    setState(() => _busy = true);
    final app = AppScope.of(context);
    final uid = app.uid;
    final memorials =
        uid == null ? <Memorial>[] : await app.repository.listMemorials(ownerUid: uid);
    final buffer = StringBuffer();
    buffer.writeln('Letters to Heaven — plain-text export');
    buffer.writeln('Exported ${DateTime.now().toIso8601String()}');
    buffer.writeln();
    for (final m in memorials) {
      buffer.writeln('=== ${m.displayName} ===');
      buffer.writeln();
      final entries = await app.repository.listEntries(memorialId: m.id);
      for (final e in entries) {
        final title = e.title.trim().isEmpty ? e.type.name : e.title.trim();
        buffer.writeln(title);
        if (e.body.trim().isNotEmpty) {
          buffer.writeln(e.body.trim());
        }
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
    }
    final text = buffer.toString();
    if (kIsWeb) {
      await Share.share(text, subject: 'Letters to Heaven plain-text export');
    } else {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/letters_to_heaven_export.txt';
      await io.writeBytes(path, utf8.encode(text));
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Letters to Heaven plain-text export',
      );
    }
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  Future<void> _exportJson() async {
    setState(() => _busy = true);
    final app = AppScope.of(context);
    final uid = app.uid;
    final memorials =
        uid == null ? <Memorial>[] : await app.repository.listMemorials(ownerUid: uid);
    final entries = <Entry>[];
    for (final m in memorials) {
      entries.addAll(await app.repository.listEntries(memorialId: m.id));
    }
    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'memorials': memorials.map((m) => m.toJson()).toList(),
      'entries': entries.map((e) => e.toJson()).toList(),
    };
    final json = jsonEncode(payload);
    if (kIsWeb) {
      await Share.share(json, subject: 'Letters to Heaven data export');
    } else {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/letters_to_heaven_export.json';
      await io.writeBytes(path, utf8.encode(json));
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Letters to Heaven data export',
      );
    }
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all local data?'),
        content: const Text(
          'This permanently removes memorials and entries stored on this device.',
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
    if (ok != true || !mounted) {
      return;
    }
    final app = AppScope.of(context);
    await app.repository.wipeLocalData();
    await app.wipeSession();
    if (mounted) {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('Your data'),
        intro:
            'You control every export. Delete your data whenever you choose. '
            'Existing memories remain available after cancellation.',
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FilledButton(
            onPressed: _busy ? null : _exportPlainText,
            child: const Text('Export plain text'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : _exportJson,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Export basic data (JSON)'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _deleteAccount,
            child: const Text('Delete account data on this device'),
          ),
        ],
      ),
    );
  }
}
