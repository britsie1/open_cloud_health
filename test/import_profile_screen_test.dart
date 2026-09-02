import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/checkup.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/insurance_policy.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/profile_share_models.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/screens/import_profile.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Import Profile Screen & Bundle Integration Tests', () {
    testWidgets('ImportProfileScreen renders both import options and security banner', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ImportProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Import'), findsOneWidget);
      expect(find.text('Import Health Data'), findsOneWidget);
      expect(find.text('Import Profile from File'), findsOneWidget);
      expect(find.text('Restore Full Backup from File'), findsOneWidget);
      expect(find.text('Secure & Processed Offline'), findsOneWidget);
      expect(find.byIcon(Icons.person_add_alt_1_outlined), findsOneWidget);
      expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
    });

    test('ProfilesNotifier.importProfileBundle accurately inserts all profile entities into database', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final mockNotificationService = MockNotificationService();
      when(() => mockNotificationService.syncEmergencyNotification(any()))
          .thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(mockNotificationService),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      final sampleProfile = Profile(
        id: 'bundle-test-profile-1',
        name: 'Marie',
        middleNames: 'Sklodowska',
        surname: 'Curie',
        dateOfBirth: DateTime(1867, 11, 7),
        gender: Gender.female,
        bloodType: 'A+',
        isOrganDonor: true,
        trackOvulation: true,
        chronicConditions: ['Radiation Dermatitis'],
      );

      final bundle = SharedProfileBundle(
        profile: sampleProfile,
        sharedBy: 'Dr. Pierre Curie',
        sharedAt: DateTime.now(),
        moduleOptions: const ShareModuleOptions(),
        allergies: [
          Allergy(id: 'a-1', profileId: sampleProfile.id, name: 'Latex', note: 'Mild rash'),
        ],
        medications: [
          MedicationShareBundle(
            medication: Medication(
              id: 'm-1',
              profileId: sampleProfile.id,
              name: 'Zinc Oxide Cream',
              dosage: 'Apply twice daily',
              type: 'Cream',
            ),
            logs: [],
          ),
        ],
        checkups: [
          CheckupShareBundle(
            checkup: Checkup(
              id: 'c-1',
              profileId: sampleProfile.id,
              name: 'Blood Count & Marrow Screen',
              frequencyInMonths: 3,
            ),
            logs: [],
          ),
        ],
        periodCycles: [],
        vitals: [
          VitalLog(
            id: 'v-1',
            profileId: sampleProfile.id,
            type: VitalType.bloodPressure,
            date: DateTime(2026, 8, 20),
            value1: 118,
            value2: 76,
            unit: 'mmHg',
          ),
        ],
        historyEvents: [
          HistoryEvent(
            id: 'h-1',
            profileId: sampleProfile.id,
            title: 'Laboratory Consultation',
            description: 'Routine blood panel screening',
            date: DateTime(2026, 8, 15),
          ),
        ],
        emergencyContacts: [
          EmergencyContact(
            id: 'e-1',
            profileId: sampleProfile.id,
            name: 'Pierre Curie',
            relationship: 'Spouse',
            phoneNumber: '+33 1 23 45 67',
          ),
        ],
        lockScreenSetting: LockScreenSetting(
          profileId: sampleProfile.id,
          showName: true,
          showAge: true,
          showBloodType: true,
          showOrganDonor: true,
          showChronicConditions: true,
          showAllergies: true,
          showMedications: true,
          showContacts: true,
          showInsurance: true,
          isEnabled: true,
        ),
        insurance: InsurancePolicy(
          id: 'ins-1',
          profileId: sampleProfile.id,
          provider: 'Medical Care International',
          planName: 'Premier Gold',
          policyNumber: 'MC-1867-CURIE',
        ),
      );

      // Perform import
      final imported = await container.read(profilesProvider.notifier).importProfileBundle(bundle);

      expect(imported.id, 'bundle-test-profile-1');
      expect(imported.name, 'Marie');
      expect(imported.surname, 'Curie');
      expect(imported.isShared, isFalse);
      expect(imported.isReadOnly, isFalse);

      // Verify records in DB
      final dbProfiles = await db.select(db.profiles).get();
      expect(dbProfiles.length, 1);
      expect(dbProfiles.first.name, 'Marie');
      expect(dbProfiles.first.chronicConditions, 'Radiation Dermatitis');

      final dbAllergies = await db.select(db.allergy).get();
      expect(dbAllergies.length, 1);
      expect(dbAllergies.first.name, 'Latex');

      final dbMeds = await db.select(db.medications).get();
      expect(dbMeds.length, 1);
      expect(dbMeds.first.name, 'Zinc Oxide Cream');

      final dbCheckups = await db.select(db.checkups).get();
      expect(dbCheckups.length, 1);
      expect(dbCheckups.first.name, 'Blood Count & Marrow Screen');

      final dbVitals = await db.select(db.vitalLogs).get();
      expect(dbVitals.length, 1);
      expect(dbVitals.first.value1, 118);

      final dbHistory = await db.select(db.history).get();
      expect(dbHistory.length, 1);
      expect(dbHistory.first.title, 'Laboratory Consultation');

      final dbContacts = await db.select(db.emergencyContacts).get();
      expect(dbContacts.length, 1);
      expect(dbContacts.first.name, 'Pierre Curie');

      final dbLock = await db.select(db.lockScreenSettings).get();
      expect(dbLock.length, 1);
      expect(dbLock.first.isEnabled, isTrue);

      final dbInsurance = await db.select(db.insurance).get();
      expect(dbInsurance.length, 1);
      expect(dbInsurance.first.policyNumber, 'MC-1867-CURIE');
    });
  });
}
