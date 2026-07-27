/// Project config for Letters to Heaven / letters-to-heaven-64491.
///
/// Used by the REST Auth + Storage clients (no native Firebase SDK required).
abstract final class FirebaseConfig {
  static const projectId = 'letters-to-heaven-64491';
  static const storageBucket = 'letters-to-heaven-64491.firebasestorage.app';
  static const authDomain = 'letters-to-heaven-64491.firebaseapp.com';

  /// Web API key for Identity Toolkit + Storage REST.
  static const apiKey = 'AIzaSyC8uMIfWMGecr_5e_Er-97vLIulmzhZRsQ';

  static const identityToolkitBase =
      'https://identitytoolkit.googleapis.com/v1';
  static const secureTokenBase = 'https://securetoken.googleapis.com/v1';
}
