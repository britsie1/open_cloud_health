import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/providers/checkups_provider.dart';
import 'package:open_cloud_health/providers/emergency_provider.dart';
import 'package:open_cloud_health/providers/history_provider.dart';
import 'package:open_cloud_health/providers/medications_provider.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/providers/vitals_provider.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:open_cloud_health/utils/result.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(const TimeOfDay(hour: 0, minute: 0));
  });

  group('Riverpod Providers with Drift Database Integration Tests', () {
    late AppDatabase db;
    late ProviderContainer container;
    late MockNotificationService mockNotificationService;
    late StreamController<String> markTakenController;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('PRAGMA foreign_keys = ON;');
        },
      ));
      mockNotificationService = MockNotificationService();
      markTakenController = StreamController<String>.broadcast();

      when(() => mockNotificationService.cancelNotification(any()))
          .thenAnswer((_) async => {});
      when(() => mockNotificationService.cancelMedicationNotifications(any()))
          .thenAnswer((_) async => {});
      when(() => mockNotificationService.syncEmergencyNotification(any()))
          .thenAnswer((_) async => {});
      when(() => mockNotificationService.scheduleDailyNotification(
            any(),
            any(),
            any(),
            any(),
            any(),
          )).thenAnswer((_) async => {});
      when(() => mockNotificationService.scheduleWeeklyNotification(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
          )).thenAnswer((_) async => {});
      when(() => mockNotificationService.setSystemAlarm(
            any(),
            any(),
            any(),
          )).thenAnswer((_) async => {});
      when(() => mockNotificationService.onMedicationMarkedTaken)
          .thenReturn(markTakenController);

      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(mockNotificationService),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await markTakenController.close();
      await db.close();
    });

    test('ProfilesNotifier saves, retrieves, updates and deletes profile in DB', () async {
      final notifier = container.read(profilesProvider.notifier);
      final addResult = await notifier.saveProfile(
        id: 'p-drift-1',
        name: 'Grace',
        middleNames: 'Brewster',
        surname: 'Hopper',
        dateOfBirth: DateTime(1906, 12, 9),
        gender: Gender.female,
        bloodType: 'AB+',
        isOrganDonor: true,
        trackOvulation: true,
        chronicConditions: ['Compiler Allergy'],
      );
      expect(addResult, isA<Success>());

      // Fetch profiles via provider
      final profiles = await container.read(profilesProvider.future);
      expect(profiles.length, 1);
      expect(profiles.first.id, 'p-drift-1');
      expect(profiles.first.name, 'Grace');

      // Update profile
      final existingProfile = profiles.first;
      final updatedProfile = Profile(
        id: existingProfile.id,
        name: existingProfile.name,
        middleNames: existingProfile.middleNames,
        surname: 'Hopper-Rear-Admiral',
        dateOfBirth: existingProfile.dateOfBirth,
        gender: existingProfile.gender,
        bloodType: existingProfile.bloodType,
        isOrganDonor: existingProfile.isOrganDonor,
        trackOvulation: existingProfile.trackOvulation,
        chronicConditions: existingProfile.chronicConditions,
      );
      final updateResult = await notifier.updateProfile(updatedProfile);
      expect(updateResult, isA<Success>());

      final updatedProfiles = await container.read(profilesProvider.future);
      expect(updatedProfiles.first.surname, 'Hopper-Rear-Admiral');

      // Delete profile
      final deleteResult = await notifier.deleteProfilePermanently('p-drift-1');
      expect(deleteResult, isA<Success>());

      final remainingProfiles = await container.read(profilesProvider.future);
      expect(remainingProfiles, isEmpty);
    });

    test('HistoryNotifier adds event, retrieves and integrates period logs', () async {
      // Seed profile
      await db.into(db.profiles).insert(
            ProfileEntry(
              id: 'p-hist',
              name: 'Dorothy',
              middleNames: '',
              surname: 'Hodgkin',
              dateOfBirth: DateTime(1910, 5, 12),
              bloodType: 'O+',
              gender: 'female',
              isOrganDonor: true,
              trackOvulation: true,
              isArchived: false,
              archivedAt: null,
              chronicConditions: '',
            ),
          );

      final historyNotifier = container.read(historyProvider('p-hist').notifier);
      final eventResult = await historyNotifier.saveEventWithAttachments(
        profileId: 'p-hist',
        title: 'Laboratory Session',
        description: 'Insulin crystal structure study',
        date: DateTime(1910, 6, 15),
        eventType: EventType.other,
        hasTime: true,
        attachments: [],
      );
      expect(eventResult, isA<Success>());

      final events = await container.read(historyProvider('p-hist').future);
      expect(events.any((e) => e.title == 'Laboratory Session'), true);

      // Add a period cycle and log directly in DB
      await db.into(db.periodCycles).insert(
            PeriodCycleEntry(
              id: 'pc-1',
              profileId: 'p-hist',
              startDate: DateTime(1910, 6, 1),
              endDate: DateTime(1910, 6, 5),
            ),
          );
      await db.into(db.periodLogs).insert(
            PeriodLogEntry(
              id: 'pl-1',
              cycleId: 'pc-1',
              date: DateTime(1910, 6, 1),
              flowLevel: 'medium',
            ),
          );

      // Invalidate and reload history events
      container.invalidate(historyProvider('p-hist'));
      final refreshedEvents = await container.read(historyProvider('p-hist').future);
      expect(refreshedEvents.length, greaterThanOrEqualTo(2));
    });

    test('MedicationsProvider, MedicationLogsProvider and MedicationAdherenceProvider', () async {
      const profileId = 'p-med';
      await db.into(db.profiles).insert(
            ProfileEntry(
              id: profileId,
              name: 'Ada',
              middleNames: '',
              surname: 'Lovelace',
              dateOfBirth: DateTime(1815, 12, 10),
              bloodType: 'A+',
              gender: 'female',
              isOrganDonor: true,
              trackOvulation: false,
              isArchived: false,
              archivedAt: null,
              chronicConditions: '',
            ),
          );

      final med = Medication(
        id: 'med-101',
        profileId: profileId,
        name: 'Penicillin',
        dosage: '1 capsule',
        type: 'Antibiotic',
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        timesOfDay: [const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 20, minute: 0)],
        notificationEnabled: true,
        alarmEnabled: false,
        trackInventory: true,
        stockQuantity: 20.0,
        lowStockThreshold: 4.0,
      );

      final medsNotifier = container.read(medicationsProvider(profileId).notifier);
      final addResult = await medsNotifier.addMedication(med);
      expect(addResult, isA<Success>());

      final meds = await container.read(medicationsProvider(profileId).future);
      expect(meds.length, 1);
      expect(meds.first.name, 'Penicillin');

      // Add a dose log
      final logsNotifier = container.read(medicationLogsProvider(profileId).notifier);
      final logResult = await logsNotifier.addLog(
        MedicationLog(
          id: 'mlog-1',
          medicationId: 'med-101',
          timestamp: DateTime.now(),
          isTaken: true,
          dosage: '1 capsule',
        ),
      );
      expect(logResult, isA<Success>());

      // Check adherence calculation
      final adherence = await container.read(medicationAdherenceProvider(profileId).future);
      expect(adherence.adherenceRate, isNotNull);

      // Verify stock was decremented
      final updatedMeds = await container.read(medicationsProvider(profileId).future);
      expect(updatedMeds.first.stockQuantity, 19.0);
    });

    test('CheckupsProvider and CheckupLogsProvider schedule and status derivation', () async {
      const profileId = 'p-chk';
      await db.into(db.profiles).insert(
            ProfileEntry(
              id: profileId,
              name: 'Florence',
              middleNames: '',
              surname: 'Nightingale',
              dateOfBirth: DateTime(1820, 5, 12),
              bloodType: 'O-',
              gender: 'female',
              isOrganDonor: true,
              trackOvulation: false,
              isArchived: false,
              archivedAt: null,
              chronicConditions: '',
            ),
          );

      // Add checkup via database
      await db.into(db.checkups).insert(
            CheckupsCompanion.insert(
              id: 'chk-annual',
              profileId: profileId,
              name: 'Annual Wellness Visit',
              frequencyInMonths: 12,
            ),
          );

      // Log a visit
      final checkupNotifier = container.read(checkupsProvider(profileId).notifier);
      await checkupNotifier.logCheckup(
        'chk-annual',
        DateTime.now().subtract(const Duration(days: 30)),
        notes: 'Vitals stable and routine bloodwork normal.',
      );

      final checkupsWithStatus = await container.read(checkupsProvider(profileId).future);
      expect(checkupsWithStatus.length, 1);
      expect(checkupsWithStatus.first.checkup.name, 'Annual Wellness Visit');
      expect(checkupsWithStatus.first.latestLog?.notes, contains('Vitals stable'));
    });

    test('VitalsProvider records and reads biometric entries', () async {
      const profileId = 'p-vit';
      await db.into(db.profiles).insert(
            ProfileEntry(
              id: profileId,
              name: 'Elizabeth',
              middleNames: '',
              surname: 'Blackwell',
              dateOfBirth: DateTime(1821, 2, 3),
              bloodType: 'B+',
              gender: 'female',
              isOrganDonor: true,
              trackOvulation: false,
              isArchived: false,
              archivedAt: null,
              chronicConditions: '',
            ),
          );

      final vitalsNotifier = container.read(vitalsProvider((profileId: profileId, type: VitalType.weight)).notifier);
      final logResult = await vitalsNotifier.addLog(
        VitalLog(
          id: 'v-weight-1',
          profileId: profileId,
          type: VitalType.weight,
          value1: 65.5,
          unit: 'kg',
          date: DateTime.now(),
          note: 'Post exercise weight',
        ),
      );
      expect(logResult, isA<Success>());

      final weightLogs = await container.read(vitalsProvider((profileId: profileId, type: VitalType.weight)).future);
      expect(weightLogs.length, 1);
      expect(weightLogs.first.value1, 65.5);
      expect(weightLogs.first.note, 'Post exercise weight');
    });

    test('EmergencyProvider and LockScreenSettingProvider integration', () async {
      const profileId = 'p-emg';
      await db.into(db.profiles).insert(
            ProfileEntry(
              id: profileId,
              name: 'Jane',
              middleNames: '',
              surname: 'Goodall',
              dateOfBirth: DateTime(1934, 4, 3),
              bloodType: 'A-',
              gender: 'female',
              isOrganDonor: true,
              trackOvulation: false,
              isArchived: false,
              archivedAt: null,
              chronicConditions: '',
            ),
          );

      // Test emergency contact addition
      final contact = EmergencyContact(
        profileId: profileId,
        name: 'Gombe Center',
        relationship: 'Colleague',
        phoneNumber: '+255-22-123456',
      );

      final contactNotifier = container.read(emergencyContactsProvider(profileId).notifier);
      await contactNotifier.addContact(contact);

      final contacts = await container.read(emergencyContactsProvider(profileId).future);
      expect(contacts.length, 1);
      expect(contacts.first.name, 'Gombe Center');

      // Test lock screen setting update
      final lockNotifier = container.read(lockScreenSettingsProvider(profileId).notifier);
      final initialSettings = await container.read(lockScreenSettingsProvider(profileId).future);
      expect(initialSettings.showMedications, true); // default

      final newSetting = LockScreenSetting(
        profileId: profileId,
        isEnabled: initialSettings.isEnabled,
        showName: initialSettings.showName,
        showAllergies: initialSettings.showAllergies,
        showMedications: false,
      );
      await lockNotifier.updateSettings(newSetting);
      final updatedSettings = await container.read(lockScreenSettingsProvider(profileId).future);
      expect(updatedSettings.showMedications, false);

      // Test primary profile provider
      final primaryNotifier = container.read(primaryProfileIdProvider.notifier);
      await primaryNotifier.setPrimaryProfileId(profileId);
      final primaryId = await container.read(primaryProfileIdProvider.future);
      expect(primaryId, profileId);
    });
  });
}
