import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persisted Firebase Auth REST session (id + refresh tokens).
class AuthSession {
  AuthSession._();
  static final instance = AuthSession._();

  static const _keyIdToken = 'firebase_id_token';
  static const _keyRefreshToken = 'firebase_refresh_token';
  static const _keyUid = 'firebase_auth_uid';
  static const _keyEmail = 'firebase_auth_email';
  static const _keyExpiry = 'firebase_id_token_expiry_ms';

  String? idToken;
  String? refreshToken;
  String? uid;
  String? email;
  DateTime? idTokenExpiresAt;

  bool get isSignedIn =>
      uid != null &&
      uid!.isNotEmpty &&
      refreshToken != null &&
      refreshToken!.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    idToken = prefs.getString(_keyIdToken);
    refreshToken = prefs.getString(_keyRefreshToken);
    uid = prefs.getString(_keyUid);
    email = prefs.getString(_keyEmail);
    final expiryMs = prefs.getInt(_keyExpiry);
    idTokenExpiresAt =
        expiryMs == null ? null : DateTime.fromMillisecondsSinceEpoch(expiryMs);
  }

  Future<void> save({
    required String newUid,
    required String newEmail,
    required String newIdToken,
    required String newRefreshToken,
    required int expiresInSeconds,
  }) async {
    uid = newUid;
    email = newEmail;
    idToken = newIdToken;
    refreshToken = newRefreshToken;
    idTokenExpiresAt =
        DateTime.now().add(Duration(seconds: expiresInSeconds - 60));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid, newUid);
    await prefs.setString(_keyEmail, newEmail);
    await prefs.setString(_keyIdToken, newIdToken);
    await prefs.setString(_keyRefreshToken, newRefreshToken);
    await prefs.setInt(
      _keyExpiry,
      idTokenExpiresAt!.millisecondsSinceEpoch,
    );
  }

  Future<void> clear() async {
    uid = null;
    email = null;
    idToken = null;
    refreshToken = null;
    idTokenExpiresAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUid);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyIdToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyExpiry);
  }

  Map<String, dynamic> toDebugJson() => {
        'uid': uid,
        'email': email,
        'hasToken': idToken != null,
      };

  @override
  String toString() => jsonEncode(toDebugJson());
}
