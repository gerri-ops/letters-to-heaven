import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/auth_service.dart';
import '../firebase/firebase_bootstrap.dart';

/// Controls whether user media may be uploaded to Firebase Storage.
///
/// Default is **off**: photos stay on the device. Turn this on in Settings
/// after Storage is enabled in Firebase and you are signed in.
class MediaPolicy {
  MediaPolicy._();
  static final MediaPolicy instance = MediaPolicy._();

  static const _prefsKey = 'cloud_storage_enabled';

  bool _cloudStorageEnabled = false;
  bool get cloudStorageEnabled => _cloudStorageEnabled;

  bool get canUploadNow =>
      _cloudStorageEnabled &&
      FirebaseBootstrap.isReady &&
      AuthService.instance.currentUser != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cloudStorageEnabled = prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> setCloudStorageEnabled(bool value) async {
    _cloudStorageEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  /// User-facing copy for pickers and settings.
  String get localOnlyNotice {
    if (!_cloudStorageEnabled) {
      return 'Photos stay on this device only. Cloud photo backup is off.';
    }
    if (!FirebaseBootstrap.isReady) {
      return 'Cloud backup is on, but Firebase did not finish starting.';
    }
    if (AuthService.instance.currentUser == null) {
      return 'Cloud backup is on. Sign in with email so photos can upload.';
    }
    return 'Photos can sync to your private cloud backup when you are online.';
  }
}
