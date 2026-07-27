import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/analytics/analytics.dart';
import '../../core/billing/premium_upgrade_sheet.dart';
import '../../core/billing/trust_paywall_copy.dart';
import '../../core/media/local_media_store.dart';
import '../../core/media/local_path_image.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../data/repositories/app_repository.dart';

class MemorialSetupScreen extends StatefulWidget {
  const MemorialSetupScreen({super.key, this.isAdditional = false});

  /// True when adding a second (or later) memorial after onboarding.
  final bool isAdditional;

  @override
  State<MemorialSetupScreen> createState() => _MemorialSetupScreenState();
}

class _MemorialSetupScreenState extends State<MemorialSetupScreen> {
  final _nameController = TextEditingController();
  final _mediaStore = LocalMediaStore();
  String? _relationship;
  String? _photoPath;
  bool _saving = false;
  bool _showMore = false;

  static const _relationships = [
    'Parent',
    'Child',
    'Sibling',
    'Spouse or partner',
    'Grandparent',
    'Friend',
    'Pet',
    'Other',
  ];

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (file == null || !mounted) {
      return;
    }
    final app = AppScope.of(context);
    await app.ensureLocalSession();
    final persisted = await _mediaStore.persistImage(
      sourcePath: file.path,
      ownerUid: app.uid,
    );
    if (mounted) {
      setState(() => _photoPath = persisted);
    }
  }

  Future<void> _continue() async {
    final app = AppScope.of(context);
    await app.ensureLocalSession();
    final uid = app.uid;
    if (uid == null) {
      return;
    }
    final name = _nameController.text.trim();
    final displayName = name.isEmpty ? 'Someone I miss' : name;
    setState(() => _saving = true);
    try {
      const uuid = Uuid();
      final memorial = await app.repository.createMemorial(
        id: uuid.v4(),
        ownerUid: uid,
        displayName: displayName,
        relationship: _relationship,
        photoUrl: _photoPath,
      );
      await app.setCurrentMemorial(memorial);
      PrivacySafeAnalytics.instance.log('memorial_created');
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      if (widget.isAdditional) {
        app.notifyContentChanged();
        context.go('/shell/home');
      } else {
        context.push('/privacy');
      }
    } on MemorialLimitExceeded catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      await showPremiumUpgradeSheet(
        context,
        title: '',
        body: '',
        trigger: PaywallTrigger.secondMemorial,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save memorial: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: LettersAppBar(
        title: Text(
          widget.isAdditional
              ? 'Who else would you like to remember?'
              : 'Who would you like to remember?',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.isAdditional
                ? 'Make a separate private place for each person or pet. '
                    'A name is enough.'
                : 'A name is enough. Everything else is optional.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.mutedInk,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Optional — you can add this later',
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _showMore = !_showMore),
            child: Text(_showMore ? 'Hide optional details' : 'Add optional details'),
          ),
          if (_showMore) ...[
            DropdownButtonFormField<String>(
              key: ValueKey(_relationship),
              initialValue: _relationship,
              decoration: const InputDecoration(labelText: 'Relationship'),
              items: _relationships
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _relationship = v),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Photo'),
              subtitle: const Text('Optional'),
              trailing: OutlinedButton(
                onPressed: _pickPhoto,
                child: const Text('Choose'),
              ),
              leading: _photoPath != null
                  ? CircleAvatar(
                      child: ClipOval(
                        child: LocalPathImage(
                          path: _photoPath!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : const CircleAvatar(child: Icon(Icons.person_outline)),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _continue,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
