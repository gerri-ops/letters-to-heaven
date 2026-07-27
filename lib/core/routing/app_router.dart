import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../features/auth/account_screen.dart';
import '../../features/capture/quick_capture_screen.dart';
import '../../features/entries/entry_detail_screen.dart';
import '../../features/entries/entry_editor_screen.dart';
import '../../features/gifts/gift_premium_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/keepsake/export_screen.dart';
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
final _shellNavigatorLibraryKey = GlobalKey<NavigatorState>(debugLabel: 'library');
final _shellNavigatorKeepsakeKey = GlobalKey<NavigatorState>(debugLabel: 'keepsake');
final _shellNavigatorSubscribeKey =
    GlobalKey<NavigatorState>(debugLabel: 'subscribe');

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
      if (loc.startsWith('/entry') ||
          loc == '/prompts' ||
          loc == '/capture' ||
          loc == '/first-save-success' ||
          loc == '/protect-memories' ||
          loc == '/paywall' ||
          loc == '/subscription' ||
          loc == '/keepsake-preview' ||
          loc == '/export' ||
          loc == '/memorials' ||
          loc == '/memorial/new' ||
          loc == '/gift' ||
          loc == '/retention' ||
          loc == '/privacy-trust') {
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
      if (!appState.onboardingComplete && !onboardingRoutes.contains(loc)) {
        if (appState.onboardingIntent == null) {
          return loc == '/welcome' || loc == '/first-action' ? null : '/welcome';
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
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const MemorialSetupScreen(isAdditional: true),
      ),
      GoRoute(
        path: '/memorials',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MemorialsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/privacy-trust',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacyTrustScreen(),
      ),
      GoRoute(
        path: '/pace-promise',
        builder: (context, state) => const PacePromiseScreen(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/first-save-success',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final entryId = state.uri.queryParameters['entryId'] ?? '';
          return FirstSaveSuccessScreen(entryId: entryId);
        },
      ),
      GoRoute(
        path: '/protect-memories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProtectMemoriesScreen(),
      ),
      GoRoute(
        path: '/voice-keepsakes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VoiceKeepsakesScreen(),
      ),
      GoRoute(
        path: '/voice-keepsakes/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VoiceKeepsakeEditorScreen(),
      ),
      GoRoute(
        path: '/voice-keepsakes/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => VoiceKeepsakeEditorScreen(
          entryId: state.pathParameters['id'],
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
                builder: (context, state) => const TrustPaywallScreen(
                  trigger: PaywallTrigger.browsePlans,
                  embeddedInShell: true,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/capture',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final modeName = state.uri.queryParameters['mode'];
          var mode = QuickCaptureMode.type;
          for (final value in QuickCaptureMode.values) {
            if (value.name == modeName) {
              mode = value;
              break;
            }
          }
          return QuickCaptureScreen(initialMode: mode);
        },
      ),
      GoRoute(
        path: '/entry/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final type = entryTypeFromName(state.uri.queryParameters['type']) ??
              EntryType.memory;
          final body = state.uri.queryParameters['body'];
          final promptId = state.uri.queryParameters['promptId'];
          return EntryEditorScreen(
            entryId: null,
            initialType: type,
            initialBody: body,
            promptId: promptId,
          );
        },
      ),
      GoRoute(
        path: '/entry/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            EntryDetailScreen(entryId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/entry/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => EntryEditorScreen(
          entryId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/prompts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PromptsScreen(),
      ),
      GoRoute(
        path: '/keepsake-preview',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const KeepsakePreviewScreen(),
      ),
      GoRoute(
        path: '/export',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExportScreen(),
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/timeline',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TimelineScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/gift',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final redeem = state.uri.queryParameters['mode'] == 'redeem';
          return GiftPremiumScreen(
            initialMode:
                redeem ? GiftScreenMode.redeem : GiftScreenMode.give,
          );
        },
      ),
      GoRoute(
        path: '/paywall',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final trigger = PaywallTriggerX.fromQuery(
            state.uri.queryParameters['trigger'],
          );
          final next = state.uri.queryParameters['next'];
          return TrustPaywallScreen(
            trigger: trigger,
            nextPath: next,
          );
        },
      ),
      GoRoute(
        path: '/subscription',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final trigger = PaywallTriggerX.fromQuery(
            state.uri.queryParameters['trigger'],
          );
          final next = state.uri.queryParameters['next'];
          return TrustPaywallScreen(
            trigger: trigger,
            nextPath: next,
          );
        },
      ),
      GoRoute(
        path: '/retention',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RetentionSettingsScreen(),
      ),
      GoRoute(
        path: '/reminders',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: '/data-rights',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DataRightsScreen(),
      ),
    ],
  );
}
