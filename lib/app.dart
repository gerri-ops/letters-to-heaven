import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/app_router.dart';
import 'core/state/app_scope.dart';
import 'core/theme/app_theme.dart';

class LettersToHeavenApp extends StatefulWidget {
  const LettersToHeavenApp({required this.appState, super.key});

  final AppState appState;

  @override
  State<LettersToHeavenApp> createState() => _LettersToHeavenAppState();
}

class _LettersToHeavenAppState extends State<LettersToHeavenApp> {
  late final GoRouter _router = createAppRouter(widget.appState);

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: widget.appState,
      child: MaterialApp.router(
        title: 'Letters to Heaven',
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
