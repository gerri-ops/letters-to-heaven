import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../firebase_options.dart';
import 'auth_service.dart';

/// Firestore REST client for owner-scoped user data.
class FirestoreClient {
  FirestoreClient._();
  static final instance = FirestoreClient._();

  final http.Client _client = http.Client();

  String get _base =>
      'https://firestore.googleapis.com/v1/projects/${FirebaseConfig.projectId}/databases/(default)/documents';

  Future<void> upsertUserProfile({
    required String uid,
    required String displayName,
    String? email,
  }) async {
    await upsertDocument(
      collectionPath: 'users',
      documentId: uid,
      data: {
        'uid': uid,
        'displayName': displayName,
        if (email != null) 'email': email,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> upsertDocument({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    final token = await AuthService.instance.getValidIdToken();
    final uri = Uri.parse('$_base/$collectionPath/$documentId');
    final response = await _client.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fields': encodeFields(data)}),
    );
    if (response.statusCode >= 400) {
      throw StateError(
        'Firestore upsert failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> listDocuments({
    required String collectionPath,
  }) async {
    final token = await AuthService.instance.getValidIdToken();
    final uri = Uri.parse('$_base/$collectionPath');
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 404) {
      return const [];
    }
    if (response.statusCode >= 400) {
      throw StateError(
        'Firestore list failed (${response.statusCode}): ${response.body}',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = json['documents'] as List<dynamic>? ?? const [];
    return docs
        .whereType<Map>()
        .map((raw) => decodeDocument(Map<String, dynamic>.from(raw)))
        .toList();
  }

  Future<void> deleteDocument({
    required String collectionPath,
    required String documentId,
  }) async {
    final token = await AuthService.instance.getValidIdToken();
    final uri = Uri.parse('$_base/$collectionPath/$documentId');
    final response = await _client.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400 && response.statusCode != 404) {
      debugPrint(
        'Firestore delete failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  Map<String, dynamic> encodeFields(Map<String, dynamic> data) {
    return {
      for (final entry in data.entries)
        if (entry.value != null) entry.key: encodeValue(entry.value),
    };
  }

  Map<String, dynamic> encodeValue(Object? value) {
    if (value == null) {
      return {'nullValue': null};
    }
    if (value is String) {
      return {'stringValue': value};
    }
    if (value is bool) {
      return {'booleanValue': value};
    }
    if (value is int) {
      return {'integerValue': '$value'};
    }
    if (value is double) {
      return {'doubleValue': value};
    }
    if (value is List) {
      return {
        'arrayValue': {
          'values': [for (final item in value) encodeValue(item)],
        },
      };
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return {
        'mapValue': {
          'fields': {
            for (final e in map.entries)
              if (e.value != null) e.key.toString(): encodeValue(e.value),
          },
        },
      };
    }
    return {'stringValue': '$value'};
  }

  Map<String, dynamic> decodeDocument(Map<String, dynamic> document) {
    final fields = document['fields'] as Map<String, dynamic>? ?? const {};
    final decoded = <String, dynamic>{};
    for (final entry in fields.entries) {
      decoded[entry.key] = decodeValue(entry.value);
    }
    // Prefer explicit id field; fall back to last path segment.
    if (decoded['id'] == null) {
      final name = document['name'] as String? ?? '';
      final parts = name.split('/');
      if (parts.isNotEmpty) {
        decoded['id'] = parts.last;
      }
    }
    return decoded;
  }

  Object? decodeValue(Object? raw) {
    if (raw is! Map) {
      return raw;
    }
    final value = Map<String, dynamic>.from(raw);
    if (value.containsKey('stringValue')) {
      return value['stringValue'];
    }
    if (value.containsKey('booleanValue')) {
      return value['booleanValue'];
    }
    if (value.containsKey('integerValue')) {
      return int.tryParse('${value['integerValue']}') ?? 0;
    }
    if (value.containsKey('doubleValue')) {
      return (value['doubleValue'] as num).toDouble();
    }
    if (value.containsKey('nullValue')) {
      return null;
    }
    if (value.containsKey('timestampValue')) {
      return value['timestampValue'];
    }
    if (value.containsKey('arrayValue')) {
      final arr = value['arrayValue'] as Map<String, dynamic>? ?? const {};
      final values = arr['values'] as List<dynamic>? ?? const [];
      return [for (final item in values) decodeValue(item)];
    }
    if (value.containsKey('mapValue')) {
      final map = value['mapValue'] as Map<String, dynamic>? ?? const {};
      final fields = map['fields'] as Map<String, dynamic>? ?? const {};
      return {
        for (final e in fields.entries) e.key: decodeValue(e.value),
      };
    }
    return null;
  }
}
