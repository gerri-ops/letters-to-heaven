import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import 'prompt_mood.dart';
import 'prompt_picker.dart';

/// One question at a time — optional, skippable, never centered as homework.
Future<void> showOptionalPromptSheet(BuildContext context) async {
  final app = AppScope.of(context);
  Prompt? current = await PromptPicker.pickOne(app: app);
  final shownIds = <String>[
    if (current != null) current.id,
  ];

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          Future<void> showAnother() async {
            final next = await PromptPicker.pickOne(
              app: app,
              exclude: current,
              alsoExcludeIds: shownIds,
            );
            if (next != null) {
              shownIds.add(next.id);
              setLocal(() => current = next);
            }
          }

          Future<void> notToday() async {
            final id = current?.id;
            if (id != null) {
              await app.dismissHomePrompt(id);
            }
            if (sheetContext.mounted) {
              Navigator.pop(sheetContext);
            }
          }

          void writeFromThis() {
            final question = current?.text ??
                'What would you tell them about today?';
            PrivacySafeAnalytics.instance.log('prompt_opened');
            Navigator.pop(sheetContext);
            final encoded = Uri.encodeComponent('$question\n\n');
            final idQuery =
                current == null ? '' : '&promptId=${current!.id}';
            context.push('/entry/new?type=letter&body=$encoded$idQuery');
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'One question',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Optional. You can leave it and write something else.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedInk,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final mood in PromptMood.values)
                        ChoiceChip(
                          label: Text(mood.label),
                          selected: app.promptMood == mood,
                          onSelected: (_) async {
                            if (mood == PromptMood.deeperReflection &&
                                !app.allowDifficultPrompts) {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Deeper reflection'),
                                  content: const Text(
                                    'These questions may touch anger, guilt, '
                                    'apology, or difficult relationships. '
                                    'Only continue if you want that today.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Not now'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text('I consent'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await app.setAllowDifficultPrompts(true);
                                await app.setPromptMood(mood);
                              }
                            } else {
                              await app.setPromptMood(mood);
                            }
                            final next =
                                await PromptPicker.pickOne(app: app);
                            setLocal(() {
                              current = next;
                              if (next != null) {
                                shownIds
                                  ..clear()
                                  ..add(next.id);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    current?.text ??
                        'What would you tell them about today?',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: writeFromThis,
                    child: const Text('Write from this'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: showAnother,
                    child: const Text('Show Me Another'),
                  ),
                  TextButton(
                    onPressed: notToday,
                    child: const Text('Not Today'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
