import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/history_event.dart' as history;
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/screens/auth.dart';
import 'package:open_cloud_health/screens/home.dart';
import 'package:open_cloud_health/screens/checkups.dart';
import 'package:open_cloud_health/screens/history.dart';
import 'package:open_cloud_health/screens/history_event_detail.dart';
import 'package:open_cloud_health/screens/history_event_readonly_detail.dart';
import 'package:open_cloud_health/screens/medication_tracker.dart';
import 'package:open_cloud_health/screens/period_tracker.dart';
import 'package:open_cloud_health/screens/profile_detail.dart';
import 'package:open_cloud_health/screens/profiles.dart';
import 'package:open_cloud_health/screens/settings.dart';
import 'package:open_cloud_health/screens/vital_detail_screen.dart';
import 'package:open_cloud_health/screens/import_profile.dart';
import 'package:open_cloud_health/screens/archived_profiles.dart';
import 'package:open_cloud_health/screens/export_profile.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/screens/medication_editor.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/widgets/scaffold_with_nav_bar.dart';
import 'package:open_cloud_health/widgets/shell_route_redirector.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: AppRoutes.auth,
  navigatorKey: _rootNavigatorKey,
  routes: [
    GoRoute(
      path: AppRoutes.auth,
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: AppRoutes.profiles,
      builder: (context, state) => const ProfilesScreen(),
    ),
    // Shell route for the main app sections with bottom navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Home Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.homeBase,
              builder: (context, state) => const ShellRouteRedirector(targetRoute: AppRoutes.home),
            ),
            GoRoute(
              path: '${AppRoutes.home}/:profileId',
              builder: (context, state) {
                final profile = state.extra as Profile?;
                return HomeScreen(profileId: state.pathParameters['profileId']!, profile: profile);
              },
            ),
          ],
        ),
        // Medication Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.medicationBase,
              builder: (context, state) => const ShellRouteRedirector(targetRoute: AppRoutes.medicationTracker),
            ),
            GoRoute(
              path: '${AppRoutes.medicationTracker}/:profileId',
              builder: (context, state) {
                final profileId = state.pathParameters['profileId']!;
                return MedicationTrackerScreen(profileId: profileId);
              },
            ),
          ],
        ),
        // History Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.historyBase,
              builder: (context, state) => const ShellRouteRedirector(targetRoute: AppRoutes.history),
            ),
            GoRoute(
              path: '${AppRoutes.history}/:profileId',
              builder: (context, state) {
                final profileId = state.pathParameters['profileId']!;
                final profile = state.extra as Profile?;
                return HistoryScreen(profileId: profileId, profile: profile);
              },
            ),
          ],
        ),
        // Profile Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profileBase,
              builder: (context, state) => const ShellRouteRedirector(targetRoute: AppRoutes.profileDetail),
            ),
            GoRoute(
              path: '${AppRoutes.profileDetail}/:profileId',
              builder: (context, state) {
                final profileId = state.pathParameters['profileId']!;
                final profile = state.extra as Profile?;
                return ProfileDetailScreen(profileId: profileId, profile: profile);
              },
            ),
          ],
        ),
      ],
    ),
    // Routes that should NOT have the bottom nav (detail screens, etc.)
    GoRoute(
      path: AppRoutes.profileDetail, // This is for the "Add Profile" case
      builder: (context, state) {
        final profile = state.extra as Profile?;
        return ProfileDetailScreen(profile: profile);
      },
    ),
    GoRoute(
      path: '${AppRoutes.historyDetail}/:profileId',
      builder: (context, state) {
        final profileId = state.pathParameters['profileId']!;
        final historyEvent = state.extra as history.HistoryEvent?;
        return HistoryEventDetailScreen(
            profileId: profileId, historyEvent: historyEvent);
      },
    ),
    GoRoute(
      path: AppRoutes.historyReadonlyDetail,
      builder: (context, state) {
        final historyEvent = state.extra as history.HistoryEvent;
        return HistoryEventReadonlyDetail(event: historyEvent);
      },
    ),
    GoRoute(
      path: '${AppRoutes.checkups}/:profileId',
      builder: (context, state) {
        final profileId = state.pathParameters['profileId']!;
        return CheckupsScreen(profileId: profileId);
      },
    ),
    GoRoute(
      path: '${AppRoutes.periodTracker}/:profileId',
      builder: (context, state) {
        final profileId = state.pathParameters['profileId']!;
        return PeriodTrackerScreen(profileId: profileId);
      },
    ),
    GoRoute(
      path: '${AppRoutes.medicationEditor}/:profileId',
      builder: (context, state) {
        final profileId = state.pathParameters['profileId']!;
        final medication = state.extra as Medication?;
        return MedicationEditorScreen(
          profileId: profileId,
          medication: medication,
        );
      },
    ),
    GoRoute(
      path: '${AppRoutes.vitalTracker}/:profileId/:vitalType',
      builder: (context, state) {
        final profileId = state.pathParameters['profileId']!;
        final vitalTypeString = state.pathParameters['vitalType']!;
        final vitalType = VitalType.values.byName(vitalTypeString);
        return VitalDetailScreen(profileId: profileId, vitalType: vitalType);
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.importProfile,
      builder: (context, state) => const ImportProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.archivedProfiles,
      builder: (context, state) => const ArchivedProfilesScreen(),
    ),
    GoRoute(
      path: AppRoutes.exportProfile,
      builder: (context, state) {
        final profile = state.extra as Profile;
        return ExportProfileScreen(profile: profile);
      },
    ),
  ],
);
