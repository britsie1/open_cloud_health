import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/widgets/medication_adherence_card.dart';
import 'package:open_cloud_health/screens/archived_profiles.dart';
import 'package:open_cloud_health/screens/auth.dart';
import 'package:open_cloud_health/screens/checkups.dart';
import 'package:open_cloud_health/screens/emergency_settings.dart';
import 'package:open_cloud_health/screens/export_profile.dart';
import 'package:open_cloud_health/screens/history.dart';
import 'package:open_cloud_health/screens/history_event_detail.dart';
import 'package:open_cloud_health/screens/home.dart';
import 'package:open_cloud_health/screens/import_profile.dart';
import 'package:open_cloud_health/screens/medication_editor.dart';
import 'package:open_cloud_health/screens/medication_tracker.dart';
import 'package:open_cloud_health/screens/period_tracker.dart';
import 'package:open_cloud_health/screens/profile_detail.dart';
import 'package:open_cloud_health/screens/profiles.dart';
import 'package:open_cloud_health/screens/security_setup.dart';
import 'package:open_cloud_health/screens/settings.dart';
import 'package:open_cloud_health/screens/vital_detail_screen.dart';
import 'package:open_cloud_health/screens/welcome.dart';
import 'overflow_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late OverflowTestContext ctx;

  setUpAll(() async {
    ctx = await setupOverflowTestContext();
  });

  group('Screen Layout Overflow Matrix Tests', () {
    testWidgets('HomeScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'HomeScreen',
        ctx: ctx,
        screenBuilder: (c) => HomeScreen(
          profileId: c.sampleProfile.id,
          profile: c.sampleProfile,
        ),
      );
    });

    testWidgets('MedicationTrackerScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'MedicationTrackerScreen',
        ctx: ctx,
        screenBuilder: (c) => MedicationTrackerScreen(profileId: c.sampleProfile.id),
      );
    });

    testWidgets('MedicationEditorScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'MedicationEditorScreen',
        ctx: ctx,
        screenBuilder: (c) => MedicationEditorScreen(profileId: c.sampleProfile.id),
      );
    });

    testWidgets('EmergencySettingsScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'EmergencySettingsScreen',
        ctx: ctx,
        screenBuilder: (c) => EmergencySettingsScreen(profileId: c.sampleProfile.id),
      );
    });

    testWidgets('SettingsScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'SettingsScreen',
        ctx: ctx,
        screenBuilder: (c) => const SettingsScreen(),
      );
    });

    testWidgets('SecuritySetupScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'SecuritySetupScreen',
        ctx: ctx,
        screenBuilder: (c) => const SecuritySetupScreen(),
      );
    });

    testWidgets('ProfileDetailScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'ProfileDetailScreen',
        ctx: ctx,
        screenBuilder: (c) => ProfileDetailScreen(
          profileId: c.sampleProfile.id,
          profile: c.sampleProfile,
        ),
      );
    });

    testWidgets('ProfilesScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'ProfilesScreen',
        ctx: ctx,
        screenBuilder: (c) => const ProfilesScreen(),
      );
    });

    testWidgets('ArchivedProfilesScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'ArchivedProfilesScreen',
        ctx: ctx,
        screenBuilder: (c) => const ArchivedProfilesScreen(),
      );
    });

    testWidgets('HistoryScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'HistoryScreen',
        ctx: ctx,
        screenBuilder: (c) => HistoryScreen(
          profileId: c.sampleProfile.id,
          profile: c.sampleProfile,
        ),
      );
    });

    testWidgets('HistoryEventDetailScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'HistoryEventDetailScreen',
        ctx: ctx,
        screenBuilder: (c) => HistoryEventDetailScreen(profileId: c.sampleProfile.id),
      );
    });

    testWidgets('CheckupsScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'CheckupsScreen',
        ctx: ctx,
        screenBuilder: (c) => CheckupsScreen(profileId: c.sampleProfile.id),
      );
    });

    testWidgets('PeriodTrackerScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'PeriodTrackerScreen',
        ctx: ctx,
        screenBuilder: (c) => PeriodTrackerScreen(profileId: c.sampleProfile.id),
      );
    });

    testWidgets('VitalDetailScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'VitalDetailScreen_BP',
        ctx: ctx,
        screenBuilder: (c) => VitalDetailScreen(
          profileId: c.sampleProfile.id,
          vitalType: VitalType.bloodPressure,
        ),
      );
      await testScreenAcrossMatrix(
        tester,
        screenName: 'VitalDetailScreen_Weight',
        ctx: ctx,
        screenBuilder: (c) => VitalDetailScreen(
          profileId: c.sampleProfile.id,
          vitalType: VitalType.weight,
        ),
      );
    });

    testWidgets('ExportProfileScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'ExportProfileScreen',
        ctx: ctx,
        screenBuilder: (c) => ExportProfileScreen(profile: c.sampleProfile),
      );
    });

    testWidgets('ImportProfileScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'ImportProfileScreen',
        ctx: ctx,
        screenBuilder: (c) => const ImportProfileScreen(),
      );
    });

    testWidgets('AuthScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'AuthScreen',
        ctx: ctx,
        screenBuilder: (c) => const AuthScreen(),
      );
    });

    testWidgets('WelcomeScreen layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'WelcomeScreen',
        ctx: ctx,
        screenBuilder: (c) => const WelcomeScreen(),
      );
    });

    testWidgets('MedicationAdherenceCard streak panel layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'MedicationAdherenceCard',
        ctx: ctx,
        screenBuilder: (c) => Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: MedicationAdherenceCard(profileId: c.sampleProfile.id),
          ),
        ),
      );
    });

    testWidgets('Privacy & Disclaimer Dialog layout across device & text scale matrix', (tester) async {
      await testScreenAcrossMatrix(
        tester,
        screenName: 'PrivacyDisclaimerDialog',
        ctx: ctx,
        screenBuilder: (c) => Center(
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.privacy_tip_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Privacy & Disclaimer',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medical Disclaimer',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Open Cloud Health is an informational logbook application for tracking personal medical histories, medication times, checkup schedules, and cycles. It does not provide professional medical advice, diagnosis, or treatment. Always consult a qualified physician or healthcare provider with any questions you have regarding a medical condition or treatment.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Privacy Policy',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Local Storage: All medical histories, symptoms, medication logs, and biometrics are stored strictly on your local device. The developer has zero access to your information.\n\n'
                    '• Cloud Backup: If you manually connect Google Drive, the database and attachments are stored directly in your personal Google Drive\'s secure App Data folder. With End-to-End Encryption enabled, your backups are client-side encrypted with AES-256 before upload.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {},
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    });
  });
}
