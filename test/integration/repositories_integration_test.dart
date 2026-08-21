import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/attachment.dart';
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
import 'package:open_cloud_health/repositories/allergies_repository.dart';
import 'package:open_cloud_health/repositories/attachment_repository.dart';
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

  group('Drift Repositories Full Integration Tests', () {
    late AppDatabase db;
    late ProfilesRepository profilesRepo;
    late HistoryRepository historyRepo;
    late AttachmentRepository attachmentRepo;
    late AllergiesRepository allergiesRepo;
    late MedicationsRepository medicationsRepo;
    late CheckupsRepository checkupsRepo;
    late PeriodRepository periodRepo;
    late VitalsRepository vitalsRepo;
    late EmergencyRepository emergencyRepo;

    Future<void> seedProfiles(List<String> ids) async {
      for (final id in ids) {
        await profilesRepo.addProfile(Profile(
          id: id,
          name: 'Test Profile $id',
          middleNames: '',
          surname: 'User',
          dateOfBirth: DateTime(1990, 1, 1),
          gender: Gender.female,
          bloodType: 'O+',
          isOrganDonor: true,
        ));
      }
    }

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      profilesRepo = ProfilesRepository(db);
      historyRepo = HistoryRepository(db);
      attachmentRepo = AttachmentRepository(db);
      allergiesRepo = AllergiesRepository(db);
      medicationsRepo = MedicationsRepository(db);
      checkupsRepo = CheckupsRepository(db);
      periodRepo = PeriodRepository(db);
      vitalsRepo = VitalsRepository(db);
      emergencyRepo = EmergencyRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    // -------------------------------------------------------------
    // 1. ProfilesRepository Tests
    // -------------------------------------------------------------
    group('ProfilesRepository', () {
      test('Add, update, fetch active vs archived profiles', () async {
        final activeProfile = Profile(
          id: 'prof-1',
          name: 'Sarah',
          middleNames: 'Jane',
          surname: 'Connor',
          dateOfBirth: DateTime(1985, 5, 20),
          gender: Gender.female,
          bloodType: 'O+',
          isOrganDonor: true,
          trackOvulation: true,
          isArchived: false,
          chronicConditions: ['Asthma'],
        );

        final archivedProfile = Profile(
          id: 'prof-2',
          name: 'John',
          middleNames: '',
          surname: 'Connor',
          dateOfBirth: DateTime(1995, 2, 28),
          gender: Gender.male,
          bloodType: 'O-',
          isOrganDonor: false,
          trackOvulation: false,
          isArchived: true,
          archivedAt: DateTime(2026, 1, 1),
          chronicConditions: [],
        );

        await profilesRepo.addProfile(activeProfile);
        await profilesRepo.addProfile(archivedProfile);

        // Fetch active profiles only
        final activeList = await profilesRepo.fetchProfiles();
        expect(activeList.length, 1);
        expect(activeList.first.name, 'Sarah');
        expect(activeList.first.chronicConditions, contains('Asthma'));

        // Fetch archived profiles
        final archivedList = await profilesRepo.fetchArchivedProfiles();
        expect(archivedList.length, 1);
        expect(archivedList.first.name, 'John');

        // Unarchive
        await profilesRepo.restoreProfile('prof-2');
        expect((await profilesRepo.fetchProfiles()).length, 2);
        expect(await profilesRepo.fetchArchivedProfiles(), isEmpty);

        // Archive again
        await profilesRepo.archiveProfile('prof-1');
        expect((await profilesRepo.fetchProfiles()).length, 1);
        expect((await profilesRepo.fetchArchivedProfiles()).length, 1);
      });

      test('Deep cascade deletion of profile cleans up all related records', () async {
        final profile = Profile(
          id: 'prof-cascade-root',
          name: 'Root',
          middleNames: '',
          surname: 'Cascade',
          dateOfBirth: DateTime(1990, 1, 1),
          gender: Gender.female,
          bloodType: 'AB-',
          isOrganDonor: true,
        );
        await profilesRepo.addProfile(profile);

        // Add history + attachment
        await historyRepo.addEvent(HistoryEvent(
          id: 'hist-cascade-1',
          profileId: 'prof-cascade-root',
          title: 'Cascade Event',
          description: 'Desc',
          date: DateTime.now(),
        ));
        await attachmentRepo.insertAttachment(Attachment(
          id: 'att-cascade-1',
          historyId: 'hist-cascade-1',
          filename: 'scan.pdf',
          uploadDate: DateTime.now(),
          byteLength: 1024,
        ));

        // Add allergy
        await allergiesRepo.addAllergy(Allergy(
          id: 'all-cascade-1',
          profileId: 'prof-cascade-root',
          name: 'Penicillin',
          note: '',
        ));

        // Add medication + log
        await medicationsRepo.addMedication(Medication(
          id: 'med-cascade-1',
          profileId: 'prof-cascade-root',
          name: 'Cascade Med',
          dosage: '1 pill',
          timeOfDay: const TimeOfDay(hour: 8, minute: 0),
          daysOfWeek: [1],
          timesOfDay: [const TimeOfDay(hour: 8, minute: 0)],
        ));
        await medicationsRepo.addLog(MedicationLog(
          id: 'mlog-cascade-1',
          medicationId: 'med-cascade-1',
          timestamp: DateTime.now(),
          isTaken: true,
        ));

        // Add checkup + log
        await checkupsRepo.addCheckup(Checkup(
          id: 'chk-cascade-1',
          profileId: 'prof-cascade-root',
          name: 'Cascade Check',
          frequencyInMonths: 6,
        ));
        await checkupsRepo.addCheckupLog(CheckupLog(
          id: 'chkl-cascade-1',
          checkupId: 'chk-cascade-1',
          dateCompleted: DateTime.now(),
        ));

        // Add period cycle + log
        await periodRepo.addCycle(PeriodCycle(
          id: 'cyc-cascade-1',
          profileId: 'prof-cascade-root',
          startDate: DateTime.now(),
        ));
        await periodRepo.upsertLog(PeriodLog(
          id: 'plog-cascade-1',
          cycleId: 'cyc-cascade-1',
          date: DateTime.now(),
        ));

        // Add vital log
        await vitalsRepo.addLog(VitalLog(
          id: 'vit-cascade-1',
          profileId: 'prof-cascade-root',
          type: VitalType.heartRate,
          date: DateTime.now(),
          value1: 72.0,
          unit: 'bpm',
        ));

        // Add emergency contact + lock screen setting
        await emergencyRepo.addEmergencyContact(EmergencyContact(
          id: 'ec-cascade-1',
          profileId: 'prof-cascade-root',
          name: 'Contact',
          relationship: 'Friend',
          phoneNumber: '12345',
        ));
        await emergencyRepo.saveLockScreenSetting(LockScreenSetting(
          profileId: 'prof-cascade-root',
          isEnabled: true,
        ));

        // Execute deep cascade deletion
        await profilesRepo.deleteProfilePermanently('prof-cascade-root');

        // Assert all 9 child repositories are empty for this profile
        expect(await profilesRepo.getProfile('prof-cascade-root'), isNull);
        expect(await historyRepo.fetchEvents('prof-cascade-root'), isEmpty);
        expect(await attachmentRepo.getAttachments('hist-cascade-1'), isEmpty);
        expect(await allergiesRepo.getAllergies('prof-cascade-root'), isEmpty);
        expect(await medicationsRepo.loadMedications('prof-cascade-root'), isEmpty);
        expect(await medicationsRepo.loadAllLogs('prof-cascade-root'), isEmpty);
        expect(await checkupsRepo.loadCheckups('prof-cascade-root'), isEmpty);
        expect(await checkupsRepo.loadLogsForCheckup('chk-cascade-1'), isEmpty);
        expect(await periodRepo.getCycles('prof-cascade-root'), isEmpty);
        expect(await periodRepo.getLogsForCycle('cyc-cascade-1'), isEmpty);
        expect(await vitalsRepo.getLogs('prof-cascade-root', VitalType.heartRate), isEmpty);
        expect(await emergencyRepo.getEmergencyContacts('prof-cascade-root'), isEmpty);
      });

      test('watchProfiles emits updates when profile is added or updated', () async {
        final stream = profilesRepo.watchProfiles();
        final expectation = expectLater(
          stream,
          emitsThrough(predicate<List<Profile>>((list) => list.any((p) => p.name == 'Stream User'))),
        );

        await profilesRepo.addProfile(Profile(
          id: 'prof-stream',
          name: 'Stream User',
          middleNames: '',
          surname: 'Tester',
          dateOfBirth: DateTime(2000, 1, 1),
          gender: Gender.male,
          bloodType: 'B+',
          isOrganDonor: true,
        ));

        await expectation;
      });
    });

    // -------------------------------------------------------------
    // 2. HistoryRepository & AttachmentRepository Tests
    // -------------------------------------------------------------
    group('HistoryRepository & AttachmentRepository', () {
      setUp(() async {
        await seedProfiles(['prof-hist', 'prof-1']);
      });

      test('History event join queries attachment counts accurately', () async {
        final event = HistoryEvent(
          id: 'hist-10',
          profileId: 'prof-hist',
          title: 'Cardiology Check',
          description: 'ECG and Stress Test',
          date: DateTime(2026, 3, 10, 14, 30),
          eventType: EventType.checkup,
          hasTime: true,
          provider: 'Dr. Heart',
          facility: 'Cardio Center',
        );

        await historyRepo.addEvent(event);

        // Before adding attachments, attachmentCount should be 0
        var events = await historyRepo.fetchEvents('prof-hist');
        expect(events.length, 1);
        expect(events.first.attachmentCount, 0);

        // Add 2 attachments
        await attachmentRepo.insertAttachment(Attachment(
          id: 'att-1',
          historyId: 'hist-10',
          filename: 'ecg_trace.pdf',
          uploadDate: DateTime(2026, 3, 10),
          byteLength: 204800,
        ));
        await attachmentRepo.insertAttachment(Attachment(
          id: 'att-2',
          historyId: 'hist-10',
          filename: 'stress_report.pdf',
          uploadDate: DateTime(2026, 3, 10),
          byteLength: 512000,
        ));

        events = await historyRepo.fetchEvents('prof-hist');
        expect(events.length, 1);
        expect(events.first.attachmentCount, 2);
        expect(events.first.provider, 'Dr. Heart');
        expect(events.first.facility, 'Cardio Center');

        // Query single attachment
        final singleAtt = await attachmentRepo.getAttachment('att-1');
        expect(singleAtt?.filename, 'ecg_trace.pdf');
        expect(singleAtt?.byteLength, 204800);

        // Bulk delete attachments
        await attachmentRepo.deleteAttachments(['att-1', 'att-2']);
        final remainingAtts = await attachmentRepo.getAttachments('hist-10');
        expect(remainingAtts, isEmpty);
      });

      test('Deleting history event cascades to delete attached files records', () async {
        await historyRepo.addEvent(HistoryEvent(
          id: 'hist-del',
          profileId: 'prof-1',
          title: 'To Delete',
          description: '',
          date: DateTime(2026, 1, 1),
        ));
        await attachmentRepo.insertAttachment(Attachment(
          id: 'att-del-1',
          historyId: 'hist-del',
          filename: 'test.pdf',
          uploadDate: DateTime(2026, 1, 1),
          byteLength: 100,
        ));

        await historyRepo.deleteEvent('hist-del');

        expect(await historyRepo.fetchEvents('prof-1'), isEmpty);
        expect(await attachmentRepo.getAttachments('hist-del'), isEmpty);
      });
    });

    // -------------------------------------------------------------
    // 3. AllergiesRepository Tests
    // -------------------------------------------------------------
    group('AllergiesRepository', () {
      setUp(() async {
        await seedProfiles(['p1', 'p2']);
      });

      test('Add, fetch, watch, and delete allergies', () async {
        final a1 = Allergy(id: 'all-1', profileId: 'p1', name: 'Latex', note: 'Contact rash');
        final a2 = Allergy(id: 'all-2', profileId: 'p1', name: 'Pollen', note: 'Seasonal');
        final a3 = Allergy(id: 'all-3', profileId: 'p2', name: 'Sulfa', note: 'Severe rash');

        await allergiesRepo.addAllergy(a1);
        await allergiesRepo.addAllergy(a2);
        await allergiesRepo.addAllergy(a3);

        final p1Allergies = await allergiesRepo.getAllergies('p1');
        expect(p1Allergies.length, 2);
        expect(p1Allergies.map((a) => a.name), containsAll(['Latex', 'Pollen']));

        await allergiesRepo.deleteAllergy('all-1');
        final p1AfterDelete = await allergiesRepo.getAllergies('p1');
        expect(p1AfterDelete.length, 1);
        expect(p1AfterDelete.first.name, 'Pollen');
      });

      test('setAllergies updates entire list of allergies in single transaction', () async {
        await allergiesRepo.addAllergy(Allergy(id: 'all-old', profileId: 'p1', name: 'Dust', note: ''));

        final newAllergies = [
          Allergy(id: 'all-new-1', profileId: 'p1', name: 'Penicillin', note: 'Anaphylaxis'),
          Allergy(id: 'all-new-2', profileId: 'p1', name: 'Peanuts', note: 'Hives'),
        ];

        await allergiesRepo.setAllergies('p1', newAllergies);

        final result = await allergiesRepo.getAllergies('p1');
        expect(result.length, 2);
        expect(result.map((a) => a.name), containsAll(['Penicillin', 'Peanuts']));
        expect(result.any((a) => a.name == 'Dust'), isFalse);
      });
    });

    // -------------------------------------------------------------
    // 4. MedicationsRepository Tests
    // -------------------------------------------------------------
    group('MedicationsRepository', () {
      setUp(() async {
        await seedProfiles(['p1']);
      });

      test('Add medication with multi-time dosage and serialization', () async {
        final med = Medication(
          id: 'med-complex',
          profileId: 'p1',
          name: 'Metformin',
          dosage: '500 mg',
          type: 'Tablet',
          notificationEnabled: true,
          alarmEnabled: false,
          timeOfDay: const TimeOfDay(hour: 8, minute: 0),
          isActive: true,
          daysOfWeek: [1, 3, 5],
          timesOfDay: [
            const TimeOfDay(hour: 8, minute: 0),
            const TimeOfDay(hour: 13, minute: 30),
            const TimeOfDay(hour: 20, minute: 0),
          ],
          isAsNeeded: false,
          trackInventory: true,
          stockQuantity: 60.0,
          lowStockThreshold: 10.0,
        );

        await medicationsRepo.addMedication(med);

        final loadedList = await medicationsRepo.loadMedications('p1');
        expect(loadedList.length, 1);
        final loaded = loadedList.first;
        expect(loaded.name, 'Metformin');
        expect(loaded.dosage, '500 mg');
        expect(loaded.daysOfWeek, [1, 3, 5]);
        expect(loaded.timesOfDay.length, 3);
        expect(loaded.timesOfDay[1], const TimeOfDay(hour: 13, minute: 30));
        expect(loaded.trackInventory, true);
        expect(loaded.stockQuantity, 60.0);
        expect(loaded.lowStockThreshold, 10.0);
      });

      test('Inventory stock automatically decrements when log is added', () async {
        final med = Medication(
          id: 'med-inv',
          profileId: 'p1',
          name: 'Vitamin D3',
          dosage: '2 drops',
          type: 'Liquid',
          notificationEnabled: false,
          alarmEnabled: false,
          timeOfDay: const TimeOfDay(hour: 9, minute: 0),
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          timesOfDay: [const TimeOfDay(hour: 9, minute: 0)],
          trackInventory: true,
          stockQuantity: 50.0,
          lowStockThreshold: 10.0,
        );
        await medicationsRepo.addMedication(med);

        // Add dose log (taking 2 drops)
        await medicationsRepo.addLog(MedicationLog(
          id: 'mlog-1',
          medicationId: 'med-inv',
          timestamp: DateTime(2026, 8, 18, 9, 0),
          isTaken: true,
          dosage: '2 drops',
        ));

        var updatedMeds = await medicationsRepo.loadMedications('p1');
        expect(updatedMeds.first.stockQuantity, 48.0);

        // Add another log with custom dosage
        await medicationsRepo.addLog(MedicationLog(
          id: 'mlog-2',
          medicationId: 'med-inv',
          timestamp: DateTime(2026, 8, 18, 21, 0),
          isTaken: true,
          dosage: '3 drops',
        ));

        updatedMeds = await medicationsRepo.loadMedications('p1');
        expect(updatedMeds.first.stockQuantity, 45.0);
      });

      test('Inventory stock automatically replenishes when log is removed', () async {
        final med = Medication(
          id: 'med-replenish',
          profileId: 'p1',
          name: 'Paracetamol',
          dosage: '1 tablet',
          type: 'Tablet',
          notificationEnabled: false,
          alarmEnabled: false,
          timeOfDay: const TimeOfDay(hour: 12, minute: 0),
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          timesOfDay: [const TimeOfDay(hour: 12, minute: 0)],
          trackInventory: true,
          stockQuantity: 10.0,
        );
        await medicationsRepo.addMedication(med);

        final testDate = DateTime(2026, 8, 18, 12, 0);
        await medicationsRepo.addLog(MedicationLog(
          id: 'log-rep-1',
          medicationId: 'med-replenish',
          timestamp: testDate,
          isTaken: true,
          dosage: '1 tablet',
        ));

        var medList = await medicationsRepo.loadMedications('p1');
        expect(medList.first.stockQuantity, 9.0);

        // Remove log
        await medicationsRepo.removeLog('med-replenish', testDate, time: const TimeOfDay(hour: 12, minute: 0));

        medList = await medicationsRepo.loadMedications('p1');
        expect(medList.first.stockQuantity, 10.0);
      });

      test('loadLogsForDate and loadAllLogs with pagination', () async {
        final med = Medication(
          id: 'med-logs',
          profileId: 'p1',
          name: 'Aspirin',
          dosage: '100 mg',
          type: 'Pill',
          notificationEnabled: false,
          alarmEnabled: false,
          timeOfDay: const TimeOfDay(hour: 8, minute: 0),
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          timesOfDay: [const TimeOfDay(hour: 8, minute: 0)],
        );
        await medicationsRepo.addMedication(med);

        // Add 5 logs across different dates
        for (int i = 1; i <= 5; i++) {
          await medicationsRepo.addLog(MedicationLog(
            id: 'l-$i',
            medicationId: 'med-logs',
            timestamp: DateTime(2026, 8, i, 8, 0),
            isTaken: true,
          ));
        }

        // Date-specific filter
        final dateLogs = await medicationsRepo.loadLogsForDate(DateTime(2026, 8, 3), 'p1');
        expect(dateLogs.length, 1);
        expect(dateLogs.first.id, 'l-3');

        // Paginated all logs
        final page1 = await medicationsRepo.loadAllLogs('p1', limit: 2, offset: 0);
        expect(page1.length, 2);
        expect(page1[0].id, 'l-5'); // Ordered desc
        expect(page1[1].id, 'l-4');

        final page2 = await medicationsRepo.loadAllLogs('p1', limit: 2, offset: 2);
        expect(page2.length, 2);
        expect(page2[0].id, 'l-3');
        expect(page2[1].id, 'l-2');
      });

      test('Deleting medication deletes its logs in a transaction', () async {
        final med = Medication(
          id: 'med-to-del',
          profileId: 'p1',
          name: 'Temporary Med',
          dosage: '10 mg',
          type: 'Pill',
          notificationEnabled: false,
          alarmEnabled: false,
          timeOfDay: const TimeOfDay(hour: 8, minute: 0),
          daysOfWeek: [1],
          timesOfDay: [const TimeOfDay(hour: 8, minute: 0)],
        );
        await medicationsRepo.addMedication(med);
        await medicationsRepo.addLog(MedicationLog(
          id: 'log-orphan',
          medicationId: 'med-to-del',
          timestamp: DateTime(2026, 8, 1),
          isTaken: true,
        ));

        await medicationsRepo.deleteMedication('med-to-del');

        expect(await medicationsRepo.loadMedications('p1'), isEmpty);
        expect(await medicationsRepo.loadAllLogs('p1'), isEmpty);
      });
    });

    // -------------------------------------------------------------
    // 5. CheckupsRepository Tests
    // -------------------------------------------------------------
    group('CheckupsRepository', () {
      setUp(() async {
        await seedProfiles(['p1']);
      });

      test('Add checkup, log visits, fetch latest log and profile logs', () async {
        final checkup = Checkup(
          id: 'chk-derm',
          profileId: 'p1',
          name: 'Dermatologist Skin Check',
          frequencyInMonths: 12,
          iconName: 'skin',
          isCustomInterval: false,
          isActive: true,
        );
        await checkupsRepo.addCheckup(checkup);

        // Add 2 logs on different dates
        await checkupsRepo.addCheckupLog(CheckupLog(
          id: 'log-derm-1',
          checkupId: 'chk-derm',
          dateCompleted: DateTime(2025, 5, 10),
          doctorName: 'Dr. Skin',
          location: 'City Clinic',
          notes: 'Year 2025 mole map normal',
        ));
        await checkupsRepo.addCheckupLog(CheckupLog(
          id: 'log-derm-2',
          checkupId: 'chk-derm',
          dateCompleted: DateTime(2026, 5, 15),
          doctorName: 'Dr. Skin',
          location: 'City Clinic',
          notes: 'Year 2026 check complete',
        ));

        // Test getLatestLogForCheckup
        final latest = await checkupsRepo.getLatestLogForCheckup('chk-derm');
        expect(latest?.id, 'log-derm-2');
        expect(latest?.notes, 'Year 2026 check complete');

        // Test loadAllLogsForProfile (join checkups + checkup_logs)
        final profileLogs = await checkupsRepo.loadAllLogsForProfile('p1');
        expect(profileLogs.length, 2);

        // Test deleteCheckupLog
        await checkupsRepo.deleteCheckupLog('log-derm-1');
        final remainingLogs = await checkupsRepo.loadLogsForCheckup('chk-derm');
        expect(remainingLogs.length, 1);
        expect(remainingLogs.first.id, 'log-derm-2');
      });
    });

    // -------------------------------------------------------------
    // 6. PeriodRepository Tests
    // -------------------------------------------------------------
    group('PeriodRepository', () {
      setUp(() async {
        await seedProfiles(['p1']);
      });

      test('Cycle management and upsertLog updating existing day records', () async {
        final cycle = PeriodCycle(
          id: 'cyc-1',
          profileId: 'p1',
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 5),
        );
        await periodRepo.addCycle(cycle);

        final logDate = DateTime(2026, 7, 1);

        // First insert
        await periodRepo.upsertLog(PeriodLog(
          id: 'plog-1',
          cycleId: 'cyc-1',
          date: logDate,
          flowLevel: FlowLevel.light,
          moods: [Mood.calm],
          physicalSymptoms: [PhysicalSymptom.headache],
        ));

        var logs = await periodRepo.getLogsForCycle('cyc-1');
        expect(logs.length, 1);
        expect(logs.first.flowLevel, FlowLevel.light);
        expect(logs.first.moods, [Mood.calm]);

        // Upsert on same date -> Should update existing row without creating duplicate
        await periodRepo.upsertLog(PeriodLog(
          id: 'plog-ignored-id',
          cycleId: 'cyc-1',
          date: logDate,
          flowLevel: FlowLevel.heavy,
          moods: [Mood.irritable, Mood.anxious],
          physicalSymptoms: [PhysicalSymptom.cramps, PhysicalSymptom.bloating],
        ));

        logs = await periodRepo.getLogsForCycle('cyc-1');
        expect(logs.length, 1, reason: 'Upsert should update existing day record');
        expect(logs.first.flowLevel, FlowLevel.heavy);
        expect(logs.first.moods, containsAll([Mood.irritable, Mood.anxious]));
        expect(logs.first.physicalSymptoms, containsAll([PhysicalSymptom.cramps, PhysicalSymptom.bloating]));

        // Deleting cycle deletes its logs
        await periodRepo.deleteCycle('cyc-1');
        expect(await periodRepo.getCycles('p1'), isEmpty);
        expect(await periodRepo.getLogsForCycle('cyc-1'), isEmpty);
      });
    });

    // -------------------------------------------------------------
    // 7. VitalsRepository Tests
    // -------------------------------------------------------------
    group('VitalsRepository', () {
      setUp(() async {
        await seedProfiles(['p1']);
      });

      test('Add and fetch logs across VitalTypes sorted chronologically', () async {
        await vitalsRepo.addLog(VitalLog(
          id: 'v-bp-2',
          profileId: 'p1',
          type: VitalType.bloodPressure,
          date: DateTime(2026, 8, 18, 18, 0),
          value1: 125.0,
          value2: 82.0,
          unit: 'mmHg',
        ));
        await vitalsRepo.addLog(VitalLog(
          id: 'v-bp-1',
          profileId: 'p1',
          type: VitalType.bloodPressure,
          date: DateTime(2026, 8, 18, 8, 0),
          value1: 118.0,
          value2: 78.0,
          unit: 'mmHg',
        ));
        await vitalsRepo.addLog(VitalLog(
          id: 'v-wt-1',
          profileId: 'p1',
          type: VitalType.weight,
          date: DateTime(2026, 8, 18, 8, 5),
          value1: 70.5,
          unit: 'kg',
        ));

        final bpLogs = await vitalsRepo.getLogs('p1', VitalType.bloodPressure);
        expect(bpLogs.length, 2);
        expect(bpLogs[0].id, 'v-bp-1', reason: 'Should be sorted ascending by date');
        expect(bpLogs[1].id, 'v-bp-2');

        final wtLogs = await vitalsRepo.getLogs('p1', VitalType.weight);
        expect(wtLogs.length, 1);
        expect(wtLogs.first.value1, 70.5);

        await vitalsRepo.deleteLog('v-bp-1');
        final remainingBp = await vitalsRepo.getLogs('p1', VitalType.bloodPressure);
        expect(remainingBp.length, 1);
        expect(remainingBp.first.id, 'v-bp-2');
      });
    });

    // -------------------------------------------------------------
    // 8. EmergencyRepository Tests
    // -------------------------------------------------------------
    group('EmergencyRepository', () {
      setUp(() async {
        await seedProfiles(['p1']);
      });

      test('Emergency contacts and lock screen setting persistence', () async {
        final contact = EmergencyContact(
          id: 'ec-1',
          profileId: 'p1',
          name: 'Alex Smith',
          relationship: 'Partner',
          phoneNumber: '+1234567890',
        );
        await emergencyRepo.addEmergencyContact(contact);

        final contacts = await emergencyRepo.getEmergencyContacts('p1');
        expect(contacts.length, 1);
        expect(contacts.first.name, 'Alex Smith');

        // Lock screen setting fallback
        final initialSetting = await emergencyRepo.getLockScreenSetting('p1');
        expect(initialSetting.isEnabled, false);
        expect(initialSetting.showName, true);

        // Update setting
        final updatedSetting = LockScreenSetting(
          profileId: initialSetting.profileId,
          showName: initialSetting.showName,
          showAge: initialSetting.showAge,
          showBloodType: initialSetting.showBloodType,
          showOrganDonor: false,
          showChronicConditions: initialSetting.showChronicConditions,
          showAllergies: true,
          showMedications: initialSetting.showMedications,
          showContacts: initialSetting.showContacts,
          isEnabled: true,
        );
        await emergencyRepo.saveLockScreenSetting(updatedSetting);

        final savedSetting = await emergencyRepo.getLockScreenSetting('p1');
        expect(savedSetting.isEnabled, true);
        expect(savedSetting.showOrganDonor, false);
        expect(savedSetting.showAllergies, true);

        // Primary Profile ID
        expect(await emergencyRepo.getPrimaryProfileId(), isNull);
        await emergencyRepo.setPrimaryProfileId('p1');
        expect(await emergencyRepo.getPrimaryProfileId(), 'p1');
      });
    });
  });
}
