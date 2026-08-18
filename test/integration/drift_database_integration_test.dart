import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Drift AppDatabase Direct Integration Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Schema version and table creation', () async {
      expect(db.schemaVersion, 1);

      // Verify all tables can be queried
      expect(await db.select(db.profiles).get(), isEmpty);
      expect(await db.select(db.history).get(), isEmpty);
      expect(await db.select(db.attachments).get(), isEmpty);
      expect(await db.select(db.allergy).get(), isEmpty);
      expect(await db.select(db.medications).get(), isEmpty);
      expect(await db.select(db.medicationLogs).get(), isEmpty);
      expect(await db.select(db.checkups).get(), isEmpty);
      expect(await db.select(db.checkupLogs).get(), isEmpty);
      expect(await db.select(db.periodCycles).get(), isEmpty);
      expect(await db.select(db.periodLogs).get(), isEmpty);
      expect(await db.select(db.vitalLogs).get(), isEmpty);
      expect(await db.select(db.settings).get(), isEmpty);
      expect(await db.select(db.emergencyContacts).get(), isEmpty);
      expect(await db.select(db.lockScreenSettings).get(), isEmpty);
    });

    test('Profiles table insert, select, update, and defaults', () async {
      await db.into(db.profiles).insert(
            const ProfileEntry(
              id: 'prof-1',
              name: 'Alice',
              middleNames: 'Marie',
              surname: 'Smith',
              dateOfBirth: '1995-04-12',
              bloodType: 'A+',
              gender: 'female',
              isOrganDonor: 'true',
              trackOvulation: 'true',
              isArchived: 'false',
              archivedAt: null,
              chronicConditions: 'Asthma,Migraine',
            ),
          );

      final row = await (db.select(db.profiles)..where((tbl) => tbl.id.equals('prof-1'))).getSingle();
      expect(row.name, 'Alice');
      expect(row.middleNames, 'Marie');
      expect(row.surname, 'Smith');
      expect(row.dateOfBirth, '1995-04-12');
      expect(row.bloodType, 'A+');
      expect(row.gender, 'female');
      expect(row.isOrganDonor, 'true');
      expect(row.trackOvulation, 'true');
      expect(row.isArchived, 'false');
      expect(row.archivedAt, isNull);
      expect(row.chronicConditions, 'Asthma,Migraine');

      // Update profile
      await (db.update(db.profiles)..where((tbl) => tbl.id.equals('prof-1'))).write(
        const ProfilesCompanion(
          name: Value('Alice Updated'),
          chronicConditions: Value('Asthma,Migraine,Hypertension'),
        ),
      );

      final updatedRow = await (db.select(db.profiles)..where((tbl) => tbl.id.equals('prof-1'))).getSingle();
      expect(updatedRow.name, 'Alice Updated');
      expect(updatedRow.chronicConditions, 'Asthma,Migraine,Hypertension');
    });

    test('History & Attachments tables foreign key association & query', () async {
      await db.into(db.history).insert(
            const HistoryEntry(
              id: 'hist-1',
              profileId: 'prof-1',
              title: 'Annual Physical',
              description: 'Routine bloodwork and general exam',
              date: '2026-01-15T09:30:00.000',
              eventType: 'appointment',
              hasTime: 'true',
              provider: 'Dr. Gregory House',
              facility: 'Princeton-Plainsboro',
            ),
          );

      await db.into(db.attachments).insert(
            const AttachmentEntry(
              id: 'att-1',
              historyId: 'hist-1',
              filename: 'bloodwork_results.pdf',
              uploadDate: '2026-01-15',
              byteLength: 450210,
            ),
          );

      await db.into(db.attachments).insert(
            const AttachmentEntry(
              id: 'att-2',
              historyId: 'hist-1',
              filename: 'chest_xray.png',
              uploadDate: '2026-01-15',
              byteLength: 1048576,
            ),
          );

      final attachments = await (db.select(db.attachments)..where((tbl) => tbl.historyId.equals('hist-1'))).get();
      expect(attachments.length, 2);
      expect(attachments.map((a) => a.filename), containsAll(['bloodwork_results.pdf', 'chest_xray.png']));
      expect(attachments.map((a) => a.byteLength), containsAll([450210, 1048576]));
    });

    test('Allergy table insert and query', () async {
      await db.into(db.allergy).insert(
            const AllergyEntry(
              id: 'all-1',
              profileId: 'prof-1',
              name: 'Penicillin',
              note: 'Causes hives and swelling',
            ),
          );

      final allergy = await (db.select(db.allergy)..where((tbl) => tbl.profileId.equals('prof-1'))).getSingle();
      expect(allergy.name, 'Penicillin');
      expect(allergy.note, 'Causes hives and swelling');
    });

    test('Medications and MedicationLogs table operations', () async {
      await db.into(db.medications).insert(
            MedicationsCompanion.insert(
              id: 'med-1',
              profileId: 'prof-1',
              name: 'Amoxicillin',
              dosage: '500 mg',
              type: const Value('Antibiotic'),
              notificationEnabled: const Value('true'),
              alarmEnabled: const Value('false'),
              timeOfDay: '08:00',
              isActive: const Value('true'),
              daysOfWeek: const Value('[1,2,3,4,5,6,7]'),
              timesOfDay: const Value('["08:00","20:00"]'),
              isAsNeeded: const Value('false'),
              trackInventory: const Value('true'),
              stockQuantity: const Value(30.0),
              lowStockThreshold: const Value(5.0),
            ),
          );

      await db.into(db.medicationLogs).insert(
            const MedicationLogEntry(
              id: 'log-1',
              medicationId: 'med-1',
              timestamp: '2026-08-18T08:05:00.000',
              isTaken: 'true',
              dosage: '500 mg',
            ),
          );

      final med = await (db.select(db.medications)..where((tbl) => tbl.id.equals('med-1'))).getSingle();
      expect(med.name, 'Amoxicillin');
      expect(med.stockQuantity, 30.0);
      expect(med.lowStockThreshold, 5.0);

      final logs = await (db.select(db.medicationLogs)..where((tbl) => tbl.medicationId.equals('med-1'))).get();
      expect(logs.length, 1);
      expect(logs.first.isTaken, 'true');
      expect(logs.first.dosage, '500 mg');
    });

    test('Checkups and CheckupLogs table operations', () async {
      await db.into(db.checkups).insert(
            CheckupsCompanion.insert(
              id: 'chk-1',
              profileId: 'prof-1',
              name: 'Dental Cleaning',
              frequencyInMonths: 6,
              iconName: const Value('tooth'),
              isCustomInterval: const Value('false'),
              isActive: const Value('true'),
            ),
          );

      await db.into(db.checkupLogs).insert(
            const CheckupLogEntry(
              id: 'chkl-1',
              checkupId: 'chk-1',
              dateCompleted: '2026-02-10T14:00:00.000',
              location: 'Smile Dental Clinic',
              doctorName: 'Dr. Smile',
              notes: 'Clean bill of dental health, next visit in 6 months.',
            ),
          );

      final chk = await (db.select(db.checkups)..where((tbl) => tbl.id.equals('chk-1'))).getSingle();
      expect(chk.name, 'Dental Cleaning');
      expect(chk.frequencyInMonths, 6);

      final chkLog = await (db.select(db.checkupLogs)..where((tbl) => tbl.checkupId.equals('chk-1'))).getSingle();
      expect(chkLog.doctorName, 'Dr. Smile');
      expect(chkLog.location, 'Smile Dental Clinic');
    });

    test('PeriodCycles and PeriodLogs table operations', () async {
      await db.into(db.periodCycles).insert(
            const PeriodCycleEntry(
              id: 'cycle-1',
              profileId: 'prof-1',
              startDate: '2026-08-01T00:00:00.000',
              endDate: '2026-08-06T00:00:00.000',
            ),
          );

      await db.into(db.periodLogs).insert(
            const PeriodLogEntry(
              id: 'plog-1',
              cycleId: 'cycle-1',
              date: '2026-08-01T00:00:00.000',
              flowLevel: 'heavy',
              moods: 'cramps,tired',
              physicalSymptoms: 'headache,bloating',
            ),
          );

      final cycle = await (db.select(db.periodCycles)..where((tbl) => tbl.id.equals('cycle-1'))).getSingle();
      expect(cycle.startDate, '2026-08-01T00:00:00.000');
      expect(cycle.endDate, '2026-08-06T00:00:00.000');

      final log = await (db.select(db.periodLogs)..where((tbl) => tbl.cycleId.equals('cycle-1'))).getSingle();
      expect(log.flowLevel, 'heavy');
      expect(log.moods, 'cramps,tired');
      expect(log.physicalSymptoms, 'headache,bloating');
    });

    test('VitalLogs table operations across multiple metrics', () async {
      await db.into(db.vitalLogs).insert(
            const VitalLogEntry(
              id: 'vital-1',
              profileId: 'prof-1',
              type: 'bloodPressure',
              date: '2026-08-18T07:00:00.000',
              value1: 120.0,
              value2: 80.0,
              unit: 'mmHg',
              note: 'Morning resting reading',
            ),
          );

      await db.into(db.vitalLogs).insert(
            const VitalLogEntry(
              id: 'vital-2',
              profileId: 'prof-1',
              type: 'bloodGlucose',
              date: '2026-08-18T07:30:00.000',
              value1: 95.0,
              value2: null,
              unit: 'mg/dL',
              note: 'Fasting glucose',
            ),
          );

      final vitals = await (db.select(db.vitalLogs)..where((tbl) => tbl.profileId.equals('prof-1'))).get();
      expect(vitals.length, 2);
      expect(vitals[0].type, 'bloodPressure');
      expect(vitals[0].value1, 120.0);
      expect(vitals[0].value2, 80.0);
      expect(vitals[1].type, 'bloodGlucose');
      expect(vitals[1].value1, 95.0);
      expect(vitals[1].value2, isNull);
    });

    test('EmergencyContacts and LockScreenSettings operations', () async {
      await db.into(db.emergencyContacts).insert(
            const EmergencyContactEntry(
              id: 'emg-1',
              profileId: 'prof-1',
              name: 'Jane Doe',
              relationship: 'Mother',
              phoneNumber: '+1-555-0199',
            ),
          );

      await db.into(db.lockScreenSettings).insert(
            LockScreenSettingsCompanion.insert(
              profileId: 'prof-1',
              showName: const Value('true'),
              showAge: const Value('true'),
              showBloodType: const Value('true'),
              showOrganDonor: const Value('true'),
              showChronicConditions: const Value('true'),
              showAllergies: const Value('true'),
              showMedications: const Value('true'),
              showContacts: const Value('true'),
              isEnabled: const Value('true'),
            ),
          );

      final contact = await (db.select(db.emergencyContacts)..where((tbl) => tbl.id.equals('emg-1'))).getSingle();
      expect(contact.name, 'Jane Doe');
      expect(contact.relationship, 'Mother');
      expect(contact.phoneNumber, '+1-555-0199');

      final lockSetting = await (db.select(db.lockScreenSettings)..where((tbl) => tbl.profileId.equals('prof-1'))).getSingle();
      expect(lockSetting.isEnabled, 'true');
      expect(lockSetting.showOrganDonor, 'true');
    });

    test('Settings helper methods work as expected', () async {
      expect(await db.isLocalAuthEnabled(), false);
      await db.setLocalAuthEnabled(true);
      expect(await db.isLocalAuthEnabled(), true);
      await db.setLocalAuthEnabled(false);
      expect(await db.isLocalAuthEnabled(), false);

      expect(await db.isSecurityBannerDismissed(), false);
      await db.setSecurityBannerDismissed(true);
      expect(await db.isSecurityBannerDismissed(), true);

      expect(await db.getPrimaryProfileId(), isNull);
      await db.setPrimaryProfileId('prof-1');
      expect(await db.getPrimaryProfileId(), 'prof-1');
      await db.setPrimaryProfileId(null);
      expect(await db.getPrimaryProfileId(), isNull);
    });

    test('Transactions roll back on error', () async {
      try {
        await db.transaction(() async {
          await db.into(db.profiles).insert(
                const ProfileEntry(
                  id: 'prof-trans-1',
                  name: 'Bob',
                  middleNames: '',
                  surname: 'Jones',
                  dateOfBirth: '1980-01-01',
                  bloodType: 'B+',
                  gender: 'male',
                  isOrganDonor: 'false',
                  trackOvulation: 'false',
                  isArchived: 'false',
                  archivedAt: null,
                  chronicConditions: '',
                ),
              );

          // Force an intentional error
          throw Exception('Simulated transaction failure');
        });
      } catch (_) {
        // Expected
      }

      final profile = await (db.select(db.profiles)..where((tbl) => tbl.id.equals('prof-trans-1'))).getSingleOrNull();
      expect(profile, isNull, reason: 'Transaction rollback should ensure no records were committed');
    });
  });
}
