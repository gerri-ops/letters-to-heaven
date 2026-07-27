import '../firebase/auth_session.dart';

/// Marks Firebase REST clients as ready (always, once session store is loaded).
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _ready = false;
  static bool get isReady => _ready;

  /// REST clients work on every platform, including Windows desktop.
  static bool get isSupportedPlatform => true;

  static Future<void> init() async {
    await AuthSession.instance.load();
    _ready = true;
  }
}
