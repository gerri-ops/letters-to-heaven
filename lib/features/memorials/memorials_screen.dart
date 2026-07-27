import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/billing/plan_entitlements.dart';
import '../../core/billing/premium_upgrade_sheet.dart';
import '../../core/billing/trust_paywall_copy.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../data/models/models.dart';

/// List, switch, and add memorials. One is free; more require Premium.
class MemorialsScreen extends StatefulWidget {
  const MemorialsScreen({super.key});

  @override
  State<MemorialsScreen> createState() => _MemorialsScreenState();
}

class _MemorialsScreenState extends State<MemorialsScreen> {
  List<Memorial> _memorials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final app = AppScope.of(context);
    final uid = app.uid;
    final list = uid == null
        ? <Memorial>[]
        : await app.repository.listMemorials(ownerUid: uid);
    if (!mounted) {
      return;
    }
    setState(() {
      _memorials = list;
      _loading = false;
    });
  }

  Future<void> _select(Memorial memorial) async {
    final app = AppScope.of(context);
    await app.setCurrentMemorial(memorial);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Now remembering ${memorial.displayName}.'),
        ),
      );
      setState(() {});
    }
  }

  Future<void> _addAnother() async {
    final app = AppScope.of(context);
    final uid = app.uid;
    if (uid == null) {
      return;
    }
    final existing = await app.repository.listMemorials(ownerUid: uid);
    if (!PlanEntitlements.canCreateMemorial(
      premium: app.premium,
      existingMemorialCount: existing.length,
    )) {
      if (!mounted) return;
      await showPremiumUpgradeSheet(
        context,
        title: '',
        body: '',
        trigger: PaywallTrigger.secondMemorial,
      );
      return;
    }
    if (!mounted) return;
    await context.push('/memorial/new');
    if (mounted) {
      await _load();
    }
  }

  Future<void> _edit(Memorial memorial) async {
    final app = AppScope.of(context);
    final nameController = TextEditingController(text: memorial.displayName);
    final relController =
        TextEditingController(text: memorial.relationship ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit memorial'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: relController,
              decoration: const InputDecoration(labelText: 'Relationship'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final updated = memorial.copyWith(
        displayName: nameController.text.trim().isEmpty
            ? memorial.displayName
            : nameController.text.trim(),
        relationship: relController.text.trim().isEmpty
            ? null
            : relController.text.trim(),
      );
      await app.repository.updateMemorial(updated);
      if (app.currentMemorial?.id == memorial.id) {
        await app.setCurrentMemorial(
          (await app.repository.getMemorial(memorial.id)) ?? updated,
        );
      }
      await _load();
    }
    nameController.dispose();
    relController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final currentId = app.currentMemorial?.id;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('Memorials'),
        intro:
            'A separate private place for each person or pet you want to remember.',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  'Basic includes one memorial. Premium lets you keep more—'
                  'both parents, a spouse and a pet, family members, a friend '
                  'alongside a relative—without choosing whose memory gets a place.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                for (final m in _memorials)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: AppColors.parchment,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: m.id == currentId
                            ? AppColors.burgundy.withValues(alpha: 0.45)
                            : AppColors.softBlush.withValues(alpha: 0.6),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        m.id == currentId
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: AppColors.burgundy,
                      ),
                      title: Text(m.displayName),
                      subtitle: () {
                        final parts = <String>[
                          if (m.relationship != null &&
                              m.relationship!.trim().isNotEmpty)
                            m.relationship!,
                          if (m.id == currentId) 'Open now',
                        ];
                        return parts.isEmpty ? null : Text(parts.join(' · '));
                      }(),
                      trailing: IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _edit(m),
                      ),
                      onTap: m.id == currentId ? null : () => _select(m),
                    ),
                  ),
                if (_memorials.isEmpty)
                  Text(
                    'No memorial yet. Add who you want to remember.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedOlive,
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _addAnother,
                  child: const Text('Add another memorial'),
                ),
                if (!app.premium && _memorials.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    TrustPaywallCopy.secondMemorialHeadline,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedOlive,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
