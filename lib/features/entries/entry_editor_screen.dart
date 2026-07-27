import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/analytics/analytics.dart';
import '../../core/billing/plan_entitlements.dart';
import '../../core/billing/premium_upgrade_sheet.dart';
import '../../core/billing/trust_paywall_copy.dart';
import '../../core/media/local_media_store.dart';
import '../../core/media/local_only_media_banner.dart';
import '../../core/reviews/review_request_copy.dart';
import '../../core/reviews/review_request_service.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/artwork_assets.dart';
import '../../core/theme/artwork_image.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../core/utils/entry_helpers.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import 'emotional_exit_door.dart';
import 'entry_placement.dart';
import 'entry_scrapbook_canvas.dart';
import 'entry_templates.dart';

class EntryEditorScreen extends StatefulWidget {
  const EntryEditorScreen({
    super.key,
    this.entryId,
    this.initialType,
    this.initialBody,
    this.promptId,
    this.initialTemplateId,
  });

  final String? entryId;
  final EntryType? initialType;
  final String? initialBody;
  final String? promptId;
  final String? initialTemplateId;

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagsController = TextEditingController();
  final _extControllers = <String, TextEditingController>{};
  final _mediaStore = LocalMediaStore();
  static const _uuid = Uuid();
  static final _dateFormat = DateFormat.yMMMd();

  EntryType _type = EntryType.memory;
  EntryStatus _status = EntryStatus.draft;
  DateTime? _entryDate;
  bool _favorite = false;
  bool _hiddenFromExport = false;
  bool _hiddenFromHome = false;
  DateTime? _privateReturnDate;
  bool _loading = true;
  bool _saving = false;
  String? _existingId;
  DateTime? _createdAt;
  Timer? _autosaveTimer;
  bool _firstSaveLogged = false;
  final List<String> _photoPaths = [];
  final List<String> _mediaIds = [];
  final Set<String> _pendingMediaDeletes = {};
  List<EntryPlacement> _placements = [];
  String? _selectedPlacementId;
  String? _templateId;

  EntryTypeTemplate get _template => templateFor(_type);

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? EntryType.memory;
    _templateId = widget.initialTemplateId;
    _entryDate = DateTime.now();
    _ensureExtControllers(_template);
    if (widget.initialBody != null) {
      _bodyController.text = widget.initialBody!;
    }
    _autosaveTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _save(draft: true, silent: true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _ensureExtControllers(EntryTypeTemplate template) {
    for (final field in template.fields) {
      _extControllers.putIfAbsent(field.key, TextEditingController.new);
    }
  }

  TextEditingController _ext(String key) =>
      _extControllers.putIfAbsent(key, TextEditingController.new);

  Future<void> _load() async {
    if (widget.entryId != null) {
      final entry =
          await AppScope.of(context).repository.getEntryById(widget.entryId!);
      if (entry != null && mounted) {
        _existingId = entry.id;
        _createdAt = entry.createdAt;
        _type = entry.type;
        _status = entry.status;
        _favorite = entry.isFavorite;
        _hiddenFromExport = entry.hiddenFromExport;
        _hiddenFromHome = entry.hiddenFromHome;
        _privateReturnDate = entry.privateReturnDate;
        _entryDate = entry.entryDate ?? entry.createdAt ?? DateTime.now();
        _titleController.text = entry.title;
        _bodyController.text = entry.body;
        _tagsController.text = entry.tags.join(', ');
        _ensureExtControllers(templateFor(_type));
        for (final field in templateFor(_type).fields) {
          _ext(field.key).text =
              entry.extensionJson[field.key]?.toString() ?? '';
        }
        // Preserve any known legacy keys even if not on current template.
        for (final key in entry.extensionJson.keys) {
          if (key == 'stickers' || key == 'placements' || key == 'template') {
            continue;
          }
          final value = entry.extensionJson[key];
          if (value != null && value.toString().isNotEmpty) {
            _ext(key).text = value.toString();
          }
        }
        _templateId = entry.extensionJson['template']?.toString();
        _mediaIds
          ..clear()
          ..addAll(entry.mediaIds);
        final media =
            await AppScope.of(context).repository.listMediaForEntry(entry.id);
        final pathByMediaId = {
          for (final m in media) m.id: m.localPath,
        };
        _photoPaths
          ..clear()
          ..addAll(media.map((m) => m.localPath));
        final hasSavedLayout = entry.extensionJson.containsKey('placements');
        _placements = placementsFromExtension(entry.extensionJson).map((p) {
          if ((p.localPath == null || p.localPath!.isEmpty) &&
              p.mediaId != null) {
            return p.copyWith(localPath: pathByMediaId[p.mediaId!]);
          }
          return p;
        }).toList();
        // Legacy entries without a placements layout: seed once from media.
        // Once placements exist (even empty), do not resurrect removed photos.
        if (!hasSavedLayout) {
          for (final m in media) {
            final already = _placements.any((p) => p.mediaId == m.id);
            if (!already) {
              _placements.add(
                EntryPlacement(
                  id: _uuid.v4(),
                  mediaId: m.id,
                  localPath: m.localPath,
                  x: 0.1 + (_placements.length % 3) * 0.28,
                  y: 0.12 + (_placements.length ~/ 3) * 0.3,
                  scale: 0.32,
                ),
              );
            }
          }
        }
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _onTypeChanged(EntryType type) {
    setState(() {
      _type = type;
      _templateId = null;
      _ensureExtControllers(templateFor(type));
    });
  }

  Future<void> _pickEntryDate() async {
    final now = DateTime.now();
    final initial = _entryDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null && mounted) {
      setState(() => _entryDate = picked);
    }
  }

  Future<void> _addPhoto() async {
    final app = AppScope.of(context);
    final currentCount = _placements.length;
    if (!PlanEntitlements.canAddPhoto(
      premium: app.premium,
      currentPhotoCount: currentCount,
    )) {
      await showPremiumUpgradeSheet(
        context,
        title: 'Unlimited photos',
        body: '',
        trigger: PaywallTrigger.browsePlans,
      );
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (file == null || !mounted) {
      return;
    }
    final path = await _mediaStore.persistImage(
      sourcePath: file.path,
      ownerUid: app.uid,
    );
    final mediaId = _uuid.v4();
    final placement = EntryPlacement(
      id: _uuid.v4(),
      mediaId: mediaId,
      localPath: path,
      x: 0.18 + (_placements.length % 3) * 0.06,
      y: 0.18 + (_placements.length % 2) * 0.08,
      scale: 0.36,
    );
    if (mounted) {
      setState(() {
        _photoPaths.add(path);
        _mediaIds.add(mediaId);
        _placements = [..._placements, placement];
        _selectedPlacementId = placement.id;
      });
    }
  }

  Map<String, dynamic> _extensionJson() {
    final map = <String, dynamic>{};
    for (final field in _template.fields) {
      final value = _ext(field.key).text.trim();
      if (value.isNotEmpty) {
        map[field.key] = value;
      }
    }
    if (_templateId != null && _templateId!.isNotEmpty) {
      map['template'] = _templateId;
    }
    // Always persist placements (including empty) so removals stick.
    map['placements'] = _placements.map((p) => p.toJson()).toList();
    return map;
  }

  void _removeSelected() {
    final id = _selectedPlacementId;
    if (id == null) {
      return;
    }
    EntryPlacement? removed;
    for (final p in _placements) {
      if (p.id == id) {
        removed = p;
        break;
      }
    }
    setState(() {
      _placements = _placements.where((p) => p.id != id).toList();
      if (removed?.localPath != null) {
        _photoPaths.remove(removed!.localPath);
      }
      if (removed?.mediaId != null) {
        _mediaIds.remove(removed!.mediaId);
        _pendingMediaDeletes.add(removed.mediaId!);
      }
      _selectedPlacementId = null;
    });
  }

  void _nudgeSelectedScale(double delta) {
    final id = _selectedPlacementId;
    if (id == null) {
      return;
    }
    setState(() {
      _placements = [
        for (final p in _placements)
          if (p.id == id)
            p.copyWith(scale: (p.scale + delta).clamp(0.08, 0.95))
          else
            p,
      ];
    });
  }

  List<String> _parseTags() {
    return _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  Future<String?> _save({
    required bool draft,
    bool silent = false,
    bool stepAway = false,
  }) async {
    if (_loading || _saving) {
      return null;
    }
    final app = AppScope.of(context);
    final memorial = app.currentMemorial;
    final uid = app.uid;
    if (memorial == null || uid == null) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set up a memorial first.')),
        );
      }
      return null;
    }
    final hasExtContent = _template.fields.any(
      (f) => _ext(f.key).text.trim().isNotEmpty,
    );
    if (_bodyController.text.trim().isEmpty &&
        _titleController.text.trim().isEmpty &&
        _placements.isEmpty &&
        !hasExtContent) {
      if (stepAway && mounted) {
        context.go('/shell/home');
      }
      return null;
    }
    setState(() => _saving = true);
    final entryId = _existingId ?? _uuid.v4();
    final existingMedia = await app.repository.listMediaForEntry(entryId);
    final knownPaths = {
      for (final m in existingMedia) m.localPath: m.id,
    };
    final mediaIds = <String>[];

    for (final placement in _placements) {
      final path = placement.localPath;
      if (path == null) {
        continue;
      }
      final existingId = knownPaths[path] ?? placement.mediaId;
      if (existingId != null &&
          existingMedia.any((m) => m.id == existingId)) {
        if (!mediaIds.contains(existingId)) {
          mediaIds.add(existingId);
        }
        continue;
      }
      if (knownPaths.containsKey(path)) {
        final id = knownPaths[path]!;
        if (!mediaIds.contains(id)) {
          mediaIds.add(id);
        }
        continue;
      }
      final mediaId = placement.mediaId ?? _uuid.v4();
      await app.repository.upsertMedia(
        MediaAttachment(
          id: mediaId,
          entryId: entryId,
          ownerUid: uid,
          localPath: path,
          mimeType: 'image/jpeg',
          syncState: SyncState.localOnly,
          createdAt: DateTime.now(),
        ),
      );
      if (!mediaIds.contains(mediaId)) {
        mediaIds.add(mediaId);
      }
    }

    // Drop media removed from the page (and any other orphans for this entry).
    final deleteIds = <String>{
      ..._pendingMediaDeletes,
      for (final m in existingMedia)
        if (!mediaIds.contains(m.id)) m.id,
    };
    for (final id in deleteIds) {
      await app.repository.deleteMedia(id);
    }
    _pendingMediaDeletes.clear();
    _mediaIds
      ..clear()
      ..addAll(mediaIds);

    final entry = Entry(
      id: entryId,
      memorialId: memorial.id,
      ownerUid: uid,
      type: _type,
      title: _titleController.text.trim(),
      body: _bodyController.text,
      status: draft ? EntryStatus.draft : EntryStatus.saved,
      isFavorite: _favorite,
      hiddenFromExport: _hiddenFromExport,
      hiddenFromHome: _hiddenFromHome,
      privateReturnDate: _privateReturnDate,
      promptId: widget.promptId,
      tags: _parseTags(),
      mediaIds: mediaIds,
      extensionJson: _extensionJson(),
      entryDate: _entryDate ?? DateTime.now(),
      createdAt: _createdAt,
    );
    try {
      final saved = await app.repository.upsertEntry(entry);
      _existingId = saved.id;
      _mediaIds
        ..clear()
        ..addAll(saved.mediaIds);
      _status = saved.status;
      app.notifyContentChanged();
      // Push journal text (+ photos if backup is on) for registered accounts.
      // ignore: unawaited_futures
      app.syncService.syncNow(displayName: app.displayName, email: app.email);
      if (!draft) {
        PrivacySafeAnalytics.instance.logEntrySaved(type: _type.name);
        if (!_firstSaveLogged) {
          PrivacySafeAnalytics.instance.log('first_entry_saved');
          _firstSaveLogged = true;
        }
        // Never ask after a letter. Third memory is a safe success moment.
        if (_type == EntryType.memory && mounted) {
          final memories = await app.repository.listEntries(
            memorialId: memorial.id,
          );
          final savedMemories = memories
              .where(
                (e) =>
                    e.type == EntryType.memory &&
                    e.status == EntryStatus.saved &&
                    !e.isDeleted,
              )
              .length;
          if (savedMemories >= 3) {
            if (stepAway) {
              await ReviewRequestService.instance.queueTrigger(
                ReviewTrigger.thirdMemoryPreserved,
              );
            } else if (mounted) {
              await ReviewRequestService.instance.maybeAsk(
                context,
                trigger: ReviewTrigger.thirdMemoryPreserved,
              );
            }
          }
        }
      }
      if (stepAway && mounted) {
        await showEmotionalExitDoor(context, entryId: saved.id);
        return saved.id;
      }
      if (!silent && mounted) {
        if (!draft && app.shouldShowFirstSaveSuccess(isDraft: false)) {
          await app.markFirstSaveSuccessSeen();
          if (mounted) {
            if (!app.hasCloudAccount) {
              context.go('/protect-memories');
            } else {
              if (!app.onboardingComplete) {
                await app.completeOnboarding();
              }
              if (mounted) {
                context.go('/first-save-success?entryId=$entryId');
              }
            }
          }
          return saved.id;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(draft ? 'Draft saved' : 'Saved')),
        );
        if (!draft) {
          context.pop();
        }
      }
      return saved.id;
    } on EntryLimitExceeded catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
    return null;
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    for (final c in _extControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final template = _template;
    final isNew = widget.entryId == null;

    return Scaffold(
      appBar: LettersAppBar(
        title: Text(isNew ? template.newTitle : template.editTitle),
        intro: 'Write at your own pace. Nothing has to be perfect.',
        actions: [
          IconButton(
            icon: Icon(_favorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () => setState(() => _favorite = !_favorite),
          ),
          TextButton(
            onPressed: _saving
                ? null
                : () => _save(draft: false, stepAway: true),
            child: const Text('Step away'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const LocalOnlyMediaBanner(),
          DropdownButtonFormField<EntryType>(
            key: ValueKey(_type),
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'What is this?'),
            items: EntryType.values
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(entryTypeLabel(t)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                _onTypeChanged(v);
              }
            },
          ),
          if (template.templateOptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Optional starting point',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedOlive,
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in template.templateOptions)
                  FilterChip(
                    avatar: option.id == 'cardinal'
                        ? const Padding(
                            padding: EdgeInsets.all(2),
                            child: ArtworkImage(
                              asset: ArtworkAssets.cardinal,
                              height: 18,
                              width: 18,
                              fit: BoxFit.contain,
                            ),
                          )
                        : null,
                    label: Text(option.label),
                    selected: _templateId == option.id,
                    showCheckmark: false,
                    onSelected: (selected) {
                      setState(() {
                        _templateId = selected ? option.id : null;
                      });
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.parchment,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.softBlush.withValues(alpha: 0.7),
              ),
            ),
            child: Text(
              template.guidance,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedOlive,
                  ),
            ),
          ),
          if (template.showEntryDate) ...[
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(template.entryDateLabel),
              subtitle: Text(
                _entryDate == null
                    ? 'Choose a date'
                    : _dateFormat.format(_entryDate!),
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickEntryDate,
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: template.titleLabel,
              hintText: template.titleHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            decoration: InputDecoration(
              labelText: template.bodyLabel,
              hintText: template.bodyHint,
              alignLabelWithHint: true,
            ),
            maxLines: template.bodyMaxLines,
          ),
          for (final field in template.fields) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _ext(field.key),
              decoration: InputDecoration(
                labelText: field.label,
                hintText: field.hint,
                alignLabelWithHint: field.maxLines > 1,
              ),
              maxLines: field.maxLines,
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (comma separated)',
              hintText: 'Optional labels to find this later',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Page layout',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Add photos to the page, then drag to arrange them.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedOlive,
                ),
          ),
          const SizedBox(height: 8),
          EntryScrapbookCanvas(
            placements: _placements,
            editable: true,
            selectedId: _selectedPlacementId,
            onSelect: (id) => setState(() => _selectedPlacementId = id),
            onChanged: (next) => setState(() => _placements = next),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: _addPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Insert photo'),
              ),
              if (_selectedPlacementId != null) ...[
                IconButton(
                  tooltip: 'Make smaller',
                  onPressed: () => _nudgeSelectedScale(-0.08),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  tooltip: 'Make larger',
                  onPressed: () => _nudgeSelectedScale(0.08),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                IconButton(
                  tooltip: 'Remove from page',
                  onPressed: _removeSelected,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
          SwitchListTile(
            title: const Text('Hide from Home'),
            subtitle: const Text(
              'Keeps photographs and memories out of Home without deleting them',
            ),
            value: _hiddenFromHome,
            onChanged: (v) => setState(() {
              _hiddenFromHome = v;
              if (!v) {
                _privateReturnDate = null;
              }
            }),
          ),
          SwitchListTile(
            title: const Text('Hide from export'),
            subtitle: const Text('Skip this entry in PDF exports'),
            value: _hiddenFromExport,
            onChanged: (v) => setState(() => _hiddenFromExport = v),
          ),
          if (_status == EntryStatus.draft)
            Text(
              'Draft — autosaves every 8 seconds',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving
                ? null
                : () => _save(draft: false, stepAway: true),
            child: const Text(EmotionalExitCopy.buttonLabel),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _save(draft: true),
                  child: const Text('Save draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _saving ? null : () => _save(draft: false),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
