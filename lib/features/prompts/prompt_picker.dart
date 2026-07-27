import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../core/billing/plan_entitlements.dart';
import '../../core/state/app_scope.dart';
import '../../data/models/models.dart';
import 'prompt_mood.dart';

/// Loads and picks a single optional prompt with consent and cooldown rules.
class PromptPicker {
  PromptPicker._();

  static List<Prompt>? _cache;

  static Future<List<Prompt>> loadAll() async {
    if (_cache != null) {
      return _cache!;
    }
    final raw =
        await rootBundle.loadString('assets/prompts/launch_prompts.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = (json['prompts'] as List<dynamic>)
        .map((e) => Prompt.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  static Future<Prompt?> pickOne({
    required AppState app,
    Prompt? exclude,
    List<String> alsoExcludeIds = const [],
  }) async {
    final all = await loadAll();
    final forPlan = PlanEntitlements.promptsForPlan(
      all: all,
      premium: app.premium,
    );
    final mood = app.promptMood;
    final allowDifficult = app.allowDifficultPrompts;
    final candidates = forPlan.where((p) {
      if (app.hiddenPromptCategories.contains(p.category)) {
        return false;
      }
      if (!promptMatchesMood(p, mood)) {
        return false;
      }
      if (!allowDifficult && promptNeedsDifficultConsent(p)) {
        return false;
      }
      if (exclude != null && p.id == exclude.id) {
        return false;
      }
      if (alsoExcludeIds.contains(p.id)) {
        return false;
      }
      if (app.isPromptOnDismissCooldown(p.id)) {
        return false;
      }
      return true;
    }).toList();

    if (candidates.isEmpty) {
      // Soft fallback within mood without difficult content.
      final fallback = forPlan.where((p) {
        if (app.hiddenPromptCategories.contains(p.category)) return false;
        if (!allowDifficult && promptNeedsDifficultConsent(p)) return false;
        if (app.isPromptOnDismissCooldown(p.id)) return false;
        if (exclude != null && p.id == exclude.id) return false;
        return promptMatchesMood(p, PromptMood.gentle);
      }).toList();
      if (fallback.isEmpty) return null;
      return fallback[Random().nextInt(fallback.length)];
    }
    return candidates[Random().nextInt(candidates.length)];
  }
}
