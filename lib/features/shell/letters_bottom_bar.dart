import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';

/// Shared bottom chrome: quick capture + primary destinations.
class LettersBottomBar extends StatelessWidget {
  const LettersBottomBar({super.key});

  static const _tabPaths = [
    '/shell/home',
    '/shell/library',
    '/shell/keepsake',
    '/shell/subscribe',
  ];

  static int indexForLocation(String loc) {
    if (loc.startsWith('/shell/library') ||
        loc == '/prompts' ||
        loc.startsWith('/entry')) {
      return 1;
    }
    if (loc.startsWith('/shell/keepsake') ||
        loc == '/export' ||
        loc == '/keepsake-preview' ||
        loc == '/timeline' ||
        loc == '/search' ||
        loc.startsWith('/voice-keepsakes')) {
      return 2;
    }
    if (loc.startsWith('/shell/subscribe') ||
        loc == '/paywall' ||
        loc == '/subscription') {
      return 3;
    }
    return 0;
  }

  static bool _showCaptureStrip(String loc) {
    if (loc.startsWith('/shell/subscribe') ||
        loc == '/paywall' ||
        loc == '/subscription' ||
        loc == '/settings' ||
        loc == '/account' ||
        loc == '/data-rights' ||
        loc == '/retention' ||
        loc == '/reminders' ||
        loc == '/privacy-trust' ||
        loc == '/first-save-success' ||
        loc == '/protect-memories') {
      return false;
    }
    // Editors and capture already have their own primary action.
    if (loc.startsWith('/entry') || loc == '/capture') {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    final selected = indexForLocation(loc);
    final showCapture = _showCaptureStrip(loc);
    final premium = AppScope.of(context).premium;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCapture)
          Material(
            color: AppColors.cream,
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/capture'),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Remember Something?'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (index) {
            final path = _tabPaths[index];
            if (loc == path) {
              return;
            }
            context.go(path);
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Library',
            ),
            const NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Keepsake',
            ),
            NavigationDestination(
              icon: Icon(
                premium
                    ? Icons.workspace_premium
                    : Icons.workspace_premium_outlined,
              ),
              selectedIcon: const Icon(Icons.workspace_premium),
              label: premium ? 'Premium' : 'Subscribe',
            ),
          ],
        ),
      ],
    );
  }
}
