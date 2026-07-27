import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics.dart';
import '../../core/billing/plan_entitlements.dart';
import '../../core/billing/premium_upgrade_sheet.dart';
import '../../core/billing/trust_paywall_copy.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/letters_app_bar.dart';
import '../../data/models/models.dart';
import 'prompt_mood.dart';
import 'optional_prompt_sheet.dart';

class PromptsScreen extends StatefulWidget {
  const PromptsScreen({super.key});

  @override
  State<PromptsScreen> createState() => _PromptsScreenState();
}

class _PromptsScreenState extends State<PromptsScreen> {
  List<Prompt> _all = [];
  String? _categoryFilter;
  PromptMood? _moodFilter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/prompts/launch_prompts.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final prompts = (json['prompts'] as List<dynamic>)
        .map((e) => Prompt.fromJson(e as Map<String, dynamic>))
        .toList();
    if (mounted) {
      setState(() {
        _all = prompts;
        _loading = false;
      });
    }
  }

  List<Prompt> get _planPrompts {
    final app = AppScope.of(context);
    final hidden = app.hiddenPromptCategories;
    final forPlan = PlanEntitlements.promptsForPlan(
      all: _all,
      premium: app.premium,
    );
    return forPlan.where((p) {
      if (hidden.contains(p.category)) {
        return false;
      }
      if (_categoryFilter != null && p.category != _categoryFilter) {
        return false;
      }
      if (_moodFilter != null && !promptMatchesMood(p, _moodFilter!)) {
        return false;
      }
      if (!app.allowDifficultPrompts && promptNeedsDifficultConsent(p)) {
        return false;
      }
      if (app.isPromptOnDismissCooldown(p.id)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<String> get _categories {
    final list = _all.map((p) => p.category).toSet().toList();
    list.sort();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final app = AppScope.of(context);
    final visible = _planPrompts;
    final lockedCount = app.premium
        ? 0
        : (_all.length - PlanEntitlements.basicGentlePromptLimit)
            .clamp(0, _all.length);
    return Scaffold(
      appBar: LettersAppBar(
        title: const Text('Prompts'),
        intro:
            'Optional library—one question at a time when you want it. Never required.',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('cat-$_categoryFilter'),
                    initialValue: _categoryFilter,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ..._categories.map(
                        (c) => DropdownMenuItem(value: c, child: Text(c)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _categoryFilter = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<PromptMood>(
                    key: ValueKey('mood-$_moodFilter'),
                    initialValue: _moodFilter,
                    decoration: const InputDecoration(labelText: 'Tone'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...PromptMood.values.map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.label),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _moodFilter = v),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => showOptionalPromptSheet(context),
                child: const Text('One question at a time'),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: visible.length + (lockedCount > 0 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= visible.length) {
                  return ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: Text(
                      'Full prompt library ($lockedCount more)',
                    ),
                    subtitle: const Text(
                      'Premium opens every prompt. Categories can stay hidden.',
                    ),
                    onTap: () => showPremiumUpgradeSheet(
                      context,
                      title: 'Full prompt library',
                      body: '',
                      trigger: PaywallTrigger.browsePlans,
                    ),
                  );
                }
                final prompt = visible[index];
                return ListTile(
                  title: Text(prompt.text),
                  subtitle: Text(prompt.category),
                  onTap: () {
                    PrivacySafeAnalytics.instance.log('prompt_opened');
                    final body = Uri.encodeComponent('${prompt.text}\n\n');
                    final type = prompt.category.contains('letter')
                        ? 'letter'
                        : 'note';
                    context.push(
                      '/entry/new?type=$type&body=$body&promptId=${prompt.id}',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
