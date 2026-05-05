import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/history_event.dart' as history;
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/screens/auth.dart';
import 'package:open_cloud_health/screens/checkups.dart';
import 'package:open_cloud_health/screens/history.dart';
import 'package:open_cloud_health/screens/history_event_detail.dart';
import 'package:open_cloud_health/screens/measurements.dart';
import 'package:open_cloud_health/screens/medication_tracker.dart';
import 'package:open_cloud_health/screens/period_tracker.dart';
import 'package:open_cloud_health/screens/profile_detail.dart';
import 'package:open_cloud_health/screens/profiles.dart';
import 'package:open_cloud_health/screens/settings.dart';
import 'package:open_cloud_health/utils/constants.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.auth,
  routes: [
    GoRoute(
      path: AppRoutes.auth,
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: AppRoutes.profiles,
      builder: (context, state) => const ProfilesScreen(),
    ),
    GoRoute(
      path: AppRoutes.profileDetail,
      builder: (context, state) {
        final profile = state.extra as Profile?;
        return ProfileDetailScreen(profile: profile);
      },
    ),
    GoRoute(
      path: '${AppRoutes.history}/:profileId',
      builder: (context, state) {
        final profile = state.extra as Profile;
        return HistoryScreen(profile: profile);
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
      path: '${AppRoutes.medicationTracker}/:profileId',
      builder: (context, state) {
        final profileId = state.pathParameters['profileId']!;
        return MedicationTrackerScreen(profileId: profileId);
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
      path: '${AppRoutes.measurements}/:profileId',
      builder: (context, state) {
        final profileId = state.pathParameters['profileId']!;
        return MeasurementsScreen(profileId: profileId);
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
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
