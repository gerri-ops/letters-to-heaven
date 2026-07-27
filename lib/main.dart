import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/media/media_policy.dart';
import 'core/platform/desktop_sqlite.dart';
import 'core/security/biometric_lock.dart';
import 'core/state/app_scope.dart';
import 'core/sync/sync_service.dart';
import 'data/local/app_database.dart';
import 'data/repositories/app_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    initDesktopSqlite();
  }

  await FirebaseBootstrap.init();
  await MediaPolicy.instance.load();

  final database = AppDatabase();
  await database.database;
  final repository = AppRepository(database: database);
  final syncService = SyncService(repository);
  final biometricLock = BiometricLockService();

  final appState = AppState(
    repository: repository,
    syncService: syncService,
    biometricLock: biometricLock,
  );
  await appState.load();

  if (!kIsWeb && await biometricLock.isEnabled()) {
    await biometricLock.authenticate();
  }

  // Best-effort cloud sync for signed-in accounts (and photo backup if enabled).
  // ignore: unawaited_futures
  syncService.syncNow(
    displayName: appState.displayName,
    email: appState.email,
  );

  runApp(LettersToHeavenApp(appState: appState));
}
