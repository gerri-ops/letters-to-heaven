import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'trust_paywall_copy.dart';

/// Opens the trust paywall after a value moment (never used as first launch).
Future<void> showTrustPaywall(
  BuildContext context, {
  required PaywallTrigger trigger,
  String? nextPath,
}) {
  final params = <String, String>{
    'trigger': trigger.queryValue,
    if (nextPath != null && nextPath.isNotEmpty) 'next': nextPath,
  };
  final query = params.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');
  return context.push<void>('/paywall?$query');
}

/// @Deprecated — use [showTrustPaywall].
Future<void> showPremiumUpgradeSheet(
  BuildContext context, {
  required String title,
  required String body,
  PaywallTrigger trigger = PaywallTrigger.browsePlans,
}) {
  return showTrustPaywall(context, trigger: trigger);
}
