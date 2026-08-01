import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'letters_bottom_bar.dart';

/// Wraps a full-screen page so the shared bottom menu stays visible.
class AppChromeShell extends StatelessWidget {
  const AppChromeShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const LettersBottomBar(),
    );
  }
}

/// Primary tab shell — Home / Library / Keepsake / Subscribe.
class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: const LettersBottomBar(),
    );
  }
}
