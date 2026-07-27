import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../firebase_options.dart';
import 'auth_session.dart';

class AuthException implements Exception {
  AuthException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class AuthUser {
  const AuthUser({required this.uid, required this.email});

  final String uid;
  final String email;
}

class AuthCredentialResult {
  const AuthCredentialResult({required this.user});

  final AuthUser user;
}

/// Firebase Auth via Identity Toolkit REST (works on Windows/Android/iOS/web).
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final http.Client _client = http.Client();

  bool get isAvailable => true;

  AuthUser? get currentUser {
    final session = AuthSession.instance;
    if (!session.isSignedIn || session.uid == null) {
      return null;
    }
    return AuthUser(uid: session.uid!, email: session.email ?? '');
  }

  String? get firebaseUid => currentUser?.uid;

  Future<AuthCredentialResult> createAccount({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse(
      '${FirebaseConfig.identityToolkitBase}/accounts:signUp?key=${FirebaseConfig.apiKey}',
    );
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );
    return _parseAuthResponse(response, fallbackEmail: email);
  }

  Future<AuthCredentialResult> signIn({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse(
      '${FirebaseConfig.identityToolkitBase}/accounts:signInWithPassword?key=${FirebaseConfig.apiKey}',
    );
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );
    return _parseAuthResponse(response, fallbackEmail: email);
  }

  Future<void> signOut() => AuthSession.instance.clear();

  /// Returns a fresh ID token, refreshing when expired.
  Future<String> getValidIdToken() async {
    final session = AuthSession.instance;
    if (!session.isSignedIn) {
      throw AuthException('unauthenticated', 'Sign in before uploading photos.');
    }
    final expires = session.idTokenExpiresAt;
    final token = session.idToken;
    if (token != null &&
        expires != null &&
        DateTime.now().isBefore(expires)) {
      return token;
    }
    return _refreshIdToken();
  }

  Future<String> _refreshIdToken() async {
    final session = AuthSession.instance;
    final refresh = session.refreshToken;
    if (refresh == null) {
      throw AuthException('unauthenticated', 'Sign in before uploading photos.');
    }
    final uri = Uri.parse(
      '${FirebaseConfig.secureTokenBase}/token?key=${FirebaseConfig.apiKey}',
    );
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refresh,
      },
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      final err = json['error'] as Map<String, dynamic>?;
      throw AuthException(
        err?['message']?.toString() ?? 'refresh-failed',
        'Session expired. Please sign in again.',
      );
    }
    final idToken = json['id_token'] as String? ?? json['idToken'] as String?;
    final refreshToken =
        json['refresh_token'] as String? ?? json['refreshToken'] as String?;
    final expiresIn = int.tryParse(
          '${json['expires_in'] ?? json['expiresIn'] ?? 3600}',
        ) ??
        3600;
    final uid = json['user_id'] as String? ??
        json['userId'] as String? ??
        session.uid!;
    if (idToken == null || refreshToken == null) {
      throw AuthException('refresh-failed', 'Could not refresh session.');
    }
    await session.save(
      newUid: uid,
      newEmail: session.email ?? '',
      newIdToken: idToken,
      newRefreshToken: refreshToken,
      expiresInSeconds: expiresIn,
    );
    return idToken;
  }

  Future<AuthCredentialResult> _parseAuthResponse(
    http.Response response, {
    required String fallbackEmail,
  }) async {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw _mapError(json);
    }
    final uid = json['localId'] as String?;
    final idToken = json['idToken'] as String?;
    final refreshToken = json['refreshToken'] as String?;
    final expiresIn = int.tryParse('${json['expiresIn'] ?? 3600}') ?? 3600;
    final email = json['email'] as String? ?? fallbackEmail;
    if (uid == null || idToken == null || refreshToken == null) {
      throw AuthException('unknown', 'Unexpected auth response.');
    }
    await AuthSession.instance.save(
      newUid: uid,
      newEmail: email,
      newIdToken: idToken,
      newRefreshToken: refreshToken,
      expiresInSeconds: expiresIn,
    );
    return AuthCredentialResult(user: AuthUser(uid: uid, email: email));
  }

  AuthException _mapError(Map<String, dynamic> json) {
    final err = json['error'] as Map<String, dynamic>?;
    final message = err?['message']?.toString() ?? 'AUTH_ERROR';
    switch (message) {
      case 'EMAIL_EXISTS':
        return AuthException(
          'email-already-in-use',
          'That email already has an account. Try signing in.',
        );
      case 'INVALID_EMAIL':
        return AuthException(
          'invalid-email',
          'Please enter a valid email address.',
        );
      case 'WEAK_PASSWORD : Password should be at least 6 characters':
      case 'WEAK_PASSWORD':
        return AuthException(
          'weak-password',
          'Please choose a stronger password.',
        );
      case 'EMAIL_NOT_FOUND':
      case 'INVALID_PASSWORD':
      case 'INVALID_LOGIN_CREDENTIALS':
        return AuthException(
          'invalid-credential',
          'Email or password is incorrect.',
        );
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        return AuthException(
          'too-many-requests',
          'Too many attempts. Try again later.',
        );
      default:
        return AuthException(message, message);
    }
  }
}
