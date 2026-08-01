import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../firebase_options.dart';
import '../firebase/auth_service.dart';
import '../firebase/firestore_client.dart';
import 'stripe_pricing_table_config.dart';

enum StripePlan { monthly, annual }

class StripeBillingException implements Exception {
  StripeBillingException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Stripe Pricing Table + Checkout + Customer Portal.
///
/// Web subscribe UX uses the hosted Pricing Table page. Callable Cloud Functions
/// still power Customer Portal and optional plan-specific Checkout.
class StripeBillingService {
  StripeBillingService._();
  static final instance = StripeBillingService._();

  final http.Client _client = http.Client();

  static const _region = 'us-central1';

  Uri _callableUri(String name) => Uri.parse(
        'https://$_region-${FirebaseConfig.projectId}.cloudfunctions.net/$name',
      );

  Future<Map<String, dynamic>> _call(
    String name, {
    Map<String, dynamic>? data,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      throw StripeBillingException('Sign in to subscribe or manage billing.');
    }
    final token = await AuthService.instance.getValidIdToken();
    final response = await _client.post(
      _callableUri(name),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'data': data ?? const <String, dynamic>{}}),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final message = _errorMessage(body) ??
          'Billing request failed (${response.statusCode}).';
      throw StripeBillingException(message);
    }
    if (body is Map && body['error'] != null) {
      throw StripeBillingException(_errorMessage(body) ?? 'Billing request failed.');
    }
    if (body is Map && body['result'] is Map) {
      return Map<String, dynamic>.from(body['result'] as Map);
    }
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    throw StripeBillingException('Unexpected billing response.');
  }

  String? _errorMessage(Object? body) {
    if (body is! Map) {
      return null;
    }
    final error = body['error'];
    if (error is Map) {
      final message = error['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return null;
  }

  /// Opens the Stripe Pricing Table with Firebase uid as client_reference_id.
  Future<void> openPricingTable({
    required String uid,
    String? email,
    String returnPath = '/shell/subscribe',
  }) async {
    if (uid.isEmpty) {
      throw StripeBillingException('Sign in to subscribe or manage billing.');
    }
    final uri = Uri(
      path: StripePricingTableConfig.pricingPagePath,
      queryParameters: {
        'uid': uid,
        if (email != null && email.isNotEmpty) 'email': email,
        'return': returnPath,
      },
    );
    // On web, same-origin relative path; on other platforms, absolute hosting URL.
    final url = kIsWeb
        ? uri.toString()
        : Uri.https(
            'letters-to-heaven-64491.web.app',
            uri.path,
            uri.queryParameters,
          ).toString();
    await _openUrl(url);
  }

  /// Optional direct Checkout Session (callable). Prefer [openPricingTable] on web.
  Future<void> startCheckout(StripePlan plan) async {
    final result = await _call(
      'createCheckoutSession',
      data: {'plan': plan.name},
    );
    final url = result['url'] as String?;
    if (url == null || url.isEmpty) {
      throw StripeBillingException('Checkout URL missing. Try again later.');
    }
    await _openUrl(url);
  }

  Future<void> openCustomerPortal() async {
    final result = await _call('createCustomerPortalSession');
    final url = result['url'] as String?;
    if (url == null || url.isEmpty) {
      throw StripeBillingException('Billing portal URL missing. Try again later.');
    }
    await _openUrl(url);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(
      uri,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: '_self',
    );
    if (!ok) {
      throw StripeBillingException('Could not open Stripe Checkout.');
    }
  }

  /// Reads Stripe entitlement from Firestore. Returns null if none exists.
  Future<StripeEntitlement?> fetchEntitlement({required String uid}) async {
    try {
      final doc = await FirestoreClient.instance.getDocument(
        collectionPath: 'users/$uid/entitlements',
        documentId: 'premium',
      );
      if (doc == null) {
        return null;
      }
      return StripeEntitlement.fromJson(doc);
    } catch (e) {
      debugPrint('Stripe entitlement fetch failed: $e');
      return null;
    }
  }
}

class StripeEntitlement {
  const StripeEntitlement({
    required this.entitled,
    required this.status,
    this.plan,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
  });

  final bool entitled;
  final String status;
  final String? plan;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;

  bool get isStripeSubscriber =>
      entitled || status == 'active' || status == 'trialing';

  factory StripeEntitlement.fromJson(Map<String, dynamic> json) {
    final status = '${json['status'] ?? ''}';
    final entitledFlag = json['entitled'] == true;
    DateTime? periodEnd;
    final rawEnd = json['currentPeriodEnd'];
    if (rawEnd is String && rawEnd.isNotEmpty) {
      periodEnd = DateTime.tryParse(rawEnd);
    }
    return StripeEntitlement(
      entitled: entitledFlag || status == 'active' || status == 'trialing',
      status: status,
      plan: json['plan'] as String?,
      stripeCustomerId: json['stripeCustomerId'] as String?,
      stripeSubscriptionId: json['stripeSubscriptionId'] as String?,
      currentPeriodEnd: periodEnd,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] == true,
    );
  }
}
