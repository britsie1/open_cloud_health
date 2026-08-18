import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/checkup.dart';
import 'package:open_cloud_health/models/checkup_log.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/history_event.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/medication_log.dart';
import 'package:open_cloud_health/models/period_cycle.dart';
import 'package:open_cloud_health/models/period_log.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/vital_log.dart';
import 'package:open_cloud_health/repositories/checkups_repository.dart';
import 'package:open_cloud_health/repositories/emergency_repository.dart';
import 'package:open_cloud_health/repositories/history_repository.dart';
import 'package:open_cloud_health/repositories/medications_repository.dart';
import 'package:open_cloud_health/repositories/period_repository.dart';
import 'package:open_cloud_health/repositories/profiles_repository.dart';
import 'package:open_cloud_health/repositories/vitals_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('End-to-End Application Workflow Integration Tests with Drift DB', () {
    late AppDatabase db;
    late ProfilesRepository profilesRepo;
    late HistoryRepository historyRepo;
    late MedicationsRepository medsRepo;
    late CheckupsRepository checkupsRepo;
    late PeriodRepository periodRepo;
    late VitalsRepository vitalsRepo;
    late EmergencyRepository emergencyRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      profilesRepo = ProfilesRepository(db);
      historyRepo = HistoryRepository(db);
      medsRepo = MedicationsRepository(db);
      checkupsRepo = CheckupsRepository(db);
      periodRepo = PeriodRepository(db);
      vitalsRepo = VitalsRepository(db);
      emergencyRepo = EmergencyRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Full Patient Profile Lifecycle with Clinical Records, Adherence and Emergency Protocol', () async {
      // 1. Create Patient Profile
      final patient = Profile(
        id: 'patient-e2e-101',
        name: 'Alexander',
        middleNames: 'Fleming',
        surname: 'Scott',
        dateOfBirth: DateTime(1980, 5, 20),
        gender: Gender.male,
        bloodType: 'O-',
        isOrganDonor: true,
        chronicConditions: const ['Hypertension', 'Type 2 Diabetes'],
      );

      await profilesRepo.addProfile(patient);
      final activeProfiles = await profilesRepo.fetchProfiles(includeArchived: false);
      expect(activeProfiles.length, 1);
      expect(activeProfiles.first.id, patient.id);
      expect(activeProfiles.first.chronicConditions, contains('Hypertension'));

      // 2. Set as Primary Profile in DB
      await emergencyRepo.setPrimaryProfileId(patient.id);
      final primaryId = await emergencyRepo.getPrimaryProfileId();
      expect(primaryId, patient.id);

      // 3. Register Emergency Contacts and Lock Screen Protocol
      final ice1 = EmergencyContact(
        id: 'ice-1',
        profileId: patient.id,
        name: 'Sarah Scott',
        relationship: 'Spouse',
        phoneNumber: '+1-555-9876',
      );
      final ice2 = EmergencyContact(
        id: 'ice-2',
        profileId: patient.id,
        name: 'Dr. Gregory House',
        relationship: 'Physician',
        phoneNumber: '+1-555-4321',
      );

      await emergencyRepo.addEmergencyContact(ice1);
      await emergencyRepo.addEmergencyContact(ice2);

      final contacts = await emergencyRepo.getEmergencyContacts(patient.id);
      expect(contacts.length, 2);

      final setting = LockScreenSetting(
        profileId: patient.id,
        isEnabled: true,
        showName: true,
        showAllergies: true,
        showMedications: true,
      );
      await emergencyRepo.saveLockScreenSetting(setting);

      final lockSettings = await emergencyRepo.getLockScreenSetting(patient.id);
      expect(lockSettings.isEnabled, isTrue);
      expect(lockSettings.showMedications, isTrue);

      // 4. Clinical History Event with Details
      final event = HistoryEvent(
        id: 'evt-e2e-1',
        profileId: patient.id,
        date: DateTime(2026, 8, 1),
        title: 'Cardiology Annual Evaluation',
        description: 'ECG normal, blood pressure slightly elevated.',
      );
      await historyRepo.addEvent(event);

      final events = await historyRepo.fetchEvents(patient.id);
      expect(events.length, 1);
      expect(events.first.title, 'Cardiology Annual Evaluation');

      // 5. Prescribe Medication with Inventory Tracking
      final med = Medication(
        id: 'med-e2e-lisinopril',
        profileId: patient.id,
        name: 'Lisinopril',
        dosage: '1 tablet',
        type: 'Blood Pressure',
        daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
        timesOfDay: const [TimeOfDay(hour: 8, minute: 0)],
        trackInventory: true,
        stockQuantity: 30.0,
        lowStockThreshold: 5.0,
      );
      await medsRepo.addMedication(med);

      // Log 5 Doses & Verify Automatic Inventory Decrement
      for (int day = 1; day <= 5; day++) {
        await medsRepo.addLog(
          MedicationLog(
            id: 'log-e2e-$day',
            medicationId: med.id,
            timestamp: DateTime(2026, 8, day, 8, 0),
            isTaken: true,
            dosage: '1 tablet',
          ),
        );
      }

      final logs = await medsRepo.loadAllLogs(patient.id);
      expect(logs.length, 5);

      final updatedMeds = await medsRepo.loadMedications(patient.id);
      final updatedMed = updatedMeds.firstWhere((m) => m.id == med.id);
      expect(updatedMed.stockQuantity, 25.0);

      // 6. Record Vitals Data Stream
      await vitalsRepo.addLog(
        VitalLog(
          id: 'vital-e2e-1',
          profileId: patient.id,
          type: VitalType.bloodPressure,
          value1: 128.0,
          value2: 82.0,
          unit: 'mmHg',
          date: DateTime(2026, 8, 5, 8, 15),
          note: 'Resting BP after morning dose',
        ),
      );

      final bpLogs = await vitalsRepo.getLogs(patient.id, VitalType.bloodPressure);
      expect(bpLogs.length, 1);
      expect(bpLogs.first.value1, 128.0);
      expect(bpLogs.first.value2, 82.0);

      // 7. Schedule Preventive Checkup & Log Visit
      final checkup = Checkup(
        id: 'chk-e2e-lipid',
        profileId: patient.id,
        name: 'Lipid Panel',
        frequencyInMonths: 6,
      );
      await checkupsRepo.addCheckup(checkup);

      await checkupsRepo.addCheckupLog(
        CheckupLog(
          id: 'chk-log-e2e-1',
          checkupId: checkup.id,
          dateCompleted: DateTime(2026, 8, 10),
          notes: 'Total cholesterol 185 mg/dL - Normal range',
        ),
      );

      final checkupLogs = await checkupsRepo.loadAllLogsForProfile(patient.id);
      expect(checkupLogs.length, 1);
      expect(checkupLogs.first.notes, contains('Total cholesterol 185'));

      // 8. Period Cycle & Log
      await periodRepo.addCycle(
        PeriodCycle(
          id: 'cyc-e2e-1',
          profileId: patient.id,
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 5),
        ),
      );
      await periodRepo.upsertLog(
        PeriodLog(
          cycleId: 'cyc-e2e-1',
          date: DateTime(2026, 7, 1),
          flowLevel: FlowLevel.medium,
          moods: [Mood.calm],
          physicalSymptoms: [PhysicalSymptom.cramps],
        ),
      );

      final cycles = await periodRepo.getCycles(patient.id);
      expect(cycles.length, 1);

      // 9. Cascade Profile Deletion Verification
      await profilesRepo.deleteProfile(patient.id);

      final remainingProfiles = await profilesRepo.fetchProfiles(includeArchived: true);
      expect(remainingProfiles, isEmpty);

      final remainingEvents = await historyRepo.fetchEvents(patient.id);
      expect(remainingEvents, isEmpty);

      final remainingMeds = await medsRepo.loadMedications(patient.id);
      expect(remainingMeds, isEmpty);

      final remainingMedsLogs = await medsRepo.loadAllLogs(patient.id);
      expect(remainingMedsLogs, isEmpty);

      final remainingContacts = await emergencyRepo.getEmergencyContacts(patient.id);
      expect(remainingContacts, isEmpty);

      final remainingCycles = await periodRepo.getCycles(patient.id);
      expect(remainingCycles, isEmpty);
    });
  });
}
