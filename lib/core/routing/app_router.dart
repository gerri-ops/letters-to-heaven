import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../features/auth/account_screen.dart';
import '../../features/capture/quick_capture_screen.dart';
import '../../features/entries/entry_detail_screen.dart';
import '../../features/entries/entry_editor_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/keepsake/export_screen.dart';
import '../../features/keepsake/keepsake_catalog.dart';
import '../../features/keepsake/keepsake_preview_screen.dart';
import '../../features/keepsake/keepsake_screen.dart';
import '../../features/keepsake/search_screen.dart';
import '../../features/keepsake/timeline_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/memorials/memorials_screen.dart';
import '../../features/onboarding/first_action_screen.dart';
import '../../features/onboarding/first_save_success_screen.dart';
import '../../features/onboarding/memorial_setup_screen.dart';
import '../../features/onboarding/pace_promise_screen.dart';
import '../../features/onboarding/privacy_screen.dart';
import '../../features/privacy/privacy_trust_screen.dart';
import '../../features/onboarding/protect_memories_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/prompts/prompts_screen.dart';
import '../../features/settings/data_rights_screen.dart';
import '../../features/settings/reminders_screen.dart';
import '../../features/settings/retention_settings_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/trust_paywall_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/voice/voice_keepsake_editor_screen.dart';
import '../../features/voice/voice_keepsakes_screen.dart';
import '../billing/trust_paywall_copy.dart';
import '../state/app_scope.dart';
import '../utils/entry_helpers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorLibraryKey =
    GlobalKey<NavigatorState>(debugLabel: 'library');
final _shellNavigatorKeepsakeKey =
    GlobalKey<NavigatorState>(debugLabel: 'keepsake');
final _shellNavigatorSubscribeKey =
    GlobalKey<NavigatorState>(debugLabel: 'subscribe');

Widget _chrome(Widget child) => AppChromeShell(child: child);

GoRouter createAppRouter(AppState appState) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/welcome',
    refreshListenable: appState,
    redirect: (context, state) {
      if (!appState.initialized) {
        return null;
      }
      final loc = state.matchedLocation;

      // First capture paths stay open during onboarding so the chosen action
      // can happen right after naming a memorial.
      final firstActionPaths = loc.startsWith('/entry') ||
          loc == '/capture' ||
          loc.startsWith('/voice-keepsakes');

      if (loc == '/prompts' ||
          loc == '/first-save-success' ||
          loc == '/protect-memories' ||
          loc == '/paywall' ||
          loc == '/subscription' ||
          loc == '/keepsake-preview' ||
          loc == '/export' ||
          loc == '/memorials' ||
          loc == '/memorial/new' ||
          loc == '/retention' ||
          loc == '/privacy-trust' ||
          firstActionPaths) {
        return null;
      }

      final onboardingRoutes = {
        '/welcome',
        '/privacy',
        '/pace-promise',
        '/account',
        '/memorial-setup',
        '/first-action',
        '/protect-memories',
        '/first-save-success',
        '/paywall',
      };

      if (!appState.onboardingComplete) {
        // Shell tabs stay closed until privacy + pace are done.
        if (loc.startsWith('/shell/')) {
          if (appState.onboardingIntent == null) {
            return '/welcome';
          }
          if (appState.currentMemorial == null) {
            return '/memorial-setup';
          }
          if (!appState.privacyAccepted) {
            return '/privacy';
          }
          if (!appState.paceAccepted) {
            return '/pace-promise';
          }
          return null;
        }
        if (!onboardingRoutes.contains(loc)) {
          if (appState.onboardingIntent == null) {
            return loc == '/welcome' || loc == '/first-action'
                ? null
                : '/welcome';
          }
          if (appState.currentMemorial == null) {
            return '/memorial-setup';
          }
          if (!appState.privacyAccepted) {
            return '/privacy';
          }
          if (!appState.paceAccepted) {
            return '/pace-promise';
          }
          return '/shell/home';
        }
      }
      if (appState.onboardingComplete &&
          (loc == '/welcome' ||
              loc == '/privacy' ||
              loc == '/pace-promise' ||
              loc == '/memorial-setup' ||
              loc == '/first-action')) {
        return '/shell/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/first-action',
        builder: (context, state) => const FirstActionScreen(),
      ),
      GoRoute(
        path: '/memorial-setup',
        builder: (context, state) => const MemorialSetupScreen(),
      ),
      GoRoute(
        path: '/memorial/new',
        builder: (context, state) =>
            _chrome(const MemorialSetupScreen(isAdditional: true)),
      ),
      GoRoute(
        path: '/memorials',
        builder: (context, state) => _chrome(const MemorialsScreen()),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/privacy-trust',
        builder: (context, state) => _chrome(const PrivacyTrustScreen()),
      ),
      GoRoute(
        path: '/pace-promise',
        builder: (context, state) => const PacePromiseScreen(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => _chrome(const AccountScreen()),
      ),
      GoRoute(
        path: '/first-save-success',
        builder: (context, state) {
          final entryId = state.uri.queryParameters['entryId'] ?? '';
          return _chrome(FirstSaveSuccessScreen(entryId: entryId));
        },
      ),
      GoRoute(
        path: '/protect-memories',
        builder: (context, state) =>
            _chrome(const ProtectMemoriesScreen()),
      ),
      GoRoute(
        path: '/voice-keepsakes',
        builder: (context, state) =>
            _chrome(const VoiceKeepsakesScreen()),
      ),
      GoRoute(
        path: '/voice-keepsakes/new',
        builder: (context, state) =>
            _chrome(const VoiceKeepsakeEditorScreen()),
      ),
      GoRoute(
        path: '/voice-keepsakes/:id/edit',
        builder: (context, state) => _chrome(
          VoiceKeepsakeEditorScreen(entryId: state.pathParameters['id']),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/shell/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorLibraryKey,
            routes: [
              GoRoute(
                path: '/shell/library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeepsakeKey,
            routes: [
              GoRoute(
                path: '/shell/keepsake',
                builder: (context, state) => const KeepsakeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSubscribeKey,
            routes: [
              GoRoute(
                path: '/shell/subscribe',
                builder: (context, state) => TrustPaywallScreen(
                  trigger: PaywallTrigger.browsePlans,
                  embeddedInShell: true,
                  checkoutResult: state.uri.queryParameters['checkout'],
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/capture',
        builder: (context, state) {
          final modeName = state.uri.queryParameters['mode'];
          var mode = QuickCaptureMode.type;
          for (final value in QuickCaptureMode.values) {
            if (value.name == modeName) {
              mode = value;
              break;
            }
          }
          return _chrome(QuickCaptureScreen(initialMode: mode));
        },
      ),
      GoRoute(
        path: '/entry/new',
        builder: (context, state) {
          final type = entryTypeFromName(state.uri.queryParameters['type']) ??
              EntryType.memory;
          final body = state.uri.queryParameters['body'];
          final promptId = state.uri.queryParameters['promptId'];
          final template = state.uri.queryParameters['template'];
          return _chrome(
            EntryEditorScreen(
              entryId: null,
              initialType: type,
              initialBody: body,
              promptId: promptId,
              initialTemplateId: template,
            ),
          );
        },
      ),
      GoRoute(
        path: '/entry/:id',
        builder: (context, state) => _chrome(
          EntryDetailScreen(entryId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/entry/:id/edit',
        builder: (context, state) => _chrome(
          EntryEditorScreen(entryId: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: '/prompts',
        builder: (context, state) => _chrome(const PromptsScreen()),
      ),
      GoRoute(
        path: '/keepsake-preview',
        builder: (context, state) => _chrome(
          KeepsakePreviewScreen(
            initialTheme: ExportThemeX.fromLegacyName(
              state.uri.queryParameters['theme'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/export',
        builder: (context, state) => _chrome(
          ExportScreen(
            initialTheme: ExportThemeX.fromLegacyName(
              state.uri.queryParameters['theme'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => _chrome(const SearchScreen()),
      ),
      GoRoute(
        path: '/timeline',
        builder: (context, state) => _chrome(const TimelineScreen()),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => _chrome(const SettingsScreen()),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) {
          final trigger = PaywallTriggerX.fromQuery(
            state.uri.queryParameters['trigger'],
          );
          final next = state.uri.queryParameters['next'];
          return _chrome(
            TrustPaywallScreen(
              trigger: trigger,
              nextPath: next,
              checkoutResult: state.uri.queryParameters['checkout'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) {
          final trigger = PaywallTriggerX.fromQuery(
            state.uri.queryParameters['trigger'],
          );
          final next = state.uri.queryParameters['next'];
          return _chrome(
            TrustPaywallScreen(
              trigger: trigger,
              nextPath: next,
              checkoutResult: state.uri.queryParameters['checkout'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/retention',
        builder: (context, state) =>
            _chrome(const RetentionSettingsScreen()),
      ),
      GoRoute(
        path: '/reminders',
        builder: (context, state) => _chrome(const RemindersScreen()),
      ),
      GoRoute(
        path: '/data-rights',
        builder: (context, state) => _chrome(const DataRightsScreen()),
      ),
    ],
  );
}
