import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/billing/premium_upgrade_sheet.dart';
import '../../core/billing/trust_paywall_copy.dart';
import '../../core/reminders/reminder_copy.dart';
import '../../core/reminders/reminder_opt_in_sheet.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../data/models/models.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<RemembranceDate> _dates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final app = AppScope.of(context);
    final memorial = app.currentMemorial;
    var dates = <RemembranceDate>[];
    if (memorial != null) {
      dates = await app.repository.listRemembranceDates(memorial.id);
    }
    if (mounted) {
      setState(() {
        _dates = dates;
        _loading = false;
      });
    }
  }

  Future<void> _addDate() async {
    final app = AppScope.of(context);
    final memorial = app.currentMemorial;
    if (memorial == null || app.uid == null) {
      return;
    }
    if (!app.premium) {
      await showPremiumUpgradeSheet(
        context,
        title: 'Private remembrance dates',
        body: '',
        trigger: PaywallTrigger.browsePlans,
      );
      return;
    }

    final labelController = TextEditingController();
    DateTime selected = DateTime.now();
    var time = TimeOfDay(
      hour: app.reminderDefaultHour,
      minute: app.reminderDefaultMinute,
    );
    var recurring = true;
    var notifyEnabled = app.remindersWanted;
    var showName = app.reminderShowLovedOneName;
    var showPhotos = app.reminderShowPhotos;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Add remembrance date'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label (birthday, anniversary…)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(DateFormat.yMMMd().format(selected)),
                      subtitle: const Text('Exact date'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selected,
                          firstDate: DateTime(1900),
                          lastDate:
                              DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setLocal(() => selected = picked);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(time.format(ctx)),
                      subtitle: const Text('Time of day'),
                      trailing: const Icon(Icons.schedule),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: time,
                        );
                        if (picked != null) {
                          setLocal(() => time = picked);
                        }
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Quiet reminder'),
                      subtitle: const Text(
                        'Permission is requested only after you choose Remind Me.',
                      ),
                      value: notifyEnabled,
                      onChanged: (v) => setLocal(() => notifyEnabled = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Loved one’s name may appear'),
                      value: showName,
                      onChanged: (v) => setLocal(() => showName = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Photos may appear'),
                      value: showPhotos,
                      onChanged: (v) => setLocal(() => showPhotos = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Repeats yearly'),
                      value: recurring,
                      onChanged: (v) => setLocal(() => recurring = v),
                    ),
                    Text(
                      'Notification wording: “${ReminderCopy.notificationBody}”',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
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
            );
          },
        );
      },
    );

    if (saved != true || labelController.text.trim().isEmpty) {
      labelController.dispose();
      return;
    }

    await app.repository.upsertRemembranceDate(
      RemembranceDate(
        id: const Uuid().v4(),
        memorialId: memorial.id,
        ownerUid: app.uid!,
        label: labelController.text.trim(),
        date: selected,
        recurring: recurring,
        notifyEnabled: notifyEnabled,
        notifyHour: time.hour,
        notifyMinute: time.minute,
        showLovedOneName: showName,
        showPhotos: showPhotos,
        syncState: SyncState.pendingUpload,
      ),
    );
    await app.setReminderDefaultTime(hour: time.hour, minute: time.minute);
    await app.setReminderPrivacy(
      showLovedOneName: showName,
      showPhotos: showPhotos,
    );
    labelController.dispose();
    await _load();
    if (mounted) {
      await offerReminderOptInIfNeeded(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final paused = app.remindersPaused || app.reminderSilencePermanent;
    return Scaffold(
      appBar: const LettersAppBar(
        title: Text('Reminders'),
        intro:
            'Opt-in only. Reminders can be painful—pause or silence anytime.',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDate,
        icon: const Icon(Icons.add),
        label: const Text('Add date'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      ReminderCopy.notificationBody,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ReminderCopy.optInQuestion,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedInk,
                      ),
                ),
                SwitchListTile(
                  title: const Text('Temporary pause'),
                  subtitle: const Text('Pause all reminders for now'),
                  value: paused && !app.reminderSilencePermanent,
                  onChanged: (v) => app.setRemindersPaused(v),
                ),
                SwitchListTile(
                  title: const Text('Permanent silence'),
                  subtitle: const Text('Do not ask about reminders again'),
                  value: app.reminderSilencePermanent,
                  onChanged: (v) => app.setReminderSilencePermanent(v),
                ),
                SwitchListTile(
                  title: const Text('Loved one’s name may appear'),
                  value: app.reminderShowLovedOneName,
                  onChanged: (v) =>
                      app.setReminderPrivacy(showLovedOneName: v),
                ),
                SwitchListTile(
                  title: const Text('Photos may appear'),
                  value: app.reminderShowPhotos,
                  onChanged: (v) => app.setReminderPrivacy(showPhotos: v),
                ),
                const ListTile(
                  title: Text('Notification permission'),
                  subtitle: Text(
                    'Never requested on first launch. Asked only after you '
                    'save an entry, add a date, and choose Remind Me.',
                  ),
                ),
                const Divider(),
                if (_dates.isEmpty)
                  const ListTile(
                    title: Text('No remembrance dates yet'),
                    subtitle: Text(
                      'Add birthdays, anniversaries, or personal dates when ready.',
                    ),
                  )
                else
                  ..._dates.map(
                    (d) => ListTile(
                      title: Text(d.label),
                      subtitle: Text(
                        [
                          DateFormat.yMMMd().format(d.date),
                          TimeOfDay(
                            hour: d.notifyHour,
                            minute: d.notifyMinute,
                          ).format(context),
                          if (d.recurring) 'repeats',
                          if (d.pauseUntil != null) 'paused',
                        ].join(' · '),
                      ),
                      trailing: d.notifyEnabled
                          ? const Icon(Icons.notifications_active_outlined)
                          : const Icon(Icons.notifications_off_outlined),
                    ),
                  ),
                const SizedBox(height: 72),
              ],
            ),
    );
  }
}
